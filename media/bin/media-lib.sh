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

# linked <dir> <file>...: succeeds when a library hardlink still points at one of the torrent's files.
linked() {
  local dir=$1 f
  shift
  for f in "$@"; do
    [[ -e $dir/$f && $(stat -c %h "$dir/$f") -gt 1 ]] && return 0
  done
  return 1
}

torrent_linked() {
  local files
  mapfile -t files < <(qbt "/torrents/files?hash=$1" | jq -r '.[].name')
  linked "$(qbt "/torrents/properties?hash=$1" | jq -r .save_path)" "${files[@]}"
}

# Prints one line per problem the services report about themselves; nothing when all is well.
health() {
  local app
  for app in radarr sonarr prowlarr; do
    api "$app" GET /health 2>/dev/null | jq -r --arg a "$app" '.[] | select(.type != "ok") | "\($a): \(.message)"' ||
      echo "$app: not answering"
  done
  curl -fsS -H "X-API-KEY: $(env_get BAZARR_API_KEY)" http://127.0.0.1:6767/api/providers 2>/dev/null |
    jq -r '.data[] | select(.status != "Good") | "bazarr: \(.name) is paused (\(.status), retry \(.retry))"' ||
    echo "bazarr: not answering"
  qbt /transfer/info 2>/dev/null | jq -r 'select(.connection_status != "connected") | "qbittorrent: \(.connection_status)"' ||
    echo "qbittorrent: not answering"
  systemctl --user list-units --failed --plain --no-legend 'media-*' configarr.service jellyfin.service seerr.service \
    radarr.service sonarr.service prowlarr.service bazarr.service flaresolverr.service whisper.service whisper-cpp.service |
    awk '{print "systemd: " $1 " failed"}'
}
