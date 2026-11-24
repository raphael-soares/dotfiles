# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_flatpaks
# Radarr and Sonarr answer the Arr Pick plugin in Stremio on the other machine.
need_firewall --add-port=7878/tcp --add-port=8990/tcp
