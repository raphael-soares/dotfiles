#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/bin"
printf '#!/bin/sh\necho "$*" >>"%s/pkill.log"\n' "$T" >"$T/bin/pkill"
chmod +x "$T/bin/pkill"
export PATH=$T/bin:$PATH XDG_RUNTIME_DIR=$T/run
REMOTE_SERVING_LIB=1 source "$REPO/hyprland/bin/remote-serving"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
S=$T/run/remote/serving
C='[2026-11-24 00:13:53.045]: Info: CLIENT CONNECTED'
D='[2026-11-24 00:13:59.654]: Info: CLIENT DISCONNECTED'
feed() { rm -f "$T/pkill.log"; printf '%s\n' "$@" | follow; }

mkdir -p "$T/run/remote"
touch "$S"
feed 'Info: Screencasting with KMS'
[[ ! -e $S ]] || fail "a sun left by the previous run stays lit"

feed "$C"
[[ -e $S ]] || fail "a client connecting does not light the sun"
[[ $(cat "$T/pkill.log" 2>/dev/null) == '-x moonlight' ]] || fail "this machine's Moonlight is not closed when the peer connects"

feed "$C" "$D"
[[ ! -e $S ]] || fail "the sun stays lit after the only client left"

feed "$C" "$C" "$D"
[[ -e $S ]] || fail "the sun goes out while a second client still watches"

feed "$D" "$C"
[[ -e $S ]] || fail "a disconnect with no client drove the count below zero"

if ((failures)); then
  echo "remote_serving: $failures failure(s)"
  exit 1
fi
echo "remote_serving: ok"
