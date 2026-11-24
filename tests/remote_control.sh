#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/bin" "$T/run/remote"
for cmd in ssh hyprctl; do
  printf '#!/bin/sh\necho "%s $*" >>"%s/calls"\nexit ${STUB_RC:-0}\n' "$cmd" "$T" >"$T/bin/$cmd"
done
# A local Moonlight is the file $T/moonlight: pkill removes it, pgrep finds it.
printf '#!/bin/sh\necho "pkill $*" >>"%s/calls"\n[ -e "%s/moonlight" ] || exit 1\nrm "%s/moonlight"\n' "$T" "$T" "$T" >"$T/bin/pkill"
printf '#!/bin/sh\n[ -e "%s/moonlight" ]\n' "$T" >"$T/bin/pgrep"
chmod +x "$T"/bin/*
export PATH=$T/bin:$PATH XDG_RUNTIME_DIR=$T/run
echo fedora >"$T/run/remote/peer"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
on() {
  rm -f "$T/run/remote/serving" "$T/run/remote/viewing" "$T/moonlight" "$T/calls"
  case $1 in
    viewing) touch "$T/run/remote/viewing" "$T/moonlight" ;;
    serving) touch "$T/run/remote/serving" ;;
  esac
}
run() { "$REPO/hyprland/bin/remote-control" "$@" 2>"$T/err"; }
calls() { cat "$T/calls" 2>/dev/null; }

on serving; run stop
[[ $(calls) == "ssh "*" fedora pkill -x moonlight" ]] || fail "stop while watched does not close the peer's Moonlight: $(calls)"

on viewing; run stop
[[ $(calls) == "pkill -x moonlight" ]] || fail "stop while watching does not close this Moonlight: $(calls)"

on serving; run swap
[[ $(calls | head -1) == *" fedora pkill -x moonlight" && $(calls | tail -1) == "hyprctl eval "*toggle* ]] ||
  fail "swap while watched does not close the peer's Moonlight and then open this one: $(calls)"

on viewing; run swap
[[ $(calls | sed -n 2p) == "pkill -x moonlight" && $(calls | sed -n 3p) == "ssh "*" fedora "*toggle* && ! -e $T/moonlight ]] ||
  fail "swap while watching does not close this Moonlight and then open the peer's: $(calls)"

on viewing
if STUB_RC=255 run swap; then fail "swap reports success with the peer unreachable"; fi
[[ -e $T/moonlight ]] || fail "swap closed this stream although the peer cannot take over"

on viewing; touch "$T/run/remote/serving"; run stop
[[ $(calls) == "pkill -x moonlight" ]] || fail "a serving file left behind turns stop on the wrong side: $(calls)"

on serving
if STUB_RC=255 run stop; then fail "stop reports success with the peer unreachable"; fi
grep -q 'Could not reach fedora' "$T/err" || fail "an unreachable peer is not named: $(cat "$T/err")"

on idle
if run swap; then fail "swap with no stream reports success"; fi

if ((failures)); then
  echo "remote_control: $failures failure(s)"
  exit 1
fi
echo "remote_control: ok"
