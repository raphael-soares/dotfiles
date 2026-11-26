# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_cmd starship mise ghostty rbw direnv
[[ -f ${XDG_STATE_HOME:-$HOME/.local/state}/secrets/personal.env ]] ||
  step "rbw unlock && secrets pull"
herdr_setup=$HOME/Code/Personal/herdr-setup
[[ -d $herdr_setup ]] ||
  step "git clone https://github.com/raphael-soares/herdr-setup ~/Code/Personal/herdr-setup && ~/Code/Personal/herdr-setup/install.sh"
