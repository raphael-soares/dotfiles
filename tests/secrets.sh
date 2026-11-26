#!/usr/bin/env bash
# secrets with the real sops and age, against a throwaway key and repo copy.
# shellcheck disable=SC2016  # the expect bodies are eval'd later on purpose
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
unset SOPS_AGE_KEY_FILE XDG_CONFIG_HOME
key=$HOME/.config/sops/age/keys.txt
mkdir -p "${key%/*}" "$T/repo/terminal/bin" "$T/repo/secrets"
cp "$REPO/terminal/bin/secrets" "$T/repo/terminal/bin/"
S=$T/repo/terminal/bin/secrets
(umask 077 && age-keygen -o "$key" 2>/dev/null)
printf 'creation_rules:\n  - path_regex: secrets/[^/]+\\.env$\n    age: %s\n' "$(age-keygen -y "$key")" >"$T/repo/.sops.yaml"

tricky='a b=$c"d'"'"'e'
(cd "$T/repo" && printf 'TRICKY=%s\n' "$tricky" |
  sops encrypt --filename-override secrets/personal.env --input-type dotenv --output-type dotenv /dev/stdin >secrets/personal.env)
(cd "$T/repo" && printf 'AWS_ACCESS_KEY_ID=AKIAFAKE\nAWS_SECRET_ACCESS_KEY=s/e+cret\n' |
  sops encrypt --filename-override secrets/aws.env --input-type dotenv --output-type dotenv /dev/stdin >secrets/aws.env)
mkdir -p "$HOME/.local/bin"
ln -s "$S" "$HOME/.local/bin/secrets"

fail=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

expect "the file in the repo holds no plain value" '! grep -qF "$tricky" "$T/repo/secrets/personal.env"'
expect "run passes a value with spaces, = and quotes unchanged" '[[ $("$S" run -- printenv TRICKY) == "$tricky" ]]'
expect "run passes arguments with spaces and \$ unchanged" '[[ $("$S" run -- printf "%s|" "x y" "\$TRICKY") == "x y|\$TRICKY|" ]]'
expect "check passes with the key in place" '"$S" check'
expect "aws prints the credential_process JSON" \
  '[[ $("$S" aws | jq -c .) == "{\"Version\":1,\"AccessKeyId\":\"AKIAFAKE\",\"SecretAccessKey\":\"s/e+cret\"}" ]]'
if command -v aws >/dev/null; then
  creds=$(AWS_CONFIG_FILE=$REPO/terminal/aws/config AWS_SHARED_CREDENTIALS_FILE=/dev/null \
    env -u AWS_PROFILE -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY aws configure export-credentials --format env-no-export)
  expect "the aws config reaches the key through secrets" '[[ $creds == *"AWS_SECRET_ACCESS_KEY=s/e+cret"* ]]'
fi

mkdir -p "$HOME/.config/media"
printf 'A=1\n' >"$HOME/.config/media/media.env"
chmod 644 "$HOME/.config/media/media.env"
out=$("$S" check || true)
expect "check flags media.env readable by others" '[[ $out == *"media.env can be read by others"* ]]'
chmod 600 "$HOME/.config/media/media.env"

mkdir -p "$HOME/Code/app" "$HOME/Notes/TEAjudo" "$HOME/Drive/TEAjudo" "$HOME/.config/tool"
printf 'X_TOKEN=1\n' >"$HOME/Code/app/.env"
printf 'POSITION=left\n' >"$HOME/.config/tool/config.env"
expect "check leaves a project .env and a .env without secrets alone" '"$S" check >/dev/null'
printf 'machine x login a password b\n' >"$HOME/.netrc"
printf 'DB_PASSWORD=x\n' >"$HOME/Notes/TEAjudo/api-prod.env"
printf 'DB_PASSWORD=x\n' >"$HOME/Drive/TEAjudo/api-prod.env"
out=$("$S" check || true)
expect "check flags a .netrc" '[[ $out == *"plain-text credential at ~/.netrc"* ]]'
expect "check flags a stray .env outside Code" '[[ $out == *"~/Notes/TEAjudo/api-prod.env"* ]]'
expect "check does not walk into Drive" '[[ $out != *"~/Drive/"* ]]'
rm "$HOME/.netrc" "$HOME/Notes/TEAjudo/api-prod.env" "$HOME/Drive/TEAjudo/api-prod.env"

