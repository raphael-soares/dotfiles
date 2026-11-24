# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_flatpaks
[[ -x $HOME/.local/opt/stremio-enhanced/AppRun ]] || step "$REPO_SHOWN/media/install/stremio-enhanced"
# Arr Pick sends a picked torrent to Radarr or Sonarr; its repo is private.
if [[ ! -f $HOME/.config/stremio-enhanced/plugins/arr-pick.plugin.js ]]; then
  step "gh release download -R raphael-soares/stremio-arr-pick -p arr-pick.plugin.js -D ~/.config/stremio-enhanced/plugins --clobber"
  note "Arr Pick needs a gh account that reads raphael-soares/stremio-arr-pick"
fi
# Radarr and Sonarr web pages stay reachable from the other machine's browser.
need_firewall --add-port=7878/tcp --add-port=8990/tcp
