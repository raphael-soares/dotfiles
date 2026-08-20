#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

STOW_PKGS=(bash tmux alacritty git starship fzf local mise nvim ai)

cat <<'EOF'
Deps:

  stow git tmux nvim fzf starship mise alacritty tpm
  jq curl gh openfortivpn jetbrainsmono-nerd-font fzf

EOF

if ! command -v stow >/dev/null || ! command -v git >/dev/null; then
  echo "Precisa de stow e git para rodar este script." >&2
  exit 1
fi

echo "==> Stowing..."
stow --adopt -R "${STOW_PKGS[@]}"
git restore -- "${STOW_PKGS[@]}"

echo
echo "Done."
