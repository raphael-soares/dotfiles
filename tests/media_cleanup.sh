#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

MEDIA_CLEANUP_LIB=1 MEDIA_SEED_RATIO=1 MEDIA_SEED_DAYS=30 MEDIA_SEED_SWARM=50 source "$REPO/media/bin/media-cleanup"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

got=$(watched_before 2026-11-08T00:00:00 <<'EOF'
{"path":"/old","last":"2026-10-01T10:00:00.000Z"}
{"path":"/recent","last":"2026-11-20T10:00:00.000Z"}
{"path":"/shared","last":"2026-10-01T10:00:00.000Z"}
{"path":"/shared","last":"2026-11-21T10:00:00.000Z"}
EOF
)
[[ $got == '["/old"]' ]] || fail "watched_before kept the wrong files: $got"

grabbed='{"grabbed":["AAA","BBB","CCC","DDD","EEE","GGG"],"queued":["EEE"]}'
day=86400
got=$(spent_torrents "$grabbed" <<EOF | cut -f2 | sort | paste -sd,
[
  {"hash":"aaa","name":"ratio-met","ratio":1.2,"seeding_time":$day,"num_complete":3},
  {"hash":"bbb","name":"low-ratio-fresh","ratio":0.3,"seeding_time":$((2 * day)),"num_complete":49},
  {"hash":"ccc","name":"low-ratio-old","ratio":0.3,"seeding_time":$((31 * day)),"num_complete":2},
  {"hash":"ddd","name":"ratio-exact","ratio":1,"seeding_time":0,"num_complete":0},
  {"hash":"eee","name":"still-queued","ratio":5,"seeding_time":$((40 * day)),"num_complete":900},
  {"hash":"fff","name":"added-by-hand","ratio":5,"seeding_time":$((40 * day)),"num_complete":900},
  {"hash":"ggg","name":"big-swarm","ratio":0,"seeding_time":60,"num_complete":50}
]
EOF
)
[[ $got == big-swarm,low-ratio-old,ratio-exact,ratio-met ]] || fail "spent_torrents picked: $got"

mkdir -p "$T/dl/pack" "$T/lib"
touch "$T/dl/pack/a.mkv" "$T/dl/pack/b.nfo"
linked "$T/dl" pack/a.mkv pack/b.nfo && fail "torrent without hardlinks counted as linked"
ln "$T/dl/pack/a.mkv" "$T/lib/a.mkv"
linked "$T/dl" pack/b.nfo pack/a.mkv || fail "torrent with a library hardlink counted as unlinked"
linked "$T/dl" pack/gone.mkv && fail "missing file counted as linked"

((failures == 0)) && echo "media_cleanup: ok"
exit "$failures"
