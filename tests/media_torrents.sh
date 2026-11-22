#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
MEDIA_TORRENTS_LIB=1 MEDIA_STALL_HOURS=6 MEDIA_SLOW_4K_HOURS=12 MEDIA_MIN_SEEDS=5 source "$REPO/media/bin/media-torrents"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

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
[[ $got == meta-old,stalled-old ]] || fail "stalled_torrents picked: $got"

queue='[
  {"id":1,"movieId":11,"downloadId":"SLOW","quality":{"quality":{"resolution":2160}}},
  {"id":2,"movieId":12,"downloadId":"FAST","quality":{"quality":{"resolution":2160}}},
  {"id":3,"movieId":13,"downloadId":"FRESH","quality":{"quality":{"resolution":2160}}},
  {"id":4,"movieId":14,"downloadId":"HD","quality":{"quality":{"resolution":1080}}},
  {"id":5,"movieId":15,"downloadId":"DONE","quality":{"quality":{"resolution":2160}}}
]'
got=$(slow_4k "$queue" "$now" <<EOF | cut -f1-5 | tr '\t' : | paste -sd,
[
  {"hash":"slow","name":"a","progress":0.1,"added_on":$((now - 2 * h)),"eta":$((13 * h)),"amount_left":900,"num_complete":40},
  {"hash":"fast","name":"b","progress":0.1,"added_on":$((now - 2 * h)),"eta":$((3 * h)),"amount_left":900,"num_complete":40},
  {"hash":"fresh","name":"c","progress":0,"added_on":$((now - 600)),"eta":8640000,"amount_left":900,"num_complete":0},
  {"hash":"hd","name":"d","progress":0.1,"added_on":$((now - 2 * h)),"eta":8640000,"amount_left":900,"num_complete":0},
  {"hash":"done","name":"e","progress":1,"added_on":$((now - 2 * h)),"eta":8640000,"amount_left":0,"num_complete":9}
]
EOF
)
[[ $got == 1:11:SLOW:900:40 ]] || fail "slow_4k picked: $got"

gb=1000000000
releases='[
  {"guid":"g-4k","indexerId":1,"title":"4k","size":'$((5 * gb))',"seeders":90,"customFormatScore":3000,"quality":{"quality":{"resolution":2160}},"rejections":[]},
  {"guid":"g-few","indexerId":1,"title":"few","size":'$((6 * gb))',"seeders":4,"customFormatScore":2000,"quality":{"quality":{"resolution":1080}},"rejections":["Release in queue is of equal or higher preference"]},
  {"guid":"g-big","indexerId":1,"title":"big","size":'$((17 * gb))',"seeders":80,"customFormatScore":1900,"quality":{"quality":{"resolution":1080}},"rejections":["Release in queue is of equal or higher preference"]},
  {"guid":"g-small","indexerId":1,"title":"small","size":'$((2 * gb))',"seeders":80,"customFormatScore":1800,"quality":{"quality":{"resolution":1080}},"rejections":["Release in queue is of equal or higher preference","1.7 GB is smaller than minimum allowed"]},
  {"guid":"g-ok","indexerId":2,"title":"ok","size":'$((7 * gb))',"seeders":6,"customFormatScore":1500,"quality":{"quality":{"resolution":1080}},"rejections":["Release in queue is of equal or higher preference"]},
  {"guid":"g-more","indexerId":2,"title":"more","size":'$((8 * gb))',"seeders":60,"customFormatScore":0,"quality":{"quality":{"resolution":1080}},"rejections":[]}
]'
got=$(pick_1080p $((12 * gb)) 0 <<<"$releases" | cut -f1)
[[ $got == g-ok ]] || fail "pick_1080p with a dead 4K swarm picked: $got"
got=$(pick_1080p $((12 * gb)) 40 <<<"$releases" | cut -f1)
[[ $got == g-more ]] || fail "pick_1080p against a 40 seeder 4K picked: $got"
got=$(pick_1080p $((7 * gb)) 0 <<<"$releases" | cut -f1)
[[ -z $got ]] || fail "pick_1080p picked a release no smaller than the 4K left: $got"

((failures == 0)) || { echo "media_torrents: $failures failure(s)"; exit 1; }
echo "media_torrents: ok"
