#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
REPO=$PWD

usage() {
  cat <<'EOF'
Uso: ./install.sh [--adopt] [--sem-pacotes] <camada>...

Camadas:
  terminal  bash, tmux, nvim, git, fzf, starship, mise, alacritty, workmux, ~/.local/bin
  ai        AGENTS.md, skills, omp e Claude Code
  desktop   Hyprland, Noctalia e o tema GTK/portal
  audio     WirePlumber so com A2DP no Bluetooth (sem microfone em fone BT)
  sistema   /etc: greetd, PAM do greetd e plymouth (copia com sudo)

--adopt        puxa para o repo o arquivo real que ja existir no home e depois
               descarta essa copia com git restore, deixando so o symlink
--sem-pacotes  nao instala pacote, so linka os arquivos
EOF
}

adopt=0
pacotes=1
camadas=()
for arg in "$@"; do
  case "$arg" in
    --adopt) adopt=1 ;;
    --sem-pacotes) pacotes=0 ;;
    -h|--help) usage; exit 0 ;;
    terminal|ai|desktop|audio|sistema) camadas+=("$arg") ;;
    *) echo "install.sh: camada desconhecida: $arg" >&2; usage >&2; exit 1 ;;
  esac
done
[[ ${#camadas[@]} -gt 0 ]] || { usage >&2; exit 1; }

command -v stow >/dev/null && command -v git >/dev/null \
  || { echo "install.sh: precisa de stow e git" >&2; exit 1; }

instalar_pacotes() {
  local lista="$REPO/packages/$1.txt" faltando
  [[ $pacotes -eq 1 && -f "$lista" ]] || return 0
  command -v pacman >/dev/null || { echo "==> sem pacman, pule ou instale a mao: $lista"; return 0; }
  faltando=$(pacman -T $(<"$lista") || true)
  [[ -n "$faltando" ]] || return 0
  echo "==> Instalando: $(echo $faltando)"
  if command -v yay >/dev/null; then
    yay -S --needed $faltando
  else
    sudo pacman -S --needed $faltando
  fi
}

avisar_fora_do_pacman() {
  local falta=()
  for cmd in "$@"; do command -v "$cmd" >/dev/null || falta+=("$cmd"); done
  [[ ${#falta[@]} -eq 0 ]] || echo "==> Falta instalar pelo instalador de cada um: ${falta[*]}"
}

# Diretorio onde o app escreve tem que existir antes do stow: senao ele vira um
# symlink para dentro do repo e o estado do app passa a sujar o git.
linkar() {
  local dirs=() pkgs=()
  while [[ $1 != -- ]]; do dirs+=("$HOME/$1"); shift; done
  shift
  pkgs=("$@")
  [[ ${#dirs[@]} -eq 0 ]] || mkdir -p "${dirs[@]}"
  if [[ $adopt -eq 1 ]]; then
    stow -t "$HOME" --adopt -R "${pkgs[@]}"
    git restore -- "${pkgs[@]}"
  else
    stow -t "$HOME" -R "${pkgs[@]}"
  fi
}

camada_terminal() {
  instalar_pacotes terminal
  avisar_fora_do_pacman starship mise workmux
  linkar .config/tmux .config/workmux .config/mise .config/git .local/bin .local/share/applications \
    -- bash tmux alacritty git starship fzf local mise nvim workmux
  if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
  fi
  if [[ ! -f "$HOME/.env.local" ]]; then
    cp .env.example "$HOME/.env.local"
    echo "==> ~/.env.local criado a partir do .env.example, preencha as chaves"
  fi
}

camada_ai() {
  instalar_pacotes ai
  avisar_fora_do_pacman omp claude rtk
  linkar .claude .omp/agent/extensions .omp/agent/rules .config/rtk -- ai
}

camada_desktop() {
  instalar_pacotes desktop
  linkar .config/hypr .config/noctalia-plugins .config/gtk-3.0 .config/gtk-4.0 \
    .config/xdg-desktop-portal .local/state/noctalia Pictures/Wallpaper \
    -- hypr noctalia desktop
  echo "==> Para aplicar: hyprctl reload && noctalia msg config-reload"
}

camada_audio() {
  local conf="$HOME/.config/wireplumber/wireplumber.conf.d/53-bluetooth-a2dp-only.conf" novo=0
  instalar_pacotes audio
  [[ -L "$conf" ]] || novo=1
  linkar .config/wireplumber/wireplumber.conf.d -- audio
  if [[ $novo -eq 1 ]] && command -v systemctl >/dev/null; then
    systemctl --user restart wireplumber
    echo "==> WirePlumber reiniciado; reconecte o Bluetooth para renegociar em A2DP"
  fi
}

camada_sistema() {
  local src dst
  instalar_pacotes sistema
  while IFS= read -r src; do
    dst=/${src#sistema/}
    cmp -s "$src" "$dst" && continue
    echo "==> $dst"
    sudo install -Dm644 "$src" "$dst"
    if [[ $dst == /etc/plymouth/* ]]; then echo "    regere o initramfs para o plymouth pegar a mudanca"; fi
  done < <(find sistema -type f | sort)
}

for camada in "${camadas[@]}"; do
  echo "== $camada"
  "camada_$camada"
done
