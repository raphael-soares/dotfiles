#!/usr/bin/env bash
# Usage: icon-theme.sh <Yaru variant> <text color>
# Points every icon reader at the Yaru variant, with nothing but hicolor behind it,
# and gives Qt apps Yaru's symbolic glyphs in the palette's text color.
set -euo pipefail

theme=$1
fg=$2
data="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
yaru=/usr/share/icons/Yaru

# A user index.theme shadows the system one, so its Inherits line is ours to pick.
# Yaru inherits the missing Humanity. qt6ct links KIconThemes, which makes breeze the
# Qt fallback theme and bundles it: an empty breeze shadows both.
mkdir -p "$data/Yaru"
rm -f "$data/Yaru/index.theme"
sed "s/^Inherits=.*/Inherits=hicolor/" "$yaru/index.theme" >"$data/Yaru/index.theme"
for name in breeze breeze-dark; do
  mkdir -p "$data/$name"
  printf '[Icon Theme]\nName=%s\nDirectories=\nInherits=hicolor\n' "$name" >"$data/$name/index.theme"
done

# Qt asks for plain names (document-open) and never tries -symbolic, and its SVG
# loader does not recolor. So the symbolic glyphs are copied under plain names with
# Yaru's gray swapped for the text color; places and mimetypes stay full color.
recolor() {
  local svg
  IFS= read -r -d '' svg <"$1" || true
  svg=${svg//#808080/$fg}
  svg=${svg//#bebebe/$fg}
  svg=${svg//fill=\"gray\"/fill=\"$fg\"}
  svg=${svg//fill=\"#666\"/fill=\"$fg\"}
  printf '%s' "$svg" >"$2"
}
sym="$data/Yaru-symbolic"
if [[ "$(cat "$sym/.source" 2>/dev/null)" != "$theme $fg" ]]; then
  rm -rf "$sym"
  for ctx in actions status; do
    mkdir -p "$sym/$ctx"
    for src in "$yaru/scalable/$ctx/"*-symbolic.svg; do
      name=${src##*/}
      recolor "$src" "$sym/$ctx/${name%-symbolic.svg}.svg"
    done
  done
  # Breeze always puts icons on dialog buttons, under names Yaru only has in color.
  for pair in dialog-ok:actions/object-select dialog-ok-apply:actions/object-select \
    dialog-cancel:ui/window-close dialog-close:ui/window-close help-contents:apps/help-browser; do
    recolor "$yaru/scalable/${pair#*:}-symbolic.svg" "$sym/actions/${pair%%:*}.svg"
  done
  printf '[Icon Theme]\nName=Yaru-symbolic\nInherits=%s\nDirectories=actions,status\n\n[actions]\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Actions\n\n[status]\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\nContext=Status\n' \
    "$theme" >"$sym/index.theme"
  printf '%s %s' "$theme" "$fg" >"$sym/.source"
fi

gsettings set org.gnome.desktop.interface icon-theme "$theme"
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme Yaru-symbolic
fi
