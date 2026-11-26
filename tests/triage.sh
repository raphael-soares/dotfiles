#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
TRIAGE=$REPO/terminal/bin/triage
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# The fake games host answers only while $T/fedora_up exists; its remote home is
# $T/remote. The fake rsync truncates the copy while $T/rsync_short exists.
mkdir -p "$T/bin" "$T/remote"
cat >"$T/bin/ssh" <<EOF
#!/bin/sh
[ -e "$T/fedora_up" ] || exit 255
while [ "\$1" = -o ]; do shift 2; done
shift
[ "\$1" = true ] && exit 0
cd "$T/remote" && exec sh -c "\$*"
EOF
cat >"$T/bin/rsync" <<EOF
#!/bin/sh
for a in "\$@"; do src=\$dst; dst=\$a; done
cp "\$src" "$T/remote/\${dst#*:}"
[ -e "$T/rsync_short" ] && truncate -s 1 "$T/remote/\${dst#*:}"
exit 0
EOF
chmod +x "$T"/bin/*
export PATH=$T/bin:$PATH

H=$T/home
export TRIAGE_HOME=$H XDG_STATE_HOME=$T/state
TODAY=$(date +%F)

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
old() { mkdir -p "$(dirname "$1")"; printf '%s' "${2:-data}" >"$1"; touch -d '2 hours ago' "$1"; }
here() { [[ -f $1 ]] || fail "missing: ${1#"$T"/}"; }
gone() { [[ ! -e $1 ]] || fail "should not be there: ${1#"$T"/}"; }
jqe() { jq -r "$1" <<<"$OUT"; }

old "$H/Downloads/a.torrent"
old "$H/Downloads/Screenshot_from_2026.png"
old "$H/Downloads/pac.csv" $'Nome,Paciente,Idade\n1,2,3\n'
old "$H/Downloads/other.csv" $'Nome,Idade\n1,2\n'
old "$H/Downloads/unknown.pdf"
old "$H/Downloads/movie.mp4.part"
old "$H/Downloads/.hidden"
old "$H/Downloads/game.nsp" "nsp-data"
old "$H/Downloads/folder/inside.torrent"
old "$H/Drive/Inbox/b.torrent" "new"
old "$H/Drive/Personal/Torrents/b.torrent" "already here"
old "$H/Pictures/2026-11-26-101010_hyprshot.png"
old "$H/Pictures/photo.jpg"
old "$H/Pictures/Screenshots/keep.png"
printf x >"$H/Downloads/fresh.torrent"

# dry-run reports and moves nothing
OUT=$("$TRIAGE" run --dry-run)
[[ $(jqe '.moved | length') == 5 ]] || fail "dry-run should plan 5 moves, got: $OUT"
here "$H/Downloads/a.torrent"
gone "$T/state/triage/$TODAY.log"

# games host down: the game stays and is pending
OUT=$("$TRIAGE" run)
[[ $(jqe '.moved | length') == 5 ]] || fail "run should move 5 files, got: $OUT"
[[ $(jqe '[.moved[] | select(.from | endswith("b.torrent")) | .to] | .[0]') == "$H/Drive/Personal/Torrents/b (2).torrent" ]] ||
  fail "an existing destination was not given a (2) suffix"
[[ $(jqe '.moved[] | select(.from | endswith("pac.csv")) | .rule') == csv-paciente ]] || fail "csv rule not reported"
here "$H/Drive/Personal/Torrents/a.torrent"
here "$H/Drive/Personal/Torrents/b.torrent"
[[ $(<"$H/Drive/Personal/Torrents/b.torrent") == "already here" ]] || fail "an existing file was overwritten"
here "$H/Drive/Personal/Torrents/b (2).torrent"
here "$H/Pictures/Screenshots/Screenshot_from_2026.png"
here "$H/Pictures/Screenshots/2026-11-26-101010_hyprshot.png"
here "$H/Code/TEAjudo/teajudo/attachments/inbox/pac.csv"
here "$H/Downloads/other.csv"
here "$H/Downloads/unknown.pdf"
here "$H/Downloads/movie.mp4.part"
here "$H/Downloads/fresh.torrent"
here "$H/Downloads/folder/inside.torrent"
here "$H/Downloads/game.nsp"
here "$H/Pictures/photo.jpg"
want=$(printf '%s\n' "$H/Downloads/game.nsp" "$H/Downloads/other.csv" "$H/Downloads/unknown.pdf" "$H/Pictures/photo.jpg")
[[ $(jqe '.pending | sort | .[]') == "$want" ]] || fail "pending with the host down: $(jqe '.pending')"
[[ $("$TRIAGE" pending | sort) == "$want" ]] || fail "triage pending disagrees with run"
[[ $(wc -l <"$T/state/triage/$TODAY.log") == 5 ]] || fail "log should have 5 lines"
awk -F'\t' 'NF != 4 { exit 1 }' "$T/state/triage/$TODAY.log" || fail "log lines are not 4-column TSV"
[[ ! -e $T/remote/Games ]] || fail "the remote was touched while down"

# host up but the copy comes out short: the local file must stay
touch "$T/fedora_up" "$T/rsync_short"
OUT=$("$TRIAGE" run 2>/dev/null)
here "$H/Downloads/game.nsp"
[[ $(jqe '.moved | length') == 0 ]] || fail "a short copy was reported as moved"
gone "$T/remote/Games/Switch/game.nsp"
[[ $(jqe '.pending | index("'"$H"'/Downloads/game.nsp") != null') == true ]] || fail "a failed transfer is not pending"

# host up, copy ok
rm "$T/rsync_short"
OUT=$("$TRIAGE" run 2>/dev/null)
gone "$H/Downloads/game.nsp"
[[ $(<"$T/remote/Games/Switch/game.nsp") == nsp-data ]] || fail "game not on the remote"
[[ $(jqe '.moved[0].rule') == switch && $(jqe '.moved[0].to') == "fedora:Games/Switch/game.nsp" ]] || fail "switch move not reported: $OUT"

# a game with a name already on the remote keeps both
old "$H/Downloads/game.nsp" "second"
"$TRIAGE" run >/dev/null 2>&1
[[ $(<"$T/remote/Games/Switch/game (2).nsp") == second ]] || fail "remote file was overwritten or not suffixed"
[[ $(<"$T/remote/Games/Switch/game.nsp") == nsp-data ]] || fail "remote game.nsp changed"

# move for the agent
old "$H/Downloads/x.txt" "x1"
OUT=$("$TRIAGE" move "$H/Downloads/x.txt" "$H/Drive/Personal/Archive/")
[[ $(jqe '.moved[0].rule') == agent ]] || fail "move rule is not agent"
here "$H/Drive/Personal/Archive/x.txt"
old "$H/Downloads/x.txt" "x2"
"$TRIAGE" move "$H/Downloads/x.txt" "$H/Drive/Personal/Archive/x.txt" >/dev/null
[[ $(<"$H/Drive/Personal/Archive/x.txt") == x1 ]] || fail "move overwrote the destination"
[[ $(<"$H/Drive/Personal/Archive/x (2).txt") == x2 ]] || fail "move did not suffix the destination"
"$TRIAGE" move "$H/Downloads/nope.txt" "$H/Drive/" 2>/dev/null && fail "moving a missing file succeeded"

# undo restores in reverse, keeps what it cannot restore
OUT=$("$TRIAGE" undo "$TODAY")
here "$H/Downloads/a.torrent"
here "$H/Downloads/Screenshot_from_2026.png"
here "$H/Downloads/pac.csv"
here "$H/Drive/Inbox/b.torrent"
here "$H/Pictures/2026-11-26-101010_hyprshot.png"
here "$H/Downloads/x.txt"
gone "$H/Drive/Personal/Torrents/b (2).torrent"
[[ $(<"$H/Drive/Personal/Torrents/b.torrent") == "already here" ]] || fail "undo touched the pre-existing file"
[[ $(<"$H/Downloads/x.txt") == x2 ]] || fail "undo restored the wrong x.txt"
[[ $(<"$H/Drive/Personal/Archive/x.txt") == x1 ]] || fail "undo moved the wrong archive file"
[[ $(jqe '[.skipped[] | select(.to | startswith("fedora:"))] | length') == 2 ]] || fail "remote moves should be skipped by undo: $OUT"

"$TRIAGE" undo 1999-01-01 2>/dev/null && fail "undo of a day without a log succeeded"
"$TRIAGE" bogus 2>/dev/null && fail "an unknown command succeeded"
"$TRIAGE" --help | grep -q 'triage run' || fail "--help does not describe run"

if ((failures)); then
  echo "triage: $failures failure(s)"
  exit 1
fi
echo "triage: ok"
