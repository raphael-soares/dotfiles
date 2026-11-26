# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_cmd starship mise ghostty rbw direnv
# Fedora does not package sops; the project publishes an rpm.
[[ $DISTRO == fedora ]] && ! have sops &&
  step "sudo dnf install https://github.com/getsops/sops/releases/download/v3.13.3/sops-3.13.3-1.x86_64.rpm"
# The TEAjudo hosts reach their servers through SSM (ProxyCommand in secrets/ssh/config.d/teajudo.conf).
[[ $DISTRO == fedora ]] && ! have session-manager-plugin &&
  step "sudo dnf install https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm"
age_key=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
[[ -f $age_key ]] ||
  step "rbw unlock && secrets init"
herdr_setup=$HOME/Code/Personal/herdr-setup
[[ -d $herdr_setup ]] ||
  step "git clone https://github.com/raphael-soares/herdr-setup ~/Code/Personal/herdr-setup && ~/Code/Personal/herdr-setup/install.sh"
