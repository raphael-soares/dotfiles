#!/usr/bin/env bash
# Primeira aplicação numa máquina que já tem config: tira os links antigos para
# o repo, guarda em ~/.dotfiles-backup o que o dotter recusaria sobrescrever e
# aplica. Os argumentos vão direto para o dotter.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO=$(pwd -P)
BACKUP=$HOME/.dotfiles-backup/$(date +%Y-%m-%d-%H%M%S)

teste=$(mktemp -d)
if ! saida=$(HOME=$teste dotter -d "$@" deploy 2>&1); then
  echo "$saida" >&2
  rm -rf "$teste"
  exit 1
fi
rm -rf "$teste"

while IFS= read -r -d '' link; do
  [[ $(readlink -m "$link") == "$REPO"/* ]] || continue
  echo "==> link antigo removido: ${link#"$HOME"/}"
  rm "$link"
done < <(find "$HOME" -xdev -maxdepth 7 \
  \( -path "$REPO" -o -path "$HOME/.workmux" -o -path "$HOME/Code" -o -path "$HOME/.cache" \
  -o -path "$HOME/.dotfiles-backup" -o -path "$HOME/.local/share/Trash" \) -prune \
  -o -type l -print0)

simulacao=$(dotter -d "$@" deploy 2>&1 || true)
if grep '\[ERROR\]' <<<"$simulacao" | grep -qv 'Skipping\.$\|Some files were skipped'; then
  echo "$simulacao" >&2
  exit 1
fi

while IFS= read -r alvo; do
  [[ $alvo == "$HOME"/* ]] || { echo "adotar.sh: fora do HOME, resolva a mão: $alvo" >&2; exit 1; }
  if [[ -d $alvo && ! -L $alvo ]]; then
    find "$alvo" -depth -type d -empty -delete
    [[ -e $alvo ]] || continue
  fi
  destino=$BACKUP/${alvo#"$HOME"/}
  mkdir -p "$(dirname "$destino")"
  mv "$alvo" "$destino"
  echo "==> guardado: ${alvo#"$HOME"/} em ${destino#"$HOME"/}"
done < <(sed -n 's/^.*Creating symlink ".*" -> "\(.*\)" but .* Skipping\.$/\1/p' <<<"$simulacao")

dotter -y "$@" deploy
