#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
MEDIA_TORRENTS_LIB=1 MEDIA_STALL_HOURS=6 source "$REPO/media/bin/media-torrents"

now=1800000000
h=3600
got=$(stalled_torrents "$now" <<EOF | sort | paste -sd,
[
  {"hash":"meta-old","category":"Movies","state":"metaDL","added_on":$((now - 7 * h)),"last_activity":0},
  {"hash":"meta-new","category":"Movies","state":"metaDL","added_on":$((now - 1 * h)),"last_activity":0},
  {"hash":"stalled-old","category":"Anime","state":"stalledDL","added_on":$((now - 50 * h)),"last_activity":$((now - 6 * h))},
  {"hash":"stalled-recent","category":"Series","state":"stalledDL","added_on":$((now - 50 * h)),"last_activity":$((now - 2 * h))},
  {"hash":"queued","category":"Movies","state":"queuedDL","added_on":$((now - 50 * h)),"last_activity":0},
  {"hash":"game","category":"Games/Switch","state":"stalledDL","added_on":$((now - 50 * h)),"last_activity":0},
  {"hash":"seeding","category":"Movies","state":"stalledUP","added_on":$((now - 50 * h)),"last_activity":0}
]
EOF
)
if [[ $got != meta-old,stalled-old ]]; then
  echo "FAILED: stalled_torrents picked: $got"
  exit 1
fi
echo "media_torrents: ok"