printf '  - path_regex: secrets/ssh/.+\n    age: %s\n' "$(age-keygen -y "$key")" >>"$T/repo/.sops.yaml"
mkdir -p "$T/repo/secrets/ssh/keys" "$HOME/.ssh"
ssh-keygen -q -t ed25519 -N '' -C test -f "$T/k"
printf 'Host x\n  HostName 10.0.0.1\n' >"$T/cfg"
enc() { (cd "$T/repo" && sops encrypt --input-type binary --output-type binary --filename-override "secrets/ssh/$1" "$2" >"secrets/ssh/$1"); }
enc keys/personal "$T/k"
enc config "$T/cfg"
printf 'known\n' >"$HOME/.ssh/known_hosts"
"$S" ssh >/dev/null
expect "the repo holds no plain ssh key" '! grep -q "PRIVATE KEY" "$T/repo/secrets/ssh/keys/personal"'
expect "ssh writes the key with mode 600" \
  'cmp -s "$HOME/.ssh/keys/personal" "$T/k" && [[ $(stat -c %a "$HOME/.ssh/keys/personal") == 600 ]]'
expect "ssh writes the .pub of the key" '[[ $(cut -d" " -f1,2 "$HOME/.ssh/keys/personal.pub") == $(ssh-keygen -y -f "$T/k" | cut -d" " -f1,2) ]]'
expect "ssh writes the config" 'cmp -s "$HOME/.ssh/config" "$T/cfg"'
expect "ssh leaves a file that is not in the repo alone" '[[ $(cat "$HOME/.ssh/known_hosts") == known ]]'
touch -d 2020-01-01 "$HOME/.ssh/config"
"$S" ssh >/dev/null
expect "ssh does not rewrite an unchanged file" '[[ $(stat -c %Y "$HOME/.ssh/config") == $(date -d 2020-01-01 +%s) ]]'
expect "check passes when ~/.ssh matches the repo" '"$S" check >/dev/null'
printf 'Host y\n' >>"$HOME/.ssh/config"
cp "$T/k" "$HOME/.ssh/keys/stray"
out=$("$S" check || true)
expect "check flags a ~/.ssh file that differs" '[[ $out == *"~/.ssh/config differs from secrets/ssh"* ]]'
expect "check flags a key that is not in secrets/ssh" '[[ $out == *"~/.ssh/keys/stray is not in secrets/ssh"* ]]'
"$S" ssh >/dev/null
expect "ssh rewrites a file that changed" 'cmp -s "$HOME/.ssh/config" "$T/cfg"'
rm "$HOME/.ssh/keys/stray"
printf 'local\n' >"$HOME/.ssh/config"

mv "$key" "$T/key.bak"
out=$("$S" check || true)
expect "check points to the vault when the key is missing" '[[ $out == *"age (dotfiles)"* ]]'
expect "run fails without the key" '! "$S" run -- true 2>/dev/null'
expect "aws fails without the key" '! "$S" aws >/dev/null 2>&1'
expect "ssh without the key exits 0 and leaves ~/.ssh as is" \
  '"$S" ssh >/dev/null 2>&1 && [[ $(cat "$HOME/.ssh/config") == local ]]'

mkdir -p "$T/fakebin"
printf '#!/bin/sh\nexit 1\n' >"$T/fakebin/rbw"
chmod +x "$T/fakebin/rbw"
expect "init fails when rbw is locked and leaves no key" '! PATH=$T/fakebin:$PATH "$S" init 2>/dev/null && [[ ! -e $key ]]'
printf '#!/bin/sh\necho not-a-key\n' >"$T/fakebin/rbw"
expect "init refuses a vault item that is not an age key" '! PATH=$T/fakebin:$PATH "$S" init 2>/dev/null && [[ ! -e $key ]]'
printf '#!/bin/sh\ncat %q\n' "$T/key.bak" >"$T/fakebin/rbw"
expect "init restores the key with mode 600" \
  'PATH=$T/fakebin:$PATH "$S" init >/dev/null && cmp -s "$key" "$T/key.bak" && [[ $(stat -c %a "$key") == 600 ]]'

exit "$fail"
