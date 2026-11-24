# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
superpowers=v7.0.2
if have omp && [[ v$(jq -r .version "$HOME/.omp/profiles/enterprise/plugins/node_modules/superpowers/package.json" 2>/dev/null) != "$superpowers" ]]; then
  step "OMP_PROFILE=enterprise omp plugin install github:obra/superpowers#$superpowers"
fi
