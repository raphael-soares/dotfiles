#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
mkdir -p "$HOME" "$T/bin" "$T/overrides"
export FAKE_OVERRIDES=$T/overrides FAKE_INSTALLED="vectorcraft photocraft filmcraft pdfcraft"

cat >"$T/bin/flatpak" <<'EOF'
#!/usr/bin/env bash
case $1 in
  info) [[ " $FAKE_INSTALLED " == *" ${!##ai.storyteller.} "* ]] ;;
  override)
    file=$FAKE_OVERRIDES/${!#}
    if [[ $3 == --show ]]; then
      [[ ! -f $file ]] || cat "$file"
      exit 0
    fi
    for arg in "${@:3:$#-3}"; do
      case $arg in
        --env=*) printf '%s\n' "${arg#--env=}" >>"$file" ;;
        --filesystem=*) printf 'filesystems=%s;\n' "${arg#--filesystem=}" >>"$file" ;;
      esac
    done
    ;;
esac
EOF
chmod +x "$T/bin/flatpak"
cat >"$T/bin/uv" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FAKE_LOG/uv"
mkdir -p "$HOME/.local/bin" && install -m 755 /dev/null "$HOME/.local/bin/manim"
EOF
cat >"$T/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "$*" >>"$FAKE_LOG/systemctl"
EOF
chmod +x "$T/bin/uv" "$T/bin/systemctl"
export FAKE_LOG=$T/log && mkdir -p "$FAKE_LOG"
export PATH=$T/bin:$PATH

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }
has() { grep -qx -- "$2" "$T/overrides/ai.storyteller.$1" 2>/dev/null; }
token() { sed -n "s/^${1^^}_CONTROL_TOKEN=//p" "$T/overrides/ai.storyteller.$1" | tail -1; }

"$REPO/design/bin/design-deploy" "$REPO" >/dev/null

has filmcraft FILMCRAFT_CONTROL_PORT=7984 || fail "filmcraft lacks its port"
[[ $(token filmcraft) =~ ^[0-9a-f]{64}$ ]] || fail "filmcraft token is not 64 hex"
has filmcraft 'filesystems=~/Design;' || fail "filmcraft lacks ~/Design"
has vectorcraft VECTORCRAFT_CONTROL_PORT=7979 || fail "vectorcraft lacks its port"
[[ -z $(token vectorcraft) ]] || fail "vectorcraft got a token"
has photocraft "PHOTOCRAFT_AUTOMATION_READ_ROOT=$HOME/Design" || fail "photocraft lacks its read root"
has photocraft "PHOTOCRAFT_AUTOMATION_WRITE_ROOT=$HOME/Design" || fail "photocraft lacks its write root"
has pdfcraft 'filesystems=~/Design;' || fail "pdfcraft lacks ~/Design"
[[ ! -e $T/overrides/ai.storyteller.gridcraft ]] || fail "uninstalled gridcraft got an override"
[[ -d $HOME/Design ]] || fail "the Design folder was not created"

first=$(token filmcraft)
"$REPO/design/bin/design-deploy" "$REPO" >/dev/null
[[ $(token filmcraft) == "$first" ]] || fail "second run changed the filmcraft token"

mcp=$HOME/.omp/agent/.mcp.json
# shellcheck disable=SC2016
jq -e '.mcpServers.vectorcraft == {"command":"craft-mcp","args":["vectorcraft"],"cwd":"${HOME}"}' "$mcp" >/dev/null ||
  fail "vectorcraft entry is wrong"
[[ $(jq -c '.mcpServers | keys' "$mcp") == '["filmcraft","pdfcraft","photocraft","vectorcraft"]' ]] ||
  fail ".mcp.json lists other apps than the installed ones: $(jq -c '.mcpServers | keys' "$mcp")"

grep -qx -- '--user daemon-reload' "$FAKE_LOG/systemctl" 2>/dev/null || fail "systemd was not reloaded"
[[ $(cat "$FAKE_LOG/uv" 2>/dev/null) == "tool install manim" ]] ||
  fail "manim was not installed exactly once over two runs: $(cat "$FAKE_LOG/uv" 2>/dev/null)"

((failures == 0)) || exit 1
echo "design deploy: ok"
