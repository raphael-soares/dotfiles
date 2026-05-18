#!/usr/bin/env bash

current_session="$(tmux display-message -p -F "#{session_name}")"
popup_session="popup-${current_session}"

if [[ "$current_session" == popup-* ]]; then
    tmux detach-client
else
    tmux popup -d '#{pane_current_path}' -xC -yC -w80% -h80% -E "tmux attach -t '$popup_session' || tmux new -s '$popup_session'"
fi
