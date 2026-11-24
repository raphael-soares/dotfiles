need_packages
need_flatpaks
# Spotifast and ZapFast have no dnf repo (on Arch they come from the AUR list).
if [[ $DISTRO == fedora ]]; then
  for app in spotifast zapfast; do
    rpm -q "$app" >/dev/null 2>&1 || step "sudo dnf install \"\$($REPO_SHOWN/desktop/install/latest-rpm crmne/$app)\""
  done
  # grep without -q: fc-list dying of SIGPIPE would read as the font missing.
  fc-list 2>/dev/null | grep -i 'JetBrainsMono Nerd' >/dev/null ||
    note "install JetBrainsMono Nerd Font by hand (it is not in dnf)"
fi
need_file desktop/audio/91-fuxi-h3-mixer.rules /etc/udev/rules.d/91-fuxi-h3-mixer.rules \
  "sudo udevadm control --reload"
