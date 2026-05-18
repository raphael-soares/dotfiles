#!/usr/bin/env bash

SSH_CONFIG="${HOME}/.ssh/config"

[[ -f "$SSH_CONFIG" ]] || { echo "No SSH config found at $SSH_CONFIG"; exit 1; }

source ~/.config/fzf/fzf.sh
export FZF_DEFAULT_OPTS="$FZF_BASE_OPTS
  --prompt='SSH:  '
  --tmux center,50%,40%"

parse_hosts() {
    local config="$1"
    grep -E '^(Host |Include )' "$config" | while read -r keyword value; do
        if [[ "$keyword" == "Include" ]]; then
            local pattern="${value/#\~/$HOME}"
            for f in $pattern; do
                [[ -f "$f" ]] && parse_hosts "$f"
            done
        else
            echo "$value"
        fi
    done
}

hosts=$(parse_hosts "$SSH_CONFIG" | grep -v '[*?!]')

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(echo "$hosts" | fzf) || exit 0
fi

[[ -z "$selected" ]] && exit 0

SESSION="ssh"

if ! tmux has-session -t="$SESSION" 2>/dev/null; then
    tmux new-session -ds "$SESSION" -n "$selected"
    win_id=$(tmux display-message -t "$SESSION" -p "#{window_id}")
    tmux send-keys -t "$win_id" "ssh $selected" Enter
else
    win_id=$(tmux list-windows -t "$SESSION" -F "#{window_id} #{window_name}" 2>/dev/null \
        | awk -v name="$selected" '$2 == name {print $1; exit}')
    if [[ -n "$win_id" ]]; then
        tmux switch-client -t "$win_id"
        exit 0
    fi
    win_id=$(tmux new-window -t "$SESSION" -n "$selected" -P -F "#{window_id}")
    tmux send-keys -t "$win_id" "ssh $selected" Enter
fi

tmux switch-client -t "$win_id"
