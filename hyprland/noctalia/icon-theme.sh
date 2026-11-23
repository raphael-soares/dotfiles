#!/usr/bin/env bash
# Usage: icon-theme.sh <Yaru variant> <dark|light>
# Points every icon reader at the Yaru variant, and makes Papirus the only fallback.
set -euo pipefail

theme=$1
papirus=Papirus
[[ $2 == dark ]] && papirus=Papirus-Dark
data="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

# A user index.theme shadows the system one, so its Inherits line is ours to pick.
# Yaru inherits the missing Humanity, Papirus inherits Breeze. qt6ct links KIconThemes,
# which makes breeze the Qt fallback theme and bundles it: an empty breeze shadows both.
inherit() {
  local name=$1 parents=$2 src=/usr/share/icons/$1/index.theme
  [[ -f $src ]] || return 0
  mkdir -p "$data/$name"
  rm -f "$data/$name/index.theme"
  sed "s/^Inherits=.*/Inherits=$parents/" "$src" >"$data/$name/index.theme"
}
inherit Yaru "$papirus,hicolor"
inherit Papirus hicolor
inherit Papirus-Dark hicolor
inherit Papirus-Light hicolor
for name in breeze breeze-dark; do
  mkdir -p "$data/$name"
  printf '[Icon Theme]\nName=%s\nDirectories=\nInherits=%s,hicolor\n' "$name" "$papirus" >"$data/$name/index.theme"
done

gsettings set org.gnome.desktop.interface icon-theme "$theme"
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme "$theme"
fi
