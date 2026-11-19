#!/usr/bin/env bash
set -euo pipefail

[[ ${DOTFILES_LINKS_ONLY:-} == 1 ]] && exit 0

REPO={{dotter.current_dir}}
DISTRO=$(. /etc/os-release && echo "$ID")
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
mkdir -p "$STATE"

install_packages() {
  local list="$REPO/$1/packages.$DISTRO.txt" missing p
  [[ -f $list ]] || return 0
  case $DISTRO in
    arch)
      missing=$(pacman -T $(<"$list") || true)
      [[ -n $missing ]] || return 0
      echo "==> Installing: $(echo $missing)"
      if command -v yay >/dev/null; then
        yay -S --needed $missing
      else
        sudo pacman -S --needed $missing
      fi
      ;;
    fedora)
      missing=()
      for p in $(<"$list"); do rpm -q "$p" >/dev/null 2>&1 || missing+=("$p"); done
      ((${#missing[@]})) || return 0
      echo "==> Installing: ${missing[*]}"
      sudo dnf install -y "${missing[@]}"
      ;;
    *)
      echo "==> $DISTRO is not supported, install by hand: $(echo $(<"$list"))"
      ;;
  esac
}

warn_missing() {
  local missing=() cmd
  for cmd in "$@"; do command -v "$cmd" >/dev/null || missing+=("$cmd"); done
  ((${#missing[@]} == 0)) || echo "==> Still to install with each one's own installer: ${missing[*]}"
}

# A file in /etc is copied, never linked: its owner has to be root. Exits 1
# when nothing changed, so the caller can decide whether to reload the service.
copy_etc() {
  cmp -s "$REPO/$1" "$2" && return 1
  echo "==> $2"
  sudo install -Dm644 "$REPO/$1" "$2"
}

{{#if dotter.packages.terminal}}
install_packages terminal
warn_missing starship mise ghostty
if [[ ! -f $HOME/.env.local ]]; then
  cp "$REPO/.env.example" "$HOME/.env.local"
  echo "==> ~/.env.local created from .env.example, fill in the keys"
fi
herdr_setup=$HOME/Code/Personal/herdr-setup
[[ -d $herdr_setup ]] || git clone https://github.com/raphael-soares/herdr-setup "$herdr_setup"
"$herdr_setup/install.sh"
{{/if}}

{{#if dotter.packages.ai}}
install_packages ai
warn_missing omp claude rtk
if command -v omp >/dev/null; then
  omp plugin install github:obra/superpowers#v7.0.2
fi
{{/if}}

{{#if dotter.packages.desktop}}
install_packages desktop
if copy_etc desktop/audio/91-fuxi-h3-mixer.rules /etc/udev/rules.d/91-fuxi-h3-mixer.rules; then
  sudo udevadm control --reload
fi
rules=$(cat "$REPO"/desktop/audio/wireplumber/* | sha256sum)
if [[ $(cat "$STATE/wireplumber" 2>/dev/null) != "$rules" ]] && command -v systemctl >/dev/null; then
  if systemctl --user restart wireplumber; then
    echo "$rules" >"$STATE/wireplumber"
    echo "==> WirePlumber restarted; reconnect Bluetooth to renegotiate A2DP"
  fi
fi
if [[ $DISTRO == fedora ]] && ! fc-list | grep -qi 'JetBrainsMono Nerd'; then
  echo "==> Install JetBrainsMono Nerd Font by hand (it is not in dnf)"
fi
{{/if}}

{{#if dotter.packages.hyprland}}
install_packages hyprland
copy_etc hyprland/greetd/config.toml /etc/greetd/config.toml || true
copy_etc hyprland/greetd/pam /etc/pam.d/greetd || true
# libadwaita apps read font and icons from dconf, not from settings.ini.
gsettings set org.gnome.desktop.interface font-name 'Sans 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 10'
gsettings set org.gnome.desktop.interface icon-theme 'Yaru-olive-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.wm.preferences button-layout ':'
systemctl --user enable --now gcr-ssh-agent.socket
# The "default" theme is what XCursor uses when the app asks for none.
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nInherits=Adwaita\n' >"$HOME/.icons/default/index.theme"
# Flatpak does not read the host settings.ini for icon and cursor.
if command -v flatpak >/dev/null; then
  flatpak override --user --env=ICON_THEME=Papirus-Dark --env=XCURSOR_THEME=Adwaita
fi
# Swapping the ~/.config/hypr link while Hyprland is running drops it into emergency mode.
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null && { noctalia msg config-reload || true; }
  hyprctl configerrors
fi
{{/if}}

{{#if dotter.packages.home}}
install_packages home
if ! rpm -q Sunshine >/dev/null 2>&1; then
  sudo dnf copr enable -y lizardbyte/stable
  sudo dnf install -y Sunshine
fi
# Key-only login without an authorized key would lock the laptop out.
if [[ -s $HOME/.ssh/authorized_keys ]]; then
  if copy_etc home/ssh/50-key-only.conf /etc/ssh/sshd_config.d/50-key-only.conf; then
    sudo systemctl reload sshd 2>/dev/null || true
  fi
else
  echo "==> Authorize the laptop key in ~/.ssh/authorized_keys, then deploy again (sshd_config.d left as is)"
fi
copy_etc home/sddm/autologin.conf /etc/sddm.conf.d/autologin.conf || true
sudo systemctl enable --now sshd avahi-daemon
# KMS capture needs cap_sys_admin, and a package update drops it with the old binary.
sunshine=$(readlink -f "$(command -v sunshine)")
capped=0
if ! getcap "$sunshine" | grep -q cap_sys_admin; then
  sudo setcap cap_sys_admin+p "$sunshine"
  capped=1
fi
unit_found=0
for unit in app-dev.lizardbyte.app.Sunshine.service sunshine.service; do
  if systemctl --user cat "$unit" >/dev/null 2>&1; then
    systemctl --user enable --now "$unit"
    ((capped)) && systemctl --user restart "$unit"
    unit_found=1
    break
  fi
done
((unit_found)) || echo "==> No Sunshine user unit found; start it by hand and check its unit name"
sudo firewall-cmd -q --permanent --add-service=ssh --add-service=mdns \
  --add-port=47984-47990/tcp --add-port=48010/tcp --add-port=47998-48000/udp
sudo firewall-cmd -q --reload
# Never sleep or blank on AC; the screen lock stays as it is.
kwriteconfig6 --file powerdevilrc --group AC --group SuspendAndShutdown --key AutoSuspendAction 0
kwriteconfig6 --file powerdevilrc --group AC --group Display --key TurnOffDisplayWhenIdle false
kwriteconfig6 --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle false
systemctl --user restart plasma-powerdevil 2>/dev/null || true
{{/if}}

{{#if dotter.packages.work}}
install_packages work
# Enterprise omp profile: its own auth (agent.db), the rest shared with the default one.
profile=$HOME/.omp/profiles/enterprise/agent
mkdir -p "$profile"
for item in AGENTS.md RULES.md config.yml keybindings.yml lsp.json skills prompts rules extensions themes; do
  ln -sfn "$REPO/ai/.omp/agent/$item" "$profile/$item"
done
if command -v omp >/dev/null; then
  OMP_PROFILE=enterprise omp plugin install github:obra/superpowers#v7.0.2
fi
{{/if}}
