#!/usr/bin/env bash
# secrets against a fake rbw backed by a JSON vault, in a throwaway home.
# shellcheck disable=SC2016,SC2034  # the expect bodies are eval'd later on purpose
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
unset XDG_CONFIG_HOME XDG_STATE_HOME
S=$REPO/terminal/bin/secrets
STATE=$HOME/.local/state/secrets
VAULT=$T/vault.json
mkdir -p "$HOME/.ssh" "$T/bin"
export PATH=$T/bin:$PATH VAULT

# rbw fake: unlocked unless $T/locked exists; edit and add read the entry from stdin like rbw.
cat >"$T/bin/rbw" <<EOF
#!/usr/bin/env bash
set -euo pipefail
locked() { [[ -e $T/locked ]]; }
opt() { while (((\$#))); do case \$1 in --folder) folder=\$2; shift 2 ;; --raw) shift ;; *) name=\$1; shift ;; esac; done; }
folder='' name=''
cmd=\$1; shift
case \$cmd in
  unlocked) ! locked ;;
  unlock) exit 1 ;;
  sync) ! locked ;;
  list) locked && exit 1; jq '[.[] | {id: .name, name, user: null, folder, type, uris: []}]' "\$VAULT" ;;
  get) locked && exit 1; opt "\$@"
    jq -e --arg n "\$name" --arg f "\$folder" 'first(.[] | select(.name == \$n and .folder == \$f))
      | {name, notes, data: (if .private_key then {private_key} else null end)}' "\$VAULT" ;;
  edit|add) locked && exit 1; opt "\$@"; notes=\$(tail -n +2 | sed '/^#/d')
    jq --arg n "\$name" --arg f "\$folder" --arg v "\$notes" --arg c "\$cmd" \
      'if \$c == "edit" then map(if .name == \$n and .folder == \$f then .notes = \$v else . end)
       else . + [{name: \$n, folder: \$f, type: "Login", notes: \$v}] end' "\$VAULT" >"\$VAULT.new"
    mv "\$VAULT.new" "\$VAULT" ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$T/bin/rbw"

ssh-keygen -q -t ed25519 -N '' -C test -f "$T/k"
tricky='a b=$c"d'"'"'e'
jq -n --arg tricky "$tricky" --rawfile key "$T/k" '[
  {name: "env personal", folder: "Dotfiles", type: "Note", notes: ("TRICKY=" + $tricky)},
  {name: "env aws", folder: "Dotfiles", type: "Note", notes: "AWS_ACCESS_KEY_ID=AKIAFAKE\nAWS_SECRET_ACCESS_KEY=s/e+cret"},
  {name: "ssh key personal", folder: "Dotfiles", type: "SSH Key", notes: null, private_key: ($key | rtrimstr("\n"))},
  {name: "ssh config", folder: "Dotfiles", type: "Note", notes: "Host x\n  HostName 10.0.0.1"},
  {name: "notes about the PC", folder: "Dotfiles", type: "Note", notes: "free text"},
  {name: "ssh config", folder: "Personal", type: "Note", notes: "Host other-folder"}
]' >"$VAULT"
printf 'known\n' >"$HOME/.ssh/known_hosts"

fail=0
expect() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

touch "$T/locked"
expect "pull --if-unlocked with a locked vault exits 0 and writes nothing" \
  '[[ -z $("$S" pull --if-unlocked) ]] && [[ ! -e $STATE ]]'
expect "pull without the flag fails when unlock fails" '! "$S" pull 2>/dev/null'
rm "$T/locked"

"$S" pull >/dev/null
expect "pull writes a key without a trailing newline as a valid key, mode 600" \
  'cmp -s "$HOME/.ssh/keys/personal" "$T/k" && [[ $(stat -c %a "$HOME/.ssh/keys/personal") == 600 ]]'
expect "pull writes the .pub of the key" '[[ $(cut -d" " -f1,2 "$HOME/.ssh/keys/personal.pub") == $(ssh-keygen -y -f "$T/k" | cut -d" " -f1,2) ]]'
expect "pull writes the ssh config from the Dotfiles folder only" '[[ $(cat "$HOME/.ssh/config") == $(printf "Host x\n  HostName 10.0.0.1") ]]'
expect "pull leaves a file that is not in the vault alone" '[[ $(cat "$HOME/.ssh/known_hosts") == known ]]'
expect "pull ignores items outside the name contract" '[[ $(find "$HOME" -type f | grep -c "notes") == 0 ]]'
touch -d 2020-01-01 "$HOME/.ssh/config"
expect "pull reports nothing and keeps an unchanged file" \
  '[[ -z $("$S" pull) && $(stat -c %Y "$HOME/.ssh/config") == $(date -d 2020-01-01 +%s) ]]'

expect "run passes a value with spaces, = and quotes unchanged" '[[ $("$S" run -- printenv TRICKY) == "$tricky" ]]'
expect "run passes arguments with spaces and \$ unchanged" '[[ $("$S" run -- printf "%s|" "x y" "\$TRICKY") == "x y|\$TRICKY|" ]]'
expect "aws prints the credential_process JSON" \
  '[[ $("$S" aws | jq -c .) == "{\"Version\":1,\"AccessKeyId\":\"AKIAFAKE\",\"SecretAccessKey\":\"s/e+cret\"}" ]]'

printf 'VPN_PASSWORD=n3w-s3cret\n' >"$T/new.env"
out=$("$S" put "env vpn" "$T/new.env" 2>&1)
expect "put never echoes the value" '[[ $out != *n3w-s3cret* ]]'
expect "put creates the item in the Dotfiles folder" \
  '[[ $(jq -r ".[] | select(.name == \"env vpn\" and .folder == \"Dotfiles\") | .notes" "$VAULT") == VPN_PASSWORD=n3w-s3cret ]]'
printf 'VPN_PASSWORD=other\n' | "$S" put "env vpn" >/dev/null
expect "put replaces an existing item instead of adding another" \
  '[[ $(jq "[.[] | select(.name == \"env vpn\")] | length" "$VAULT") == 1 && $(jq -r ".[] | select(.name == \"env vpn\") | .notes" "$VAULT") == VPN_PASSWORD=other ]]'
expect "put refuses a name outside the contract" '! printf x | "$S" put "random" 2>/dev/null'
expect "put refuses the removed age backup name" '! printf x | "$S" put "age backup" 2>/dev/null'
printf '# servers\nHost a\n  HostName 10.0.0.2\n' | "$S" put "ssh config.d/a.conf" >/dev/null
"$S" pull >/dev/null
expect "put keeps a comment line through rbw, which drops lines starting with #" \
  '[[ $(cat "$HOME/.ssh/config.d/a.conf") == $(printf " # servers\nHost a\n  HostName 10.0.0.2") ]]'

expect "check passes with the copies in place" '"$S" check >/dev/null'
chmod 644 "$STATE/aws.env"
out=$("$S" check || true)
expect "check flags a local copy readable by others" '[[ $out == *"aws.env can be read by others"* ]]'
chmod 600 "$STATE/aws.env"
cp "$T/k" "$HOME/.ssh/keys/stray"
out=$("$S" check || true)
expect "check flags a key that is not in the vault" '[[ $out == *"~/.ssh/keys/stray is not in the vault"* ]]'
rm "$HOME/.ssh/keys/stray"

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

rm -r "$STATE"
expect "run fails without the local copy" '! "$S" run -- true 2>/dev/null'
expect "check points to secrets pull without local copies" '[[ $("$S" check || true) == *"run secrets pull"* ]]'

exit "$fail"
