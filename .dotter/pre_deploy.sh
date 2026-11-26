#!/usr/bin/env bash
# Runs before dotter links anything: ~/Documents and ~/Pictures/Wallpaper are links into
# ~/Drive, and a link made after dotter would find a real directory in its place.
set -euo pipefail

# drive_link <link> <target>: leaves a real directory that holds files alone.
drive_link() {
  local link=$1 target=$2
  mkdir -p "$target" "${link%/*}"
  if [[ -L $link ]]; then
    [[ $(readlink "$link") == "$target" ]] || ln -sfn "$target" "$link"
    return 0
  fi
  if [[ -d $link ]] && ! rmdir "$link" 2>/dev/null; then
    echo "==> ${link/#"$HOME"/\~} has files; move them to ${target/#"$HOME"/\~}, remove it and deploy again" >&2
    return 0
  fi
  [[ -e $link ]] || ln -s "$target" "$link"
}

# desktop and hyprland are on both machines.
drive_link "$HOME/Documents" "$HOME/Drive/Documents"
# The repo's forest-4.jpg is linked into Wallpaper, which the Drive pair excludes.
drive_link "$HOME/Pictures/Wallpaper" "$HOME/Drive/Personal/Wallpaper"
