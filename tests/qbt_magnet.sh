#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

mkdir "$T/bin"
cat >"$T/bin/xdg-open" <<EOF
#!/bin/sh
printf '%s' "\$1" >"$T/opened"
EOF
chmod +x "$T/bin/xdg-open"

magnet='magnet:?xt=urn:btih:ABC&dn=Ação 2 & Co'
PATH=$T/bin:$PATH "$REPO/media/bin/qbt-magnet" "$magnet"

url=$(cat "$T/opened")
prefix='http://127.0.0.1:8080/#download='
[[ $url == "${prefix}magnet%3A%3Fxt%3Durn%3Abtih%3AABC%26dn%3D"* ]] || { echo "FAILED: unexpected url $url"; exit 1; }
decoded=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]), end="")' "${url#"$prefix"}")
[[ $decoded == "$magnet" ]] || { echo "FAILED: decoded $decoded"; exit 1; }
echo "qbt_magnet: ok"
