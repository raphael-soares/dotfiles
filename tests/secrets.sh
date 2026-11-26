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

mv "$key" "$T/key.bak"
out=$("$S" check || true)
expect "check points to the vault when the key is missing" '[[ $out == *"age (dotfiles)"* ]]'
expect "run fails without the key" '! "$S" run -- true 2>/dev/null'
expect "aws fails without the key" '! "$S" aws >/dev/null 2>&1'

exit "$fail"
