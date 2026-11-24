#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export MEDIA_LOG=$T/media.log
unset DBUS_SESSION_BUS_ADDRESS
MEDIA_TORRENTS_LIB=1 MEDIA_STALL_HOURS=6 MEDIA_SLOW_4K_HOURS=12 source "$REPO/media/bin/media-torrents"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

now=1800000000
h=3600
got=$(stalled_torrents "$now" <<EOF | sort | paste -sd,
[
  {"hash":"meta-old","category":"Movies","state":"metaDL","added_on":$((now - 7 * h)),"last_activity":0},
  {"hash":"meta-new","category":"Movies","state":"metaDL","added_on":$((now - 1 * h)),"last_activity":0},
  {"hash":"stalled-old","category":"Shows","state":"stalledDL","added_on":$((now - 50 * h)),"last_activity":$((now - 6 * h))},
  {"hash":"stalled-recent","category":"Shows","state":"stalledDL","added_on":$((now - 50 * h)),"last_activity":$((now - 2 * h))},
  {"hash":"queued","category":"Movies","state":"queuedDL","added_on":$((now - 50 * h)),"last_activity":0},
  {"hash":"game","category":"Games/Switch","state":"stalledDL","added_on":$((now - 50 * h)),"last_activity":0},
  {"hash":"seeding","category":"Movies","state":"stalledUP","added_on":$((now - 50 * h)),"last_activity":0}
]
EOF
)
[[ $got == meta-old,stalled-old ]] || fail "stalled_torrents picked: $got"

queue='[
  {"id":1,"movieId":11,"downloadId":"SLOW","quality":{"quality":{"resolution":2160}}},
  {"id":2,"movieId":12,"downloadId":"FAST","quality":{"quality":{"resolution":2160}}},
  {"id":3,"movieId":13,"downloadId":"FRESH","quality":{"quality":{"resolution":2160}}},
  {"id":4,"movieId":14,"downloadId":"HD","quality":{"quality":{"resolution":1080}}},
  {"id":5,"movieId":15,"downloadId":"DONE","quality":{"quality":{"resolution":2160}}}
]'
got=$(slow_4k "$queue" "$now" <<EOF | tr '\t' : | paste -sd,
[
  {"hash":"slow","name":"a","progress":0.1,"added_on":$((now - 2 * h)),"eta":$((13 * h))},
  {"hash":"fast","name":"b","progress":0.1,"added_on":$((now - 2 * h)),"eta":$((3 * h))},
  {"hash":"fresh","name":"c","progress":0,"added_on":$((now - 600)),"eta":8640000},
  {"hash":"hd","name":"d","progress":0.1,"added_on":$((now - 2 * h)),"eta":8640000},
  {"hash":"done","name":"e","progress":1,"added_on":$((now - 2 * h)),"eta":8640000}
]
EOF
)
[[ $got == SLOW:a ]] || fail "slow_4k picked: $got"

api() {
  case "$1 $2" in
    "radarr GET") echo '{"records":[{"id":7,"downloadId":"MOVIE"}]}' ;;
    "sonarr GET") echo '{"records":[{"id":3,"downloadId":"EPISODE"}]}' ;;
    *) echo "$1 $2 $3" >>"$T/api" ;;
  esac
}
drop episode "Show S01" "parou" 2>/dev/null || fail "drop did not find a download in Sonarr's queue"
[[ $(cat "$T/api") == "sonarr DELETE /queue/3?removeFromClient=true&blocklist=false" ]] ||
  fail "drop sent: $(cat "$T/api")"
grep -q 'Show S01 parou' "$MEDIA_LOG" || fail "drop did not log the dropped download"
rm "$T/api"
! drop byhand "Mine" "parou" 2>/dev/null || fail "drop claimed a download no app grabbed"
[[ ! -e $T/api ]] || fail "drop touched an app for a download no app grabbed"

((failures == 0)) || { echo "media_torrents: $failures failure(s)"; exit 1; }
echo "media_torrents: ok"
