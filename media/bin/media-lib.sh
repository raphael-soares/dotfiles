# shellcheck shell=bash
# Sourced by the media scripts. MEDIA_ENV and MEDIA_STATE point elsewhere in tests.

ENV_FILE=${MEDIA_ENV:-$HOME/.config/media/media.env}
STATE=${MEDIA_STATE:-$HOME/.local/share/media}
QBT=http://127.0.0.1:8080/api/v2
JF_PLUGINS=("Intro Skipper" "Jellyfin Enhanced" "File Transformation" "Plugin Pages")
JF_ENHANCED=f69e946a4b3c4e9a8f0a8d7c1b2c4d9b
JF=http://127.0.0.1:8096

env_get() { sed -n "s/^$1=//p" "$ENV_FILE"; }

# api <app> <method> <path> [curl args...]: path is relative to the app's API root.
api() {
  local app=$1 method=$2 path=$3 url auth
  shift 3
  case $app in
    radarr) url=http://127.0.0.1:7878/api/v3 auth="X-Api-Key: $(env_get RADARR__AUTH__APIKEY)" ;;
    sonarr) url=http://127.0.0.1:8989/api/v3 auth="X-Api-Key: $(env_get SONARR__AUTH__APIKEY)" ;;
    prowlarr) url=http://127.0.0.1:9696/api/v1 auth="X-Api-Key: $(env_get PROWLARR__AUTH__APIKEY)" ;;
    seerr) url=http://127.0.0.1:5055/api/v1 auth="X-Api-Key: $(jq -r .main.apiKey "$STATE/seerr/settings.json")" ;;
    jellyfin) url=$JF auth="Authorization: MediaBrowser Token=\"$(env_get JELLYFIN_TOKEN)\"" ;;
    *) echo "api: unknown app $app" >&2; return 2 ;;
  esac
  curl -fsS -X "$method" -H "$auth" -H "Content-Type: ${API_TYPE:-application/json}" "$@" "$url$path"
}

# The WebUI skips auth for localhost (bypass_local_auth in preferences.json).
qbt() { local path=$1; shift; curl -fsS "$@" "$QBT$path"; }

# Repo JSON keeps paths as ~/...; this expands them for the running user.
expand_home() { jq --arg h "$HOME" 'walk(if type == "string" and startswith("~/") then $h + .[1:] else . end)' "$@"; }
