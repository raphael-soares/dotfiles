#!/usr/bin/env bash
# secrets against a fake rbw whose vault is a directory of files.
# shellcheck disable=SC2034  # $out is read inside the strings expect evals
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home XDG_STATE_HOME=$T/state VAULT=$T/vault PATH=$T/bin:$PATH
mkdir -p "$HOME" "$VAULT/dotfiles" "$T/bin"

cat >"$T/bin/rbw" <<'EOF'
#!/usr/bin/env bash
case $1 in
  unlock|sync) ;;
  list) cd "$VAULT" && find . -type f | sed 's|^\./||; s|/|\t|' ;;
  get) jq -Rs '{notes: .}' "$VAULT/$3/$5" ;;
esac
EOF
cat >"$T/bin/vault" <<'EOF'
#!/usr/bin/env bash
[[ $1 == note ]] && mkdir -p "$VAULT/$2/$(dirname "$3")" && cp "$4" "$VAULT/$2/$3"
EOF
chmod +x "$T/bin/rbw" "$T/bin/vault"

fail=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

mkdir -p "$VAULT/dotfiles/Documents/TEAjudo/Env"
printf 'A=1\nB=two words\n' >"$VAULT/dotfiles/Documents/TEAjudo/Env/api.env"
"$REPO/terminal/bin/secrets" pull >/dev/null
expect "pull writes the item to its path" 'cmp -s "$VAULT/dotfiles/Documents/TEAjudo/Env/api.env" "$HOME/Documents/TEAjudo/Env/api.env"'
expect "pull writes mode 600" '[[ $(stat -c %a "$HOME/Documents/TEAjudo/Env/api.env") == 600 ]]'

mkdir -p "$HOME/Documents/Unimed/Envs"
printf 'VPN_HOST=x\n' >"$HOME/Documents/Unimed/Envs/vpn.env"
chmod 644 "$HOME/Documents/Unimed/Envs/vpn.env"
out=$("$REPO/terminal/bin/secrets" check || true)
expect "check flags a file others can read" '[[ $out == *"Documents/Unimed/Envs/vpn.env can be read by others"* ]]'
expect "check flags a file outside the vault" '[[ $out == *"Documents/Unimed/Envs/vpn.env is not in the vault"* ]]'

"$REPO/terminal/bin/secrets" push "$HOME/Documents/Unimed/Envs/vpn.env" >/dev/null
expect "push stores the content" 'cmp -s "$HOME/Documents/Unimed/Envs/vpn.env" "$VAULT/dotfiles/Documents/Unimed/Envs/vpn.env"'
expect "check passes after push" '"$REPO/terminal/bin/secrets" check'

rm "$HOME/Documents/TEAjudo/Env/api.env"
out=$("$REPO/terminal/bin/secrets" check || true)
expect "check flags a vault file missing here" '[[ $out == *"Documents/TEAjudo/Env/api.env is in the vault but missing here"* ]]'

exit "$fail"
