#!/usr/bin/env bash
set -euo pipefail

[[ ${DOTFILES_SO_LINKS:-} == 1 ]] && exit 0

REPO={{dotter.current_dir}}
DISTRO=$(. /etc/os-release && echo "$ID")
ESTADO=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
mkdir -p "$ESTADO"

instalar_pacotes() {
  local lista="$REPO/$1/pacotes.$DISTRO.txt" faltando p
  [[ -f $lista ]] || return 0
  case $DISTRO in
    arch)
      faltando=$(pacman -T $(<"$lista") || true)
      [[ -n $faltando ]] || return 0
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
      ((${#faltando[@]})) || return 0
      echo "==> Instalando: ${faltando[*]}"
      sudo dnf install -y "${faltando[@]}"
      ;;
    *)
      echo "==> $DISTRO sem suporte, instale a mão: $(echo $(<"$lista"))"
      ;;
  esac
}

avisar_sem_pacote() {
  local falta=() cmd
  for cmd in "$@"; do command -v "$cmd" >/dev/null || falta+=("$cmd"); done
  ((${#falta[@]} == 0)) || echo "==> Falta instalar pelo instalador de cada um: ${falta[*]}"
}

# Arquivo de /etc é copiado, nunca linkado: o dono tem que ser root. Sai com 1
# quando nada mudou, para quem chama decidir se recarrega o serviço.
copiar_etc() {
  cmp -s "$REPO/$1" "$2" && return 1
  echo "==> $2"
  sudo install -Dm644 "$REPO/$1" "$2"
}

{{#if dotter.packages.terminal}}
instalar_pacotes terminal
avisar_sem_pacote starship mise ghostty
if [[ ! -f $HOME/.env.local ]]; then
  cp "$REPO/.env.example" "$HOME/.env.local"
  echo "==> ~/.env.local criado a partir do .env.example, preencha as chaves"
fi
herdr_setup=$HOME/Code/Personal/herdr-setup
[[ -d $herdr_setup ]] || git clone https://github.com/raphael-soares/herdr-setup "$herdr_setup"
"$herdr_setup/install.sh"
{{/if}}

{{#if dotter.packages.ai}}
instalar_pacotes ai
avisar_sem_pacote omp claude rtk
if command -v omp >/dev/null; then
  omp plugin install github:obra/superpowers#v7.0.2
fi
{{/if}}

{{#if dotter.packages.desktop}}
instalar_pacotes desktop
if copiar_etc desktop/audio/91-fuxi-h3-mixer.rules /etc/udev/rules.d/91-fuxi-h3-mixer.rules; then
  sudo udevadm control --reload
fi
regras=$(cat "$REPO"/desktop/audio/wireplumber/* | sha256sum)
if [[ $(cat "$ESTADO/wireplumber" 2>/dev/null) != "$regras" ]] && command -v systemctl >/dev/null; then
  if systemctl --user restart wireplumber; then
    echo "$regras" >"$ESTADO/wireplumber"
    echo "==> WirePlumber reiniciado; reconecte o Bluetooth para renegociar em A2DP"
  fi
fi
if [[ $DISTRO == fedora ]] && ! fc-list | grep -qi 'JetBrainsMono Nerd'; then
  echo "==> Instale a JetBrainsMono Nerd Font a mão (não está no dnf)"
fi
{{/if}}

{{#if dotter.packages.hyprland}}
instalar_pacotes hyprland
copiar_etc hyprland/greetd/config.toml /etc/greetd/config.toml || true
copiar_etc hyprland/greetd/pam /etc/pam.d/greetd || true
# Apps libadwaita leem fonte e ícones do dconf, não do settings.ini.
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
if command -v flatpak >/dev/null; then
  flatpak override --user --env=ICON_THEME=Papirus-Dark --env=XCURSOR_THEME=Adwaita
fi
# Trocar o link de ~/.config/hypr com o Hyprland aberto o deixa em modo de emergência.
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null && { noctalia msg config-reload || true; }
  hyprctl configerrors
fi
{{/if}}

{{#if dotter.packages.trabalho}}
instalar_pacotes trabalho
# Perfil enterprise do omp: auth própria (agent.db), o resto compartilhado com o padrão.
perfil=$HOME/.omp/profiles/enterprise/agent
mkdir -p "$perfil"
for item in AGENTS.md RULES.md config.yml keybindings.yml lsp.json skills prompts rules extensions themes; do
  ln -sfn "$REPO/ai/.omp/agent/$item" "$perfil/$item"
done
if command -v omp >/dev/null; then
  OMP_PROFILE=enterprise omp plugin install github:obra/superpowers#v7.0.2
fi
{{/if}}
