#!/usr/bin/env bash
# Aliases do ~/.ssh/config, um por linha, para o sessionizer (modo ssh).

SSH_CONFIG="${HOME}/.ssh/config"

[[ -f "$SSH_CONFIG" ]] || { echo "No SSH config found at $SSH_CONFIG" >&2; exit 1; }

parse_hosts() {
    local config="$1"
    grep -Ei '^(Host |Include )' "$config" | while read -r keyword value; do
        if [[ "${keyword,,}" == "include" ]]; then
            local pattern="${value/#\~/$HOME}"
            for f in $pattern; do
                [[ -f "$f" ]] && parse_hosts "$f"
            done
        else
            # 'Host foo bar' declara varios aliases; read -ra para 'Host *' nao virar glob.
            local -a aliases
            read -ra aliases <<< "$value"
            for alias in "${aliases[@]}"; do
                echo "$alias"
            done
        fi
    done
}

# sort -u: o mesmo alias pode aparecer em mais de um arquivo via Include.
hosts=$(parse_hosts "$SSH_CONFIG" | grep -v '[*?!]' | sort -u)
echo "$hosts"
