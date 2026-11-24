#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# The monitor: $T/input is what it shows, $T/model what it is, $T/bus its I2C bus.
# An empty input file is a monitor that does not answer.
mkdir -p "$T/bin" "$T/run" "$T/drm/card1-DP-1" "$T/drm/card1-eDP-1"
cat >"$T/bin/ddcutil" <<EOF
#!/bin/sh
case "\$*" in
  "detect --brief")
    printf 'Invalid display\n   I2C bus:  /dev/i2c-11\n   DRM connector:    card1-eDP-1\n   Monitor:          AUO::\n'
    printf 'Display 1\n   I2C bus:          /dev/i2c-%s\n   DRM connector:    card1-DP-1\n   Monitor:          GSM:%s:\n' "\$(cat $T/bus)" "\$(cat $T/model)" ;;
  "--bus \$(cat $T/bus) --brief getvcp 60")
    v=\$(cat $T/input); [ -n "\$v" ] && echo "VCP 60 SNC \$v" ;;
esac
exit 0
EOF
printf '#!/bin/sh\necho "$*" >>"%s/hyprctl.log"\n' "$T" >"$T/bin/hyprctl"
chmod +x "$T"/bin/*
export PATH=$T/bin:$PATH XDG_RUNTIME_DIR=$T/run DRM_DIR=$T/drm
MONITOR_AWAY_LIB=1 source "$REPO/hyprland/bin/monitor-away" DP-1 "LG ULTRAGEAR" 0x03
mkdir -p "$dir"
set +e

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
monitor() { echo "$1" >"$T/drm/card1-DP-1/status"; echo "$2" >"$T/model"; echo "$3" >"$T/bus"; echo "$4" >"$T/input"; }
evaluations() { wc -l <"$T/hyprctl.log" 2>/dev/null || echo 0; }
A=$T/run/hypr-away/DP-1

monitor connected "LG ULTRAGEAR" 12 x01
poll
[[ ! -e $A ]] || fail "the LG on this machine's input is taken as away"

monitor connected "LG ULTRAGEAR" 12 x03
poll
[[ $(cat "$A" 2>/dev/null) == "$$" ]] || fail "the LG on the peer's input is not marked away with the watcher's PID"
[[ $(evaluations) == 1 ]] || fail "monitors.lua is not told when the LG goes away"
poll
[[ $(evaluations) == 1 ]] || fail "monitors.lua is told again with nothing changed"

echo 13 >"$T/bus"
poll
[[ -e $A ]] || fail "one read on a renumbered bus drops the away mark"
poll
[[ -e $A ]] || fail "the LG is lost after its bus is renumbered"

monitor connected "LG ULTRAGEAR" 13 ""
for _ in $(seq 9); do poll; done
[[ -e $A ]] || fail "a few failed reads bring the LG back"
poll
[[ ! -e $A ]] || fail "an LG that stopped answering stays off for good"

monitor connected "LG ULTRAGEAR" 13 x03
poll
monitor disconnected "LG ULTRAGEAR" 13 x03
poll
[[ ! -e $A ]] || fail "the away mark outlives unplugging the LG"

monitor connected "OFFICE 27" 13 x03
poll
[[ ! -e $A ]] || fail "another monitor on the same input code is taken as the shared LG"

if ((failures)); then
  echo "monitor_away: $failures failure(s)"
  exit 1
fi
echo "monitor_away: ok"
