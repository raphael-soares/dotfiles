#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

STOW_PKGS=(bash tmux alacritty git starship fzf local mise nvim ai workmux)

cat <<'EOF'
Deps:

  stow git tmux nvim fzf starship mise alacritty tpm
  jq curl gh openfortivpn jetbrainsmono-nerd-font workmux

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

# O workmux reescreve o proprio config.yaml (prompt de nerdfont, workmux
# config edit). Se o diretorio nao existir, o stow dobra ~/.config/workmux
# num symlink para dentro do repo e essas escritas viram sujeira versionada.
mkdir -p "$HOME/.config/workmux"

echo "==> Stowing..."
stow --adopt -R "${STOW_PKGS[@]}"
git restore -- "${STOW_PKGS[@]}"

echo
echo "Done."
