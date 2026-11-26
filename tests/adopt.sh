#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
H=$T/home
mkdir -p "$H/.config/hypr" "$H/.config/nvim" "$H/.config/git"

ln -s "$REPO/bash/.bashrc" "$H/.bashrc"
ln -s "$REPO/hypr/.config/hypr/hyprland.lua" "$H/.config/hypr/hyprland.lua"
echo old >"$H/.config/git/config"
echo old >"$H/.config/nvim/init.lua"
ln -s /etc/hostname "$H/.config/other"
echo mine >"$H/notes.txt"

if HOME=$H DOTFILES_LINKS_ONLY=1 "$REPO/.dotter/adopt.sh" -g .dotter/does-not-exist.toml \
  --cache-file "$T/cache.toml" --cache-directory "$T/cache" >/dev/null 2>&1; then
  echo "FAILED: adopt.sh passed with an invalid config"; exit 1
fi
[[ -L $H/.bashrc && -L $H/.config/hypr/hyprland.lua ]] || { echo "FAILED: invalid config and the old links are gone"; exit 1; }

HOME=$H DOTFILES_LINKS_ONLY=1 "$REPO/.dotter/adopt.sh" -l .dotter/arch.toml \
  --cache-file "$T/cache.toml" --cache-directory "$T/cache"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

for f in .bashrc .config/git/config .config/hypr .config/nvim .config/ghostty/base; do
  [[ -L $H/$f && $(readlink -f "$H/$f") == "$REPO"/* ]] || fail "$f did not become a link into the repo"
done
backup=$(find "$H/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d)
[[ $(cat "$backup/.config/git/config" 2>/dev/null) == old ]] || fail "old git config is not in the backup"
[[ $(cat "$backup/.config/nvim/init.lua" 2>/dev/null) == old ]] || fail "old nvim is not in the backup"
[[ $(readlink "$H/.config/other") == /etc/hostname ]] || fail "link outside the repo was touched"
[[ $(cat "$H/notes.txt") == mine ]] || fail "file outside the mapping was touched"

if ((failures)); then
  echo "adopt: $failures failure(s)"
  exit 1
fi
echo "adopt: ok"
