#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

STOW_PKGS=(bash tmux alacritty git starship fzf local mise nvim ai)

cat <<'EOF'
Deps:

  stow git tmux nvim fzf starship mise alacritty tpm
  jq curl gh openfortivpn jetbrainsmono-nerd-font

EOF

if ! command -v stow >/dev/null || ! command -v git >/dev/null; then
  echo "Precisa de stow e git para rodar este script." >&2
  exit 1
fi

# Nunca sobrescreve: o arquivo da maquina tem chave de API e caminho local.
if [ -f "$HOME/.env.local" ]; then
  echo "==> ~/.env.local ja existe, mantido"
else
  cp .env.example "$HOME/.env.local"
  echo "==> ~/.env.local criado a partir do .env.example"
fi

echo "==> Stowing..."
stow --adopt -R "${STOW_PKGS[@]}"
git restore -- "${STOW_PKGS[@]}"

echo
echo "Done."
