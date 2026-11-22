#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
mkdir -p "$HOME"
export MEDIA_LOG=$T/media.log

MEDIA_DEPLOY_LIB=1 source "$REPO/media/bin/media-deploy" "$REPO"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
env_file=$HOME/.config/media/media.env

ensure_env
[[ $(stat -c %a "$env_file") == 600 ]] || fail "env file is not mode 600"
for k in RADARR__AUTH__APIKEY SONARR__AUTH__APIKEY PROWLARR__AUTH__APIKEY BAZARR_API_KEY QBITTORRENT_WEBUI_PASSWORD; do
  grep -Eq "^$k=[0-9a-f]{32}$" "$env_file" || fail "$k is not a 32 hex key"
done
grep -qx 'OPENSUBTITLESCOM_USERNAME=' "$env_file" || fail "empty non-key value was filled"
! grep -Evq '^([A-Z_]+=|#|$)' "$env_file" || fail "env file has a line that is not KEY=VALUE, a comment or blank"

cp "$env_file" "$T/first"
ensure_env
cmp -s "$env_file" "$T/first" || fail "second run changed the env file"

sed -i 's/^RADARR__AUTH__APIKEY=.*/RADARR__AUTH__APIKEY=abc/' "$env_file"
ensure_env
grep -qx 'RADARR__AUTH__APIKEY=abc' "$env_file" || fail "pre-filled key was overwritten"

sed -i '/^QBITTORRENT_WEBUI_PASSWORD=/d' "$env_file"
ensure_env
grep -Eq '^QBITTORRENT_WEBUI_PASSWORD=[0-9a-f]{32}$' "$env_file" || fail "key added to the example did not reach an existing env file"

ensure_dirs
while IFS= read -r src; do
  [[ -d $HOME$src ]] || fail "bind mount source ~$src missing after ensure_dirs"
done < <(sed -n 's/^Volume=%h\([^:]*\):.*/\1/p' "$REPO"/media/containers/*.container | grep -vx -e '/.config/media/configarr' -e '/.config/media/prowlarr-definitions' -e '/.config/media/whisper' -e '/.config/media/caddy')

caddyfile=$REPO/media/caddy/Caddyfile
[[ -f $caddyfile ]] || fail "media/caddy/Caddyfile is missing"
names=$(sed -n 's/^ContainerName=//p' "$REPO"/media/containers/*.container)
while read -r upstream; do
  grep -qx "${upstream%:*}" <<<"$names" || fail "Caddyfile proxies to $upstream, which is not a media container"
done < <(awk '$1 == "reverse_proxy" {print $2}' "$caddyfile" 2>/dev/null)
grep -q 'PublishPort=127.0.0.1:80:80' "$REPO/media/containers/caddy.container" 2>/dev/null &&
  grep -q 'PublishPort=\[::1\]:80:80' "$REPO/media/containers/caddy.container" || fail "caddy does not listen on both loopback families"
for arr in radarr sonarr; do
  [[ $(jq -r .externalUrl "$REPO/media/seerr/$arr.json") == "http://$arr.localhost" ]] || fail "seerr links to $arr outside the proxy"
done

mkdir "$T/bin"
cat >"$T/bin/systemctl" <<'EOF'
#!/bin/sh
case " $* " in
  *" is-active "*) exit 4 ;;
  *" restart "* | *" try-restart "*) echo "Unit bazarr.service not found." >&2; exit 5 ;;
esac
EOF
chmod +x "$T/bin/systemctl"
PATH=$T/bin:$PATH bash -c 'MEDIA_DEPLOY_LIB=1 source "$1" "$2" && render_bazarr' _ "$REPO/media/bin/media-deploy" "$REPO" >/dev/null ||
  fail "render_bazarr fails while the bazarr unit does not exist yet"
bazarr_conf=$HOME/.local/share/media/bazarr/config/config.yaml
grep -qx "  apikey: $(sed -n 's/^BAZARR_API_KEY=//p' "$env_file")" "$bazarr_conf" || fail "bazarr config lacks the Bazarr API key"
[[ $(stat -c %a "$bazarr_conf") == 600 ]] || fail "bazarr config is not mode 600"

seed_qbittorrent >/dev/null
python3 - "$HOME/.config/qBittorrent/qBittorrent.conf" "$(sed -n 's/^QBITTORRENT_WEBUI_PASSWORD=//p' "$env_file")" <<'PY' ||
import base64, hashlib, re, sys
m = re.search(r'^WebUI\\Password_PBKDF2="@ByteArray\(([^:]+):([^)]+)\)"$', open(sys.argv[1]).read(), re.M)
salt, key = map(base64.b64decode, m.groups())
sys.exit(hashlib.pbkdf2_hmac("sha512", sys.argv[2].encode(), salt, 100000) != key)
PY
  fail "seeded qBittorrent WebUI password does not match the env file"

link_files 2>/dev/null
[[ $(readlink "$HOME/.local/bin/media-failure") == "$REPO/media/bin/media-failure" ]] || fail "a media/bin script was not linked"
[[ $(readlink "$HOME/.config/systemd/user/media-failure@.service") == "$REPO/media/systemd/media-failure@.service" ]] ||
  fail "a media/systemd unit was not linked"
[[ $(readlink "$HOME/.config/containers/systemd/media") == "$REPO/media/containers" ]] || fail "the quadlet directory was not linked"
[[ -z $(CHECK=1 link_files) ]] || fail "--check reports links that link_files just made"
rm "$HOME/.local/bin/mediactl"
ln -s "$REPO/media/bin/media-removed" "$HOME/.local/bin/media-removed"
rm "$HOME/.local/bin/media-backup" && echo mine >"$HOME/.local/bin/media-backup"
report=$(CHECK=1 link_files 2>&1)
grep -q "differs: link $HOME/.local/bin/mediactl" <<<"$report" || fail "--check does not report a missing link"
grep -q "differs: remove $HOME/.local/bin/media-removed" <<<"$report" || fail "--check does not report a link to a removed script"
link_files 2>/dev/null
[[ -L $HOME/.local/bin/mediactl && ! -L $HOME/.local/bin/media-removed ]] || fail "link_files did not restore and prune links"
[[ $(cat "$HOME/.local/bin/media-backup") == mine ]] || fail "link_files replaced a file that is not a link"

(source "$REPO/media/bin/media-lib.sh" && for i in {1..13000}; do printf '%0100d\n' "$i"; done >"$MEDIA_LOG" && log "last")
[[ $(wc -l <"$MEDIA_LOG") -le 5000 && $(tail -n1 "$MEDIA_LOG") == *": last" ]] || fail "the log is not trimmed to its latest lines"

((failures == 0)) && echo "media_deploy: ok" || { echo "media_deploy: $failures failure(s)"; exit 1; }
