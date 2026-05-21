#!/usr/bin/env bash

current_session="$(tmux display-message -p -F "#{session_name}")"
popup_session="popup-${current_session}"

if [[ "$current_session" == popup-* ]]; then
    tmux detach-client
else
    if ! tmux has-session -t "$popup_session" 2>/dev/null; then
        tmux new-session -d -s "$popup_session"
        tmux set-option -t "$popup_session" detach-on-destroy on
    fi
    tmux popup -d '#{pane_current_path}' -xC -yC -w80% -h80% -E \
        "tmux attach -t '$popup_session'"
fi
