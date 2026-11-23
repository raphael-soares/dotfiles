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

# Bloat the Fedora KDE installer brings and nothing here uses. Runs after
# install_packages so the fonts and langpacks it would drag out are back in
# place first.
remove_packages() {
  local list="$REPO/$1/remove.$DISTRO.txt" present=() p
  [[ -f $list ]] || return 0
  [[ $DISTRO == fedora ]] || return 0
  for p in $(<"$list"); do rpm -q "$p" >/dev/null 2>&1 && present+=("$p"); done
  ((${#present[@]})) || return 0
  echo "==> Removing: ${present[*]}"
  sudo dnf remove -y "${present[@]}"
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
warn_missing starship mise ghostty rbw direnv
if rbw unlocked 2>/dev/null || [[ -t 0 ]]; then
  "$REPO/terminal/bin/secrets" pull || echo "==> secrets: run 'secrets setup' then 'secrets pull'"
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
if command -v claude >/dev/null && ! claude mcp get bitwarden >/dev/null 2>&1; then
  claude mcp add -s user bitwarden -e BW_CLI_PATH="$HOME/.local/share/mise/shims/bw" \
    -- npx -y @bitwarden/mcp-server@2026.7.0
fi
{{/if}}

{{#if dotter.packages.desktop}}
install_packages desktop
remove_packages desktop
# Spotifast and ZapFast have no dnf repo (on Arch they come from the AUR list):
# install the latest release rpm straight from GitHub.
if [[ $DISTRO == fedora ]]; then
  for app in spotifast zapfast; do
    rpm -q "$app" >/dev/null 2>&1 && continue
    url=$(curl -fsSL "https://api.github.com/repos/crmne/$app/releases/latest" |
      jq -r '.assets[].browser_download_url | select(endswith(".x86_64.rpm"))')
    echo "==> Installing $app from $url"
    sudo dnf install -y "$url"
  done
fi
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
# grep -q closes the pipe early and, under pipefail, fc-list dying of SIGPIPE
# would report the font as missing.
if [[ $DISTRO == fedora ]] && ! fc-list | grep -i 'JetBrainsMono Nerd' >/dev/null; then
  echo "==> Install JetBrainsMono Nerd Font by hand (it is not in dnf)"
fi
{{/if}}

{{#if dotter.packages.hyprland}}
if [[ $DISTRO == fedora ]]; then
  coprs=$(dnf copr list 2>/dev/null)
  for copr in lionheartp/Hyprland nett00n/hyprland; do
    grep -q "/$copr$" <<<"$coprs" || sudo dnf copr enable -y "$copr"
  done
  # nett00n's hyprland sorts above lionheartp's build, which is the one tracked here.
  sudo dnf config-manager setopt copr:copr.fedorainfracloud.org:nett00n:hyprland.includepkgs=satty
fi
install_packages hyprland
if [[ $DISTRO == fedora ]] && ! flatpak info io.missioncenter.MissionCenter >/dev/null 2>&1; then
  flatpak install --user -y --noninteractive flathub io.missioncenter.MissionCenter
fi
# Fedora's hyprland pulls in uwsm, whose %post starts its failed-unit notifier in every
# graphical session, Plasma included. Neither session here runs under uwsm.
if systemctl --user cat fumon.service >/dev/null 2>&1; then
  systemctl --user mask --now fumon.service
fi
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

{{#if dotter.packages.laptop}}
install_packages laptop
copy_etc laptop/greetd/config.toml /etc/greetd/config.toml || true
copy_etc laptop/greetd/pam /etc/pam.d/greetd || true
{{/if}}

{{#if dotter.packages.sshd}}
install_packages sshd
# Without an authorized key sshd would take passwords on any network the laptop joins.
if [[ -s $HOME/.ssh/authorized_keys ]]; then
  if copy_etc sshd/50-key-only.conf /etc/ssh/sshd_config.d/50-key-only.conf; then
    sudo systemctl reload sshd 2>/dev/null || true
  fi
  sudo systemctl enable --now sshd
else
  echo "==> sshd left off: add ~/.ssh/keys/personal.pub to ~/.ssh/authorized_keys, then deploy again"
fi
sudo systemctl enable --now avahi-daemon
if command -v firewall-cmd >/dev/null; then
  sudo firewall-cmd -q --permanent --add-service=ssh --add-service=mdns
  sudo firewall-cmd -q --reload
fi
{{/if}}

{{#if dotter.packages.home}}
if ! rpm -q Sunshine >/dev/null 2>&1; then
  sudo dnf copr enable -y lizardbyte/stable
  sudo dnf install -y Sunshine
fi
install_packages home
# Sunshine needs a session after an unattended boot. Plasma stays in the greeter until it is removed.
copy_etc home/greetd/config.toml /etc/greetd/config.toml || true
if [[ $(systemctl is-enabled greetd.service 2>/dev/null) != enabled ]]; then
  sudo systemctl disable plasmalogin.service
  sudo systemctl enable greetd.service
  echo "==> Reboot to log in through greetd"
fi
# The KDE apps still hold these until Plasma is removed.
xdg-mime default org.gnome.Nautilus.desktop inode/directory
xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp \
  image/avif image/heif image/tiff image/bmp image/svg+xml
xdg-mime default org.gnome.Papers.desktop application/pdf
xdg-mime default org.gnome.Showtime.desktop video/mp4 video/x-matroska video/webm \
  video/quicktime video/x-msvideo video/mpeg
xdg-mime default org.gnome.TextEditor.desktop text/plain
# Fedora 44 replaced SDDM with Plasma Login Manager, which reads the same keys from its own dir.
copy_etc home/plasmalogin/autologin.conf /etc/plasmalogin.conf.d/autologin.conf || true
# kded's gtkconfig rewrites settings.ini on every Plasma login, and here it links into the repo.
kwriteconfig6 --file kded5rc --group Module-gtkconfig --key autoload false
# The monitor shows the laptop most of the time and then stops answering on DP-1,
# leaving Plasma without a screen and Sunshine with nothing to stream. The kernel
# replays the LG's own EDID there (amdgpu loads from the initramfs, hence dracut).
edid_changed=0
copy_etc home/edid/lg-ultragear.bin /usr/lib/firmware/edid/lg-ultragear.bin && edid_changed=1
copy_etc home/dracut/edid.conf /etc/dracut.conf.d/edid.conf && edid_changed=1
if ((edid_changed)); then sudo dracut -f --regenerate-all; fi
if ! sudo grubby --info=ALL | grep -q 'drm.edid_firmware=DP-1'; then
  sudo grubby --update-kernel=ALL --args="drm.edid_firmware=DP-1:edid/lg-ultragear.bin video=DP-1:e"
  echo "==> Reboot for the DP-1 EDID override"
fi
# Portal capture waits on a permission dialog nobody sees after an unattended boot.
sunshine_conf=$HOME/.config/sunshine/sunshine.conf
mkdir -p "${sunshine_conf%/*}"
grep -qx 'capture = kms' "$sunshine_conf" 2>/dev/null || echo 'capture = kms' >>"$sunshine_conf"
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
sudo firewall-cmd -q --permanent \
  --add-port=47984-47990/tcp --add-port=48010/tcp --add-port=47998-48000/udp
sudo firewall-cmd -q --reload
# Never sleep or blank on AC; the screen lock stays as it is.
kwriteconfig6 --file powerdevilrc --group AC --group SuspendAndShutdown --key AutoSuspendAction 0
kwriteconfig6 --file powerdevilrc --group AC --group Display --key TurnOffDisplayWhenIdle false
kwriteconfig6 --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle false
systemctl --user restart plasma-powerdevil 2>/dev/null || true
if ! rpm -q kwin-effect-roundcorners >/dev/null 2>&1; then
  sudo dnf copr enable -y matinlotfali/KDE-Rounded-Corners
  sudo dnf install -y kwin-effect-roundcorners
fi
# Inactive windows get the Plasma panel's border (1 px white, radius 6); the focused one a
# stronger line (~30% white, Hyprland uses 25% plus a shadow KDE lacks here). Alpha is not
# linear: 100 gives the panel's color, 0 hides the border and 28 nearly does.
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
for kv in Size=6 InactiveCornerRadius=6 UseSquircleShape=false \
  OutlineThickness=1 InactiveOutlineThickness=1 \
  OutlineColor=255,255,255 InactiveOutlineColor=255,255,255 \
  ActiveOutlineAlpha=150 InactiveOutlineAlpha=100 \
  ActiveOutlineUsePalette=false InactiveOutlineUsePalette=false; do
  kwriteconfig6 --file kwinrc --group Round-Corners --key "${kv%%=*}" "${kv#*=}"
done
# Hyprland dim_inactive with dim_strength 0.08.
kwriteconfig6 --file kwinrc --group Plugins --key diminactiveEnabled true
kwriteconfig6 --file kwinrc --group Effect-diminactive --key Strength 8
# Meta+hjkl at the screen edge must stop there, not jump to the next desktop.
kwriteconfig6 --file kwinrc --group Script-krohnkite --key focusMoveVDesktopsNormal false
kwriteconfig6 --file kwinrc --group Script-krohnkite --key focusMoveVDesktopsMeta false
# KWin's own reconfigure leaves this effect on its old settings.
gdbus call --session --dest org.kde.KWin --object-path /Effects \
  --method org.kde.kwin.Effects.reconfigureEffect kwin4_effect_shapecorners >/dev/null 2>&1 || true
# Animations follow hyprland/hypr/animations.lua. Factor 1 keeps the durations below in real ms.
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 1
# windowsIn/Out "popin 90%": scale replaces fade for opening and closing windows.
kwriteconfig6 --file kwinrc --group Plugins --key scaleEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key fadeEnabled false
kwriteconfig6 --file kwinrc --group Effect-scale --key Duration 200
kwriteconfig6 --file kwinrc --group Effect-scale --key InScale 0.9
kwriteconfig6 --file kwinrc --group Effect-scale --key OutScale 0.9
kwriteconfig6 --file kwinrc --group Plugins --key fadedesktopEnabled true
kwriteconfig6 --file kwinrc --group Plugins --key slideEnabled false
kwriteconfig6 --file kwinrc --group Effect-fadedesktop --key AnimationDuration 120
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_geometry_changeEnabled true
kwriteconfig6 --file kwinrc --group Effect-kwin4_effect_geometry_change --key Duration 180
# Solid desktop: no blur or background contrast behind the panel and popups.
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled false
kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel 2" --key panelOpacity 1
# Kickoff opens anchored to its icon; this script (vendored from
# github.com/terminallywell/center-widget-popups) moves it to the screen's horizontal center.
kwriteconfig6 --file kwinrc --group Plugins --key center-widget-popupsEnabled true
gdbus call --session --dest org.kde.KWin --object-path /KWin --method org.kde.KWin.reconfigure >/dev/null 2>&1 || true
for effect in scale fadedesktop kwin4_effect_geometry_change; do
  gdbus call --session --dest org.kde.KWin --object-path /Effects \
    --method org.kde.kwin.Effects.reconfigureEffect "$effect" >/dev/null 2>&1 || true
done
{{/if}}

{{#if dotter.packages.media}}
install_packages media
"$REPO/media/bin/media-deploy" "$REPO"
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
