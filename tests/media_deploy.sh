#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
mkdir -p "$HOME"

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
! grep -Evq '^[A-Z_]+=' "$env_file" || fail "env file has a line that is not KEY=VALUE"

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
done < <(sed -n 's/^Volume=%h\([^:]*\):.*/\1/p' "$REPO"/media/containers/*.container | grep -vx '/.config/media/configarr')

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

((failures == 0)) && echo "media_deploy: ok" || { echo "media_deploy: $failures failure(s)"; exit 1; }
