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

fail=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

expect "the file in the repo holds no plain value" '! grep -qF "$tricky" "$T/repo/secrets/personal.env"'
expect "run passes a value with spaces, = and quotes unchanged" '[[ $("$S" run -- printenv TRICKY) == "$tricky" ]]'
expect "run passes arguments with spaces and \$ unchanged" '[[ $("$S" run -- printf "%s|" "x y" "\$TRICKY") == "x y|\$TRICKY|" ]]'
expect "check passes with the key in place" '"$S" check'

mkdir -p "$HOME/.config/media"
printf 'A=1\n' >"$HOME/.config/media/media.env"
chmod 644 "$HOME/.config/media/media.env"
out=$("$S" check || true)
expect "check flags media.env readable by others" '[[ $out == *"media.env can be read by others"* ]]'

mv "$key" "$T/key.bak"
out=$("$S" check || true)
expect "check points to the vault when the key is missing" '[[ $out == *"age (dotfiles)"* ]]'
expect "run fails without the key" '! "$S" run -- true 2>/dev/null'

exit "$fail"
