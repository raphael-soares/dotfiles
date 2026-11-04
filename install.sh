#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
REPO=$PWD
DISTRO=$(. /etc/os-release && echo "$ID")

GRUPOS=(terminal ai desktop hyprland audio sistema vpn raphael)
declare -A DESCRICAO=(
  [terminal]="bash, tmux, alacritty, git, starship, fzf, mise, nvim, workmux"
  [ai]="AGENTS.md, skills, omp e Claude Code"
  [desktop]="tema GTK, fontes e webapps (qualquer desktop)"
  [hyprland]="Hyprland, Noctalia e portal (so Arch)"
  [audio]="WirePlumber so com A2DP no Bluetooth (sem microfone em fone BT)"
  [sistema]="/etc: greetd, PAM do greetd, plymouth e zram (copia com sudo); thermald e fwupd (so Arch)"
  [vpn]="~/.local/bin/vpn, VPN Fortinet SSL pelo NetworkManager"
  [raphael]="so do Raphael: TMUX_SESSIONIZER_DIRS, ompe, syncfast, atalho do Alacritty"
)
declare -A SO_ARCH=([hyprland]=1 [sistema]=1)

usage() {
  echo "Uso: ./install.sh [--adopt] [--sem-pacotes] [grupo...]"
  echo
  echo "Sem grupo, pergunta um por um. Grupos:"
  for g in "${GRUPOS[@]}"; do printf '  %-9s %s\n' "$g" "${DESCRICAO[$g]}"; done
  cat <<'EOF'

--adopt        puxa para o repo o arquivo real que ja existir no home e depois
               descarta essa copia com git restore, deixando so o symlink
--sem-pacotes  nao instala pacote, so linka os arquivos
EOF
}

perguntar_grupos() {
  local g resp
  for g in "${GRUPOS[@]}"; do
    read -r -p "$g (${DESCRICAO[$g]})? [s/N] " resp
    [[ $resp == [sS]* ]] && grupos+=("$g")
  done
  return 0
}

adopt=0
pacotes=1
grupos=()
for arg in "$@"; do
  case "$arg" in
    --adopt) adopt=1 ;;
    --sem-pacotes) pacotes=0 ;;
    -h|--help) usage; exit 0 ;;
    *)
      [[ -v "DESCRICAO[$arg]" ]] || { echo "install.sh: grupo desconhecido: $arg" >&2; usage >&2; exit 1; }
      grupos+=("$arg")
      ;;
  esac
