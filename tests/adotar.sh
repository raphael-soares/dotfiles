#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
H=$T/home
mkdir -p "$H/.config/hypr" "$H/.config/nvim"

ln -s "$REPO/bash/.bashrc" "$H/.bashrc"
ln -s "$REPO/hypr/.config/hypr/hyprland.lua" "$H/.config/hypr/hyprland.lua"
echo antigo >"$H/.gitconfig"
echo antigo >"$H/.config/nvim/init.lua"
ln -s /etc/hostname "$H/.config/outro"
echo meu >"$H/notas.txt"

HOME=$H DOTFILES_SO_LINKS=1 "$REPO/.dotter/adotar.sh" -l .dotter/notebook.toml \
  --cache-file "$T/cache.toml" --cache-directory "$T/cache"

falhas=0
falha() { echo "FALHOU: $*"; falhas=$((falhas + 1)); }

for f in .bashrc .gitconfig .config/hypr .config/nvim .config/ghostty/config; do
  [[ -L $H/$f && $(readlink -f "$H/$f") == "$REPO"/* ]] || falha "$f não virou link para o repo"
done
backup=$(find "$H/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d)
[[ $(cat "$backup/.gitconfig" 2>/dev/null) == antigo ]] || falha ".gitconfig antigo não está no backup"
[[ $(cat "$backup/.config/nvim/init.lua" 2>/dev/null) == antigo ]] || falha "nvim antigo não está no backup"
[[ $(readlink "$H/.config/outro") == /etc/hostname ]] || falha "link de fora do repo foi mexido"
[[ $(cat "$H/notas.txt") == meu ]] || falha "arquivo fora do mapeamento foi mexido"

if ((falhas)); then
  echo "adotar: $falhas falha(s)"
  exit 1
fi
echo "adotar: ok"
