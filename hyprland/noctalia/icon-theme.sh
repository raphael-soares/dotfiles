#!/usr/bin/env bash
# Usage: icon-theme.sh <Yaru variant>
# Points every icon reader at the Yaru variant, with nothing but hicolor behind it.
set -euo pipefail

theme=$1
data="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

# A user index.theme shadows the system one, so its Inherits line is ours to pick.
# Yaru inherits the missing Humanity. qt6ct links KIconThemes, which makes breeze the
# Qt fallback theme and bundles it: an empty breeze shadows both.
mkdir -p "$data/Yaru"
rm -f "$data/Yaru/index.theme"
sed "s/^Inherits=.*/Inherits=hicolor/" /usr/share/icons/Yaru/index.theme >"$data/Yaru/index.theme"
for name in breeze breeze-dark; do
  mkdir -p "$data/$name"
  printf '[Icon Theme]\nName=%s\nDirectories=\nInherits=hicolor\n' "$name" >"$data/$name/index.theme"
done

gsettings set org.gnome.desktop.interface icon-theme "$theme"
if command -v kwriteconfig6 >/dev/null; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme "$theme"
fi
