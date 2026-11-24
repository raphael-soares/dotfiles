#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# $T/monitors and $T/window are what Hyprland reports, $T/outputs the order Wayland
# announced the outputs in; flameshot only records how it was called.
mkdir -p "$T/bin"
cat >"$T/bin/hyprctl" <<EOF
#!/bin/sh
case "\$1" in
  monitors) cat "$T/monitors" ;;
  activewindow) cat "$T/window" ;;
esac
EOF
cat >"$T/bin/wayland-info" <<EOF
#!/bin/sh
for o in \$(cat "$T/outputs"); do
  printf "interface: 'wl_output', version: 4, name: 1\n\tname: %s\n\tx: 0, y: 0, scale: 1,\n" "\$o"
done
EOF
printf '#!/bin/sh\necho "$*" >"%s/flameshot.args"\n' "$T" >"$T/bin/flameshot"
chmod +x "$T"/bin/*
export PATH=$T/bin:$PATH

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
shot() { rm -f "$T/flameshot.args"; "$REPO/hyprland/bin/screenshot" "$@" 2>/dev/null; cat "$T/flameshot.args" 2>/dev/null; }

cat >"$T/monitors" <<'EOF'
[{"id":0,"name":"DP-1","x":0,"y":0,"scale":1,"focused":false},
 {"id":1,"name":"eDP-1","x":1920,"y":0,"scale":1.25,"focused":true}]
EOF
echo '{"at":[1940,30],"size":[800,600]}' >"$T/window"

echo "DP-1 eDP-1" >"$T/outputs"
[[ $(shot) == "screen --number 1 --edit" ]] || fail "the focused monitor is not the one captured"

echo "eDP-1 DP-1" >"$T/outputs"
[[ $(shot) == "screen --number 0 --edit" ]] || fail "a replugged monitor shifts the capture to the wrong screen"

[[ $(shot window) == "screen --number 0 --edit --region 1000x750+25+38" ]] ||
  fail "the window selection ignores the monitor's position or scale"

echo '{}' >"$T/window"
[[ $(shot window) == "screen --number 0 --edit" ]] || fail "with no focused window the shot does not open"

echo "DP-1" >"$T/outputs"
if [[ -n $(shot) ]]; then fail "a monitor Wayland does not list is captured as another screen"; fi

if ((failures)); then
  echo "screenshot: $failures failure(s)"
  exit 1
fi
echo "screenshot: ok"
