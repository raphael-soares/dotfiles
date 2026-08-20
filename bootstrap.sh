#!/usr/bin/env bash
# Linka os dotfiles com o stow. Nao instala nada: instalar as dependencias
# e responsabilidade de quem roda, no gerenciador de pacotes dele.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

STOW_PKGS=(bash tmux alacritty git starship fzf local mise nvim ai)

cat <<'EOF'
Dependencias (instale pelo gerenciador de pacotes do seu sistema):

  stow git tmux nvim fzf starship mise alacritty
  jq curl gh openfortivpn

Fonte JetBrainsMono Nerd para o alacritty, fzf 0.48 ou maior,
e os locales en_US.UTF-8 e pt_BR.UTF-8 gerados.

TPM, para os plugins do tmux:
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

Chave de API vai em ~/.env.local (veja o .env.example).

EOF

if ! command -v stow >/dev/null || ! command -v git >/dev/null; then
  echo "Precisa de stow e git para rodar este script." >&2
  exit 1
fi

echo "==> Linkando com o stow"
# --adopt puxa para o repo o arquivo que ja existia no sistema; o restore logo
# depois descarta esse conteudo e faz valer o do repo. Restrito aos pacotes
# stowados: `git restore .` apagaria tambem mudanca sua ainda nao commitada.
stow --adopt -R "${STOW_PKGS[@]}"
git restore -- "${STOW_PKGS[@]}"

echo
echo "Pronto. No tmux, aperte prefix + I para instalar os plugins."