done
if [[ ${#grupos[@]} -eq 0 ]]; then
  [[ -t 0 ]] || { usage >&2; exit 1; }
  perguntar_grupos
  [[ ${#grupos[@]} -gt 0 ]] || { echo "Nada escolhido."; exit 0; }
fi

command -v stow >/dev/null && command -v git >/dev/null \
  || { echo "install.sh: precisa de stow e git" >&2; exit 1; }

instalar_pacotes() {
  local lista="$REPO/packages/$1.$DISTRO.txt" faltando p
  [[ $pacotes -eq 1 && -f "$lista" ]] || return 0
  case "$DISTRO" in
    arch)
      faltando=$(pacman -T $(<"$lista") || true)
      [[ -n "$faltando" ]] || return 0
      echo "==> Instalando: $(echo $faltando)"
      if command -v yay >/dev/null; then
        yay -S --needed $faltando
      else
        sudo pacman -S --needed $faltando
      fi
      ;;
    fedora)
      faltando=()
      for p in $(<"$lista"); do rpm -q "$p" >/dev/null 2>&1 || faltando+=("$p"); done
      [[ ${#faltando[@]} -gt 0 ]] || return 0
      echo "==> Instalando: ${faltando[*]}"
      sudo dnf install -y "${faltando[@]}"
      ;;
    *)
      echo "==> $DISTRO sem suporte, instale a mao: $(echo $(<"$lista"))"
      ;;
  esac
}

avisar_sem_pacote() {
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

grupo_terminal() {
  instalar_pacotes terminal
  avisar_sem_pacote starship mise workmux
  linkar .config/tmux .config/workmux .config/mise .config/git \
    -- bash tmux alacritty git starship fzf mise nvim workmux
  if [[ ! -f "$HOME/.env.local" ]]; then
    cp .env.example "$HOME/.env.local"
    echo "==> ~/.env.local criado a partir do .env.example, preencha as chaves"
  fi
}

grupo_ai() {
  instalar_pacotes ai
  avisar_sem_pacote omp claude rtk
  linkar .claude .omp/agent/extensions .omp/agent/rules .local/bin -- ai
  # Perfil do omp com auth propria (agent.db) e o resto compartilhado com o default.
  local perfil="$HOME/.omp/profiles/enterprise/agent" item
  mkdir -p "$perfil"
  for item in AGENTS.md RULES.md config.yml keybindings.yml lsp.json skills rules extensions themes; do
    ln -sfn "$REPO/ai/.omp/agent/$item" "$perfil/$item"
  done
}

grupo_desktop() {
  instalar_pacotes desktop
  linkar .config/gtk-3.0 .config/gtk-4.0 .config/fontconfig/conf.d \
    .local/share/applications .local/share/icons/hicolor/scalable/apps \
    -- gtk fontes webapps
  if [[ $DISTRO == fedora ]] && ! fc-list | grep -qi 'JetBrainsMono Nerd'; then
    echo "==> Instale a JetBrainsMono Nerd Font a mao (nao esta no dnf)"
  fi
}

grupo_hyprland() {
  instalar_pacotes hyprland
  linkar .config/hypr .config/noctalia-plugins .config/xdg-desktop-portal .local/state/noctalia Pictures/Wallpaper \
    -- hypr noctalia
  # Apps libadwaita leem fonte e icones do dconf, nao do settings.ini.
  gsettings set org.gnome.desktop.interface font-name 'Sans 10'
  gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 10'
  gsettings set org.gnome.desktop.interface icon-theme 'Yaru-olive-dark'
  gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
  gsettings set org.gnome.desktop.wm.preferences button-layout ':'
  systemctl --user enable --now gcr-ssh-agent.socket
  # O tema "default" é o que o XCursor usa quando o app não pede nenhum.
  mkdir -p "$HOME/.icons/default"
  printf '[Icon Theme]\nInherits=Adwaita\n' >"$HOME/.icons/default/index.theme"
  # Flatpak não lê o settings.ini do host para ícone e cursor.
  command -v flatpak >/dev/null &&
    flatpak override --user --env=ICON_THEME=Papirus-Dark --env=XCURSOR_THEME=Adwaita
  echo "==> Para aplicar: hyprctl reload && noctalia msg config-reload"
}

grupo_audio() {
  local conf="$HOME/.config/wireplumber/wireplumber.conf.d/53-bluetooth-a2dp-only.conf" novo=0
  instalar_pacotes audio
  [[ -L "$conf" ]] || novo=1
  linkar .config/wireplumber/wireplumber.conf.d -- audio
  if [[ $novo -eq 1 ]] && command -v systemctl >/dev/null; then
    systemctl --user restart wireplumber
    echo "==> WirePlumber reiniciado; reconecte o Bluetooth para renegociar em A2DP"
  fi
}

grupo_sistema() {
  local src dst
  instalar_pacotes sistema
  while IFS= read -r src; do
    dst=/${src#sistema/}
    cmp -s "$src" "$dst" && continue
    echo "==> $dst"
    sudo install -Dm644 "$src" "$dst"
    if [[ $dst == /etc/plymouth/* ]]; then echo "    regere o initramfs para o plymouth pegar a mudanca"; fi
  done < <(find sistema -type f | sort)
  sudo systemctl enable --now thermald.service
  echo "==> zram: reinicie (ou sudo systemctl daemon-reload && sudo systemctl start systemd-zram-setup@zram0)"
}

grupo_vpn() {
  instalar_pacotes vpn
  linkar .local/bin -- vpn
}

grupo_raphael() {
  linkar .config/shell/rc.d .config/syncfast .local/share/applications -- raphael
}

for grupo in "${grupos[@]}"; do
  if [[ -v "SO_ARCH[$grupo]" && $DISTRO != arch ]]; then
    echo "install.sh: $grupo é só para Arch, pulando" >&2
    continue
  fi
  echo "== $grupo"
  "grupo_$grupo"
done
