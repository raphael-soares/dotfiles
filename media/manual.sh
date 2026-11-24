# shellcheck shell=bash  # sourced by .dotter/missing.sh
# docker-ce is not in Fedora's repos: it comes from Docker's own.
if [[ $DISTRO == fedora && ! -e $ROOT/etc/yum.repos.d/docker-ce.repo ]] && ! rpm -q docker-ce >/dev/null 2>&1; then
  step "sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo"
fi
need_packages
need_enabled docker.service
if [[ ,$(getent group docker | cut -d: -f4), != *,"$USER",* ]]; then
  step "sudo usermod -aG docker $USER"
  note "then reboot: the session and the user services pick up the group only at a new boot"
elif ! grep -qw docker <<<"$(id -nG)"; then
  note "reboot so this session and the user services get the docker group"
fi
need_flatpaks
[[ -x $HOME/.local/opt/stremio-enhanced/AppRun ]] || step "$REPO_SHOWN/media/install/stremio-enhanced"
# Arr Pick sends a picked torrent to Radarr or Sonarr; its repo is private.
if [[ ! -f $HOME/.config/stremio-enhanced/plugins/arr-pick.plugin.js ]]; then
  step "gh release download -R raphael-soares/stremio-arr-pick -p arr-pick.plugin.js -D ~/.config/stremio-enhanced/plugins --clobber"
  note "Arr Pick needs a gh account that reads raphael-soares/stremio-arr-pick"
fi
# Radarr and Sonarr web pages stay reachable from the other machine's browser.
need_firewall --add-port=7878/tcp --add-port=8990/tcp
