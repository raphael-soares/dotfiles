#!/usr/bin/env bash

current_session="$(tmux display-message -p -F "#{session_name}")"

# tmux usa ':' pra separar sessao:janela e '.' pra janela.pane; um nome de
# sessao com esses caracteres no meio faz '-t popup-nome' ser interpretado
# como alvo janela.pane em vez de nome de sessao (mesmo bug do
# tmux-sessionizer.sh). Sanitiza antes de montar o nome da popup.
safe_session="${current_session//./_}"
safe_session="${safe_session//:/_}"
popup_session="popup-${safe_session}"

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
