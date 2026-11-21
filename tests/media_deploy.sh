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
for k in RADARR__AUTH__APIKEY SONARR__AUTH__APIKEY PROWLARR__AUTH__APIKEY BAZARR_API_KEY; do
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

((failures == 0)) && echo "media_deploy: ok" || { echo "media_deploy: $failures failure(s)"; exit 1; }
