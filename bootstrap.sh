#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

PKGS=(
  stow
  git
  github-cli
  tmux
  alacritty
  starship
  fzf
  mise
  neovim
  jq
  curl
  openfortivpn
  ttf-jetbrains-mono-nerd
  claude-code
  opencode
  kwin-scripts-krohnkite-git
)

# Agentes que nao estao nos repos: instalados via npm global.
NPM_PKGS=(@earendil-works/pi-coding-agent)

STOW_PKGS=(bash tmux alacritty git starship fzf local mise zennotes nvim kde ai)

if ! command -v yay >/dev/null; then
  echo "==> yay not found, please install it"
fi

echo "==> Installing packages via yay"
yay -S --needed "${PKGS[@]}"

echo "==> Ensuring locales are generated"
for loc in en_US.UTF-8 pt_BR.UTF-8; do
  sudo sed -i "s/^#\s*\(${loc} UTF-8\)/\1/" /etc/locale.gen
done
sudo locale-gen
[ -f /etc/locale.conf ] && grep -q '^LANG=' /etc/locale.conf \
  || echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null

if command -v npm >/dev/null; then
  echo "==> Installing agent CLIs via npm"
  npm install -g "${NPM_PKGS[@]}"
else
  echo "==> npm not found, skipping: ${NPM_PKGS[*]}"
fi

if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
  echo "==> Cloning TPM"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

[ -f "$HOME/.env.local" ] || cp .env.example "$HOME/.env.local"

echo "==> Stowing dotfiles"
stow --adopt -R "${STOW_PKGS[@]}"
git restore .

if [ -n "${KDE_SESSION_VERSION:-}" ]; then
  echo "==> Recarregando configurações do KWin e Atalhos"
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo
echo "Done. Start tmux and press 'prefix + I' to install the tmux plugins."
