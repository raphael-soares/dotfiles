#!/usr/bin/env bash
# Arch Linux bootstrap: install every dependency through yay, then deploy the
# dotfiles with stow. Idempotent — safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

# Packages — official repos and AUR alike, all installed through yay.
PKGS=(
  stow git github-cli tmux alacritty starship fzf mise neovim
  jq curl openfortivpn ttf-jetbrains-mono-nerd
  claude-code     # AUR — used by the `acmit` script (skip if you only use GEMINI_API_KEY)
  kwin-scripts-krohnkite  # AUR — tiling window manager script for KWin
)

# Stow packages to deploy (each maps to a top-level dir in this repo).
STOW_PKGS=(bash tmux alacritty git starship fzf local mise zennotes nvim kde)

# ── Ensure yay is present (bootstrap it from the AUR if not) ─────────────────
if ! command -v yay >/dev/null; then
  echo "==> yay not found, building it from the AUR"
  sudo pacman -S --needed --noconfirm base-devel git
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
fi

# ── Install packages ────────────────────────────────────────────────────────
echo "==> Installing packages via yay"
yay -S --needed "${PKGS[@]}"

# ── Locales ──────────────────────────────────────────────────────────────────
# The graphical session exports pt_BR.UTF-8 for the LC_* format variables while
# LANG stays en_US.UTF-8, so both locales must be generated or perl/git/etc.
# spew "Setting locale failed" warnings. Uncomment both and (re)generate.
echo "==> Ensuring locales are generated"
for loc in en_US.UTF-8 pt_BR.UTF-8; do
  sudo sed -i "s/^#\s*\(${loc} UTF-8\)/\1/" /etc/locale.gen
done
sudo locale-gen
# Keep LANG explicit so the session always has a generated default to fall back to.
[ -f /etc/locale.conf ] && grep -q '^LANG=' /etc/locale.conf \
  || echo 'LANG=en_US.UTF-8' | sudo tee /etc/locale.conf >/dev/null

# ── tmux plugin manager into the XDG path the config expects ─────────────────
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
  echo "==> Cloning TPM"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

# ── Local env file ──────────────────────────────────────────────────────────
[ -f "$HOME/.env.local" ] || cp .env.example "$HOME/.env.local"

# ── Stow, overriding any config that was already on the machine ─────────────
# --adopt pulls conflicting files into the repo; git restore then resets them
# to the committed versions, so every symlink ends up pointing at the repo.
echo "==> Stowing dotfiles"
stow --adopt -R "${STOW_PKGS[@]}"
git restore .

# ── Reload KDE/KWin config if running in a Plasma session ────────────────────
# KWin reconfigure also re-registers Krohnkite shortcuts, so no separate
# kglobalaccel call is needed.
if [ -n "${KDE_SESSION_VERSION:-}" ]; then
  echo "==> Recarregando configurações do KWin e Atalhos"
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo
echo "Done. Start tmux and press 'prefix + I' to install the tmux plugins."
