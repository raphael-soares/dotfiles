# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_copr lionheartp/Hyprland
need_copr lizardbyte/stable
need_packages
need_flatpaks
[[ -x $HOME/.local/opt/stremio-enhanced/AppRun ]] || step "$REPO_SHOWN/hyprland/install/stremio-enhanced"
# Arr Pick sends a picked torrent to Radarr or Sonarr; its repo is private.
if [[ ! -f $HOME/.config/stremio-enhanced/plugins/arr-pick.plugin.js ]]; then
  step "gh release download -R raphael-soares/stremio-arr-pick -p arr-pick.plugin.js -D ~/.config/stremio-enhanced/plugins --clobber"
  note "Arr Pick needs a gh account that reads raphael-soares/stremio-arr-pick"
fi
# Fedora has no syncfast-nautilus package (AUR only): the extension comes from the
# tag of the installed Flatpak, so it speaks the same D-Bus API.
if [[ $DISTRO == fedora ]]; then
  sf_ver=$(flatpak info io.github.raphael_soares.syncfast 2>/dev/null | awk '/Version:/ {print $2}')
  if [[ -n $sf_ver && $(cat "$STATE/syncfast-nautilus" 2>/dev/null) != "$sf_ver" ]]; then
    step "curl -fsSL --create-dirs -o ~/.local/share/nautilus-python/extensions/syncfast_nautilus.py https://raw.githubusercontent.com/raphael-soares/syncfast/v$sf_ver/packaging/nautilus/syncfast_nautilus.py && mkdir -p ${STATE/#"$HOME"/\~} && echo $sf_ver > ${STATE/#"$HOME"/\~}/syncfast-nautilus && nautilus -q"
  fi
fi
# bin/monitor-away asks the monitor which input it shows over DDC; Arch keeps the
# i2c devices to that group (Fedora grants them to the logged-in user).
if getent group i2c >/dev/null && ! grep -qw i2c <<<"$(id -nG)"; then
  step "sudo usermod -aG i2c $USER"
  note "takes effect at the next login"
fi
# Sunshine runs from boot as a system unit, so the other machine reaches the login
# screen. Linger starts the user manager at boot, which brings PipeWire for its audio.
if have loginctl && [[ $(loginctl show-user "$USER" -p Linger --value 2>/dev/null) != yes ]]; then
  step "sudo loginctl enable-linger $USER"
fi
if have sunshine; then
  sunshine=$(readlink -f "$(command -v sunshine)")
  # KMS capture needs cap_sys_admin, and a package update drops it with the old binary.
  grep -q cap_sys_admin <<<"$(getcap "$sunshine" 2>/dev/null)" ||
    step "sudo setcap cap_sys_admin+p $sunshine && sudo systemctl restart sunshine-prelogin.service"
  for unit in sunshine-prelogin remote-serving; do
    need_file "hyprland/sunshine/$unit.service" "/etc/systemd/system/$unit.service" \
      "sudo systemctl daemon-reload" "s|@USER@|$USER|g; s|@UID@|$(id -u)|g; s|@HOME@|$HOME|g"
  done
  need_enabled sunshine-prelogin.service remote-serving.service
  need_restart sunshine-prelogin.service sunshine \
    "$HOME/.config/sunshine/sunshine.conf" "$HOME/.config/sunshine/apps.json"
fi
need_firewall --add-port=47984-47990/tcp --add-port=48010/tcp --add-port=47998-48000/udp
