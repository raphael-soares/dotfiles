#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

mkdir -p "$T/bin" "$T/run/remote"
for cmd in ssh pkill hyprctl; do
  printf '#!/bin/sh\necho "%s $*" >>"%s/calls"\nexit ${STUB_RC:-0}\n' "$cmd" "$T" >"$T/bin/$cmd"
done
printf '#!/bin/sh\nexit 1\n' >"$T/bin/pgrep"
chmod +x "$T"/bin/*
export PATH=$T/bin:$PATH XDG_RUNTIME_DIR=$T/run
echo fedora >"$T/run/remote/peer"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
on() { rm -f "$T/run/remote/serving" "$T/run/remote/viewing" "$T/calls"; [[ $1 == idle ]] || touch "$T/run/remote/$1"; }
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
[[ $(calls | head -1) == "pkill -x moonlight" && $(calls | tail -1) == "ssh "*" fedora "*toggle* ]] ||
  fail "swap while watching does not close this Moonlight and then open the peer's: $(calls)"

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
