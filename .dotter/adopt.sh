#!/usr/bin/env bash
# First deploy on a machine that already has config: removes old links into the
# repo, moves to ~/.dotfiles-backup whatever dotter would refuse to overwrite,
# and deploys. The arguments go straight to dotter.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO=$(pwd -P)
BACKUP=$HOME/.dotfiles-backup/$(date +%Y-%m-%d-%H%M%S)

scratch=$(mktemp -d)
if ! output=$(HOME=$scratch dotter -d "$@" deploy 2>&1); then
  echo "$output" >&2
  rm -rf "$scratch"
  exit 1
fi
rm -rf "$scratch"

while IFS= read -r -d '' link; do
  [[ $(readlink -m "$link") == "$REPO"/* ]] || continue
  echo "==> old link removed: ${link#"$HOME"/}"
  rm "$link"
done < <(find "$HOME" -xdev -maxdepth 7 \
  \( -path "$REPO" -o -path "$HOME/.workmux" -o -path "$HOME/Code" -o -path "$HOME/.cache" \
  -o -path "$HOME/.dotfiles-backup" -o -path "$HOME/.local/share/Trash" \) -prune \
  -o -type l -print0)

dry_run=$(dotter -d "$@" deploy 2>&1 || true)
if grep '\[ERROR\]' <<<"$dry_run" | grep -qv 'Skipping\.$\|Some files were skipped'; then
  echo "$dry_run" >&2
  exit 1
fi

while IFS= read -r target; do
  [[ $target == "$HOME"/* ]] || { echo "adopt.sh: outside HOME, resolve by hand: $target" >&2; exit 1; }
  if [[ -d $target && ! -L $target ]]; then
    find "$target" -depth -type d -empty -delete
    [[ -e $target ]] || continue
  fi
  dest=$BACKUP/${target#"$HOME"/}
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  echo "==> backed up: ${target#"$HOME"/} to ${dest#"$HOME"/}"
done < <(sed -n 's/^.*Creating symlink ".*" -> "\(.*\)" but .* Skipping\.$/\1/p' <<<"$dry_run")

dotter -y "$@" deploy
