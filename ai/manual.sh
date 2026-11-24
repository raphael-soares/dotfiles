need_packages
need_cmd omp claude rtk
superpowers=v7.0.2
if have omp && [[ v$(jq -r .version "$HOME/.omp/plugins/node_modules/superpowers/package.json" 2>/dev/null) != "$superpowers" ]]; then
  step "omp plugin install github:obra/superpowers#$superpowers"
fi
if have claude && ! claude mcp get bitwarden >/dev/null 2>&1; then
  step "claude mcp add -s user bitwarden -e BW_CLI_PATH=$HOME/.local/share/mise/shims/bw -- npx -y @bitwarden/mcp-server@2026.7.0"
fi
