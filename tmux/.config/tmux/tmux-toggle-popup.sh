#!/usr/bin/env bash

current_session="$(tmux display-message -p -F "#{session_name}")"
current_tty="$(tmux display-message -p -F "#{client_tty}")"
current_id="$(tmux display-message -p -F "#{session_id}")"

# tmux usa ':' pra separar sessao:janela e '.' pra janela.pane; um nome de
# sessao com esses caracteres no meio faz '-t popup-nome' ser interpretado
# como alvo janela.pane em vez de nome de sessao (mesmo bug do
# tmux-sessionizer.sh, e o prefixo '=' nao resolve). Sanitiza antes de montar
# o nome da popup, e usa a mesma forma sanitizada nos nomes das opcoes.
safe_session="${current_session//[^a-zA-Z0-9_-]/_}"
popup_session="popup-${safe_session}"

# Estado guardado no servidor: o tty do cliente que roda dentro da popup e o
# id da sessao de onde ela veio. O nome da sessao sozinho nao diz se voce esta
# dentro da popup ou olhando ela em tela cheia por um cliente normal, e era
# isso que fazia o keybind dar detach e derrubar o tmux inteiro.
suffix="${safe_session}"
[[ "$current_session" == popup-* ]] && suffix="${current_session#popup-}"
popup_tty_option="@popup-tty-${suffix}"
popup_origin_option="@popup-origin-${suffix}"

if [[ "$current_session" == popup-* ]]; then
    popup_tty="$(tmux show-options -sqv "$popup_tty_option")"
    origin="$(tmux show-options -sqv "$popup_origin_option")"

    if [[ -n "$current_tty" && "$current_tty" == "$popup_tty" ]]; then
        # Dentro da popup: so fecha a popup.
        tmux detach-client
    elif [[ -n "$origin" && "$origin" != "$current_id" ]] &&
        tmux has-session -t "$origin" 2>/dev/null; then
        # Sessao da popup aberta em tela cheia num cliente normal: volta pra
        # sessao de origem. Alvo por id de sessao, que nao sofre com '.' e ':'.
        tmux switch-client -t "$origin"
    else
        tmux display-message "sem sessao de origem para ${current_session}"
    fi
else
    if ! tmux has-session -t "=$popup_session" 2>/dev/null; then
        tmux new-session -d -s "$popup_session"
        tmux set-option -t "=$popup_session" detach-on-destroy on
    fi
    tmux set-option -s "$popup_origin_option" "$current_id"
    tmux popup -d '#{pane_current_path}' -xC -yC -w80% -h80% -E \
        "tmux set-option -s '$popup_tty_option' \"\$(tty)\"; tmux attach -t '=$popup_session'; tmux set-option -su '$popup_tty_option'"
fi
