# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_cmd omp claude rtk
superpowers=v7.0.2
if have omp && [[ v$(jq -r .version "$HOME/.omp/plugins/node_modules/superpowers/package.json" 2>/dev/null) != "$superpowers" ]]; then
  step "omp plugin install github:obra/superpowers#$superpowers"
fi
