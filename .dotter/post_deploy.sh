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

# Packages a Fedora install brings and nothing here uses. Runs after
# install_packages so the fonts and langpacks it would drag out are back in
# place first. Arguments after the module go to dnf.
remove_packages() {
  local list="$REPO/$1/remove.$DISTRO.txt" present=() p
  shift
  [[ -f $list ]] || return 0
  [[ $DISTRO == fedora ]] || return 0
  for p in $(<"$list"); do rpm -q "$p" >/dev/null 2>&1 && present+=("$p"); done
  ((${#present[@]})) || return 0
  echo "==> Removing: ${present[*]}"
  sudo dnf remove -y "$@" "${present[@]}"
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

# copy_etc for a file with placeholders: the sed script fills them in first.
copy_etc_rendered() {
  local rendered status=0
  rendered=$(mktemp)
  sed "$3" "$REPO/$1" >"$rendered"
  if cmp -s "$rendered" "$2"; then
    status=1
  else
    echo "==> $2"
    sudo install -Dm644 "$rendered" "$2" || status=2
  fi
  rm -f "$rendered"
  return "$status"
}

{{#if dotter.packages.terminal}}
install_packages terminal
warn_missing starship mise ghostty rbw direnv
# Noctalia's Ghostty template rewrites the theme line of ~/.config/ghostty/config,
# so that file is a real one that only includes the repo's files. Ghostty resolves
# an include from the linked file's real path, so machine.conf is included here.
ghostty_config=$HOME/.config/ghostty/config
if [[ -L $ghostty_config || ! -e $ghostty_config ]]; then
  rm -f "$ghostty_config"
  printf 'config-file = base\nconfig-file = ?machine.conf\n' >"$ghostty_config"
fi
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
  grep -q "/lizardbyte/stable$" <<<"$coprs" || sudo dnf copr enable -y lizardbyte/stable
fi
install_packages hyprland
# Sunshine runs from boot as a system unit, so the other machine reaches the login
# screen. Portal capture would wait on a permission dialog nobody sees there.
sunshine_conf=$HOME/.config/sunshine/sunshine.conf
sunshine_changed=0
mkdir -p "${sunshine_conf%/*}"
for line in 'capture = kms' 'system_tray = disabled'; do
  grep -qx "$line" "$sunshine_conf" 2>/dev/null && continue
  echo "$line" >>"$sunshine_conf"
  sunshine_changed=1
done
# KMS capture needs cap_sys_admin, and a package update drops it with the old binary.
sunshine=$(readlink -f "$(command -v sunshine)")
if ! getcap "$sunshine" | grep -q cap_sys_admin; then
  sudo setcap cap_sys_admin+p "$sunshine"
  sunshine_changed=1
fi
# Installed next to Plasma, Sunshine's Desktop app toggles HDR with kscreen-doctor,
# which fails outside Plasma and so aborts every connection.
sunshine_apps=${sunshine_conf%/*}/apps.json
if jq -e 'any(.apps[] | select(.name == "Desktop") | ."prep-cmd"[]?; .do | test("kscreen-doctor"))' \
  "$sunshine_apps" >/dev/null 2>&1; then
  jq '(.apps[] | select(.name == "Desktop")) |= del(."prep-cmd")' "$sunshine_apps" >"$sunshine_apps.new"
  mv "$sunshine_apps.new" "$sunshine_apps"
  sunshine_changed=1
fi
for unit in app-dev.lizardbyte.app.Sunshine.service sunshine.service; do
  systemctl --user disable --now "$unit" 2>/dev/null || true
done
# Linger starts the user manager at boot, which brings PipeWire for the stream's audio.
[[ $(loginctl show-user "$USER" -p Linger --value 2>/dev/null) == yes ]] || sudo loginctl enable-linger "$USER"
for unit in sunshine-prelogin remote-serving; do
  copy_etc_rendered "hyprland/sunshine/$unit.service" "/etc/systemd/system/$unit.service" \
    "s|@USER@|$USER|g; s|@UID@|$(id -u)|g; s|@HOME@|$HOME|g" && sunshine_changed=1
done
if ((sunshine_changed)); then
  sudo systemctl daemon-reload
  sudo systemctl restart sunshine-prelogin.service
fi
sudo systemctl enable --now sunshine-prelogin.service remote-serving.service
if command -v firewall-cmd >/dev/null; then
  sudo firewall-cmd -q --permanent \
    --add-port=47984-47990/tcp --add-port=48010/tcp --add-port=47998-48000/udp
  sudo firewall-cmd -q --reload
fi
# Moonlight's stream settings, the same on both machines: Super and the other system
# shortcuts always go to the other side, 10 Mbit/s (fedora is on Wi-Fi), the mouse set
# for a desktop ("mouseacceleration" is Moonlight's key for that option) and full screen
# (windowmode=1, WM_FULLSCREEN_DESKTOP; on Wayland the default is a window).
moonlight_conf="$HOME/.config/Moonlight Game Streaming Project/Moonlight.conf"
if pgrep -x moonlight >/dev/null; then
  echo "==> Moonlight is open and rewrites its settings on exit; deploy again after closing it"
else
  mkdir -p "${moonlight_conf%/*}"
  grep -qx '\[General\]' "$moonlight_conf" 2>/dev/null || printf '[General]\n' >>"$moonlight_conf"
  for setting in capturesyskeys=2 bitrate=10000 autoadjustbitrate=false mouseacceleration=true windowmode=1; do
    if grep -q "^${setting%%=*}=" "$moonlight_conf"; then
      sed -i "s/^${setting%%=*}=.*/$setting/" "$moonlight_conf"
    else
      sed -i "/^\[General\]$/a $setting" "$moonlight_conf"
    fi
  done
fi
if [[ $DISTRO == fedora ]] && ! flatpak info io.missioncenter.MissionCenter >/dev/null 2>&1; then
  flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install --user -y --noninteractive flathub io.missioncenter.MissionCenter
fi
# Fedora's hyprland pulls in uwsm, whose %post starts its failed-unit notifier in every
# graphical session, Plasma included. Neither session here runs under uwsm.
if systemctl --user cat fumon.service >/dev/null 2>&1; then
  systemctl --user mask --now fumon.service
fi
# libadwaita apps read the font from dconf, not from settings.ini. The icon theme comes
# from the Noctalia qt6ct template hook (noctalia/icon-theme.sh).
gsettings set org.gnome.desktop.interface font-name 'Sans 10'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 10'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
gsettings set org.gnome.desktop.wm.preferences button-layout ':'
systemctl --user enable --now gcr-ssh-agent.socket
# The "default" theme is what XCursor uses when the app asks for none.
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nInherits=Adwaita\n' >"$HOME/.icons/default/index.theme"
# Flatpak does not read the host settings.ini for the cursor; icons come from the portal.
if command -v flatpak >/dev/null; then
  flatpak override --user --unset-env=ICON_THEME --env=XCURSOR_THEME=Adwaita
fi
xdg-mime default org.gnome.Nautilus.desktop inode/directory
xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp \
  image/avif image/heif image/tiff image/bmp image/svg+xml
xdg-mime default org.gnome.Papers.desktop application/pdf
xdg-mime default org.gnome.Showtime.desktop video/mp4 video/x-matroska video/webm \
  video/quicktime video/x-msvideo video/mpeg
xdg-mime default org.gnome.TextEditor.desktop text/plain
# The greeter account is greetd on Fedora and greeter on Arch. Picked by distro, not by
# getent: on a fresh Fedora greetd itself is installed later, by the home module.
greeter=greeter
[[ $DISTRO == fedora ]] && greeter=greetd
copy_etc_rendered hyprland/greetd/config.toml /etc/greetd/config.toml "s/@GREETER@/$greeter/" || true
# Swapping the ~/.config/hypr link while Hyprland is running drops it into emergency mode.
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null && { noctalia msg config-reload || true; }
  hyprctl configerrors
fi
{{/if}}

{{#if dotter.packages.laptop}}
install_packages laptop
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
install_packages home
# fedora-release-identity-kde-desktop protects plasma-desktop, and swapping the identity
# downgrades fedora-release-common. Leftover deps stay: autoremove would take tuned too.
protected=$(cat /etc/dnf/protected.d/*.conf | grep -v -e '^#' -e '^plasma-desktop$' | paste -sd,)
remove_packages home --setopt=protected_packages= --setopt=protected_packages="$protected" \
  --setopt=clean_requirements_on_remove=False
if flatpak info org.kde.haruna >/dev/null 2>&1; then
  sudo flatpak uninstall -y --noninteractive org.kde.haruna
fi
# Fedora's own file: rpm leaves a stray copy in place (as .rpmnew beside it), and the Arch one denies every login.
copy_etc home/greetd/pam /etc/pam.d/greetd || true
if [[ $(systemctl is-enabled greetd.service 2>/dev/null) != enabled ]]; then
  sudo systemctl enable --force greetd.service
  echo "==> Reboot to log in through greetd"
fi
# pcmanfm-qt rewrites its whole settings file on exit, so it is a real file and the
# repo only merges in the keys it owns. The top margin sits below the bar: its
# thickness minus the 1px that margin_edge = -1 pushes off screen.
pcm=$HOME/.config/pcmanfm-qt/default/settings.conf
bar=$(awk -F' *= *' '$1 ~ /^ *thickness$/ {print $2; exit}' "$REPO/hyprland/noctalia/base.toml")
# Unlinked before pcmanfm-qt stops: it writes on exit and would follow the old link into the repo.
[[ -L $pcm ]] && rm "$pcm"
pcm_running=0
if pkill -x pcmanfm-qt; then
  pcm_running=1
  while pgrep -x pcmanfm-qt >/dev/null; do sleep 0.2; done
fi
mkdir -p "${pcm%/*}"
python3 - "$REPO/home/pcmanfm-qt/settings.conf" "$pcm" "$((bar - 1))" <<'PY'
import configparser, os, sys

def load(path):
    c = configparser.ConfigParser(interpolation=None, delimiters=("=",))
    c.optionxform = str
    if os.path.exists(path):
        c.read(path)
    return c

owned, real = load(sys.argv[1]), load(sys.argv[2])
for section in owned.sections():
    if not real.has_section(section):
        real.add_section(section)
    for key, value in owned.items(section):
        real.set(section, key, value)
left, top, right, bottom = (int(v) for v in owned.get("Desktop", "WorkAreaMargins").split(","))
real.set("Desktop", "WorkAreaMargins", f"{left}, {top + int(sys.argv[3])}, {right}, {bottom}")
with open(sys.argv[2], "w") as f:
    real.write(f, space_around_delimiters=False)
PY
if ((pcm_running)) && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl dispatch 'hl.dsp.exec_cmd("pcmanfm-qt --desktop")' >/dev/null
fi
# Fedora has no syncfast-nautilus package (AUR only): take the extension from the
# tag of the installed Flatpak, so it speaks the same D-Bus API.
sf_ver=$(flatpak info io.github.raphael_soares.syncfast 2>/dev/null | awk '/Version:/ {print $2}')
if [[ -n $sf_ver && $(cat "$STATE/syncfast-nautilus" 2>/dev/null) != "$sf_ver" ]]; then
  ext=$HOME/.local/share/nautilus-python/extensions
  mkdir -p "$ext"
  curl -fsSL -o "$ext/syncfast_nautilus.py.new" \
    "https://raw.githubusercontent.com/raphael-soares/syncfast/v$sf_ver/packaging/nautilus/syncfast_nautilus.py"
  mv "$ext/syncfast_nautilus.py.new" "$ext/syncfast_nautilus.py"
  echo "$sf_ver" > "$STATE/syncfast-nautilus"
  nautilus -q 2>/dev/null || true
fi
# The monitor shows the laptop most of the time and then stops answering on DP-1,
# leaving the session without a screen and Sunshine with nothing to stream. The kernel
# replays the LG's own EDID there (amdgpu loads from the initramfs, hence dracut).
edid_changed=0
copy_etc home/edid/lg-ultragear.bin /usr/lib/firmware/edid/lg-ultragear.bin && edid_changed=1
copy_etc home/dracut/edid.conf /etc/dracut.conf.d/edid.conf && edid_changed=1
if ((edid_changed)); then sudo dracut -f --regenerate-all; fi
if ! sudo grubby --info=ALL | grep 'drm.edid_firmware=DP-1' >/dev/null; then
  sudo grubby --update-kernel=ALL --args="drm.edid_firmware=DP-1:edid/lg-ultragear.bin video=DP-1:e"
  echo "==> Reboot for the DP-1 EDID override"
fi
if [[ $(tuned-adm active 2>/dev/null) != *throughput-performance ]]; then
  sudo tuned-adm profile throughput-performance
fi
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
