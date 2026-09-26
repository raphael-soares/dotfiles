#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Modulo opcional, fora do bootstrap.sh principal de proposito: e a config do
# desktop (Hyprland + Noctalia), que so faz sentido na maquina que roda os dois.
#
# O que entra: ~/.config/hypr, os plugins autorais do Noctalia, o settings.toml
# do Noctalia, o wallpaper em uso e a cola de tema GTK/portal.

cat <<'EOF'
Deps:

  stow git hyprland noctalia xdg-desktop-portal-hyprland
  adw-gtk-theme papirus-icon-theme jetbrainsmono-nerd-font

EOF

if ! command -v stow >/dev/null || ! command -v git >/dev/null; then
  echo "Precisa de stow e git para rodar este script." >&2
  exit 1
fi

if ! command -v Hyprland >/dev/null || ! command -v noctalia >/dev/null; then
  echo "Hyprland ou Noctalia nao encontrados. Este modulo e so para esse desktop." >&2
  exit 1
fi

# Sem estes diretorios criados antes, o stow dobra cada um num symlink para
# dentro do repo e o que o app escreve ali vira sujeira versionada: o Noctalia
# grava clipboard, historico de notificacao e cache de plugin em
# ~/.local/state/noctalia, o plugin wallhaven baixa imagem em ~/Pictures/Wallpaper
# e o nwg-look reescreve colors.css e assets nos diretorios do GTK.
mkdir -p "$HOME/.config/hypr" \
         "$HOME/.config/noctalia-plugins" \
         "$HOME/.config/gtk-3.0" \
         "$HOME/.config/gtk-4.0" \
         "$HOME/.config/xdg-desktop-portal" \
         "$HOME/.local/state/noctalia" \
         "$HOME/Pictures/Wallpaper"

echo "==> Stowing desktop..."
# --adopt puxa pro repo qualquer arquivo real que ja exista no destino; o
# git restore em seguida joga fora essa adocao e reafirma a versao do repo,
# deixando so o symlink. O || true cobre a primeira vez, quando os pacotes ainda
# nao foram commitados e nao ha o que restaurar.
stow --adopt -R hypr noctalia desktop
git restore -- hypr noctalia desktop 2>/dev/null || true

echo
echo "Done. Recarregue a config com: hyprctl reload && noctalia msg config-reload"
