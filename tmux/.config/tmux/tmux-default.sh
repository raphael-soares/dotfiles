#!/usr/bin/env bash

# Se ja estamos dentro de um client tmux, dar attach aninhado quebra prefix
# e escape sequences. Nesse caso so troca pra sessao default.
if [[ -n "${TMUX:-}" ]]; then
    tmux has-session -t default 2>/dev/null || tmux new-session -ds default
    tmux switch-client -t default
else
    tmux has-session -t default 2>/dev/null || tmux new-session -d -s default
    tmux attach-session -t default
fi
