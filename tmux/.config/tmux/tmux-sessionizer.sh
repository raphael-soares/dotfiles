#!/usr/bin/env bash

# Os diretorios varridos saem de TMUX_SESSIONIZER_DIRS, definida em
# ~/.config/shell/rc.d/*.sh ou no ~/.env.local (veja o .env.example). O tmux
# chama este script por run-shell, que nao passa pelo .bashrc, entao os
# arquivos sao carregados aqui. Se a variavel ja veio setada no ambiente
# (ex.: override manual pra teste), respeita ela e nao carrega nada.
if [[ -z "${TMUX_SESSIONIZER_DIRS:-}" ]]; then
    for _rc in "$HOME"/.config/shell/rc.d/*.sh; do [[ -r "$_rc" ]] && source "$_rc"; done
    [[ -f ~/.env.local ]] && source ~/.env.local
fi

SEARCH_DIRS=()
if [[ -n "${TMUX_SESSIONIZER_DIRS:-}" ]]; then
    IFS=':' read -r -a SEARCH_DIRS <<< "$TMUX_SESSIONIZER_DIRS"
    # ~ so vira $HOME quando o shell expande; vindo de variavel, e literal.
    SEARCH_DIRS=("${SEARCH_DIRS[@]/#\~/$HOME}")
fi

# Ignora os que nao existem: find aborta a varredura inteira num caminho invalido.
_existentes=()
for _d in "${SEARCH_DIRS[@]}"; do
    [[ -d "$_d" ]] && _existentes+=("$_d")
done
SEARCH_DIRS=("${_existentes[@]}")
# Sem a variavel (ou com tudo invalido), varre as pastas do home.
[[ ${#SEARCH_DIRS[@]} -eq 0 ]] && SEARCH_DIRS=("$HOME")

[[ -f ~/.config/fzf/fzf.sh ]] && source ~/.config/fzf/fzf.sh
export FZF_DEFAULT_OPTS="$FZF_BASE_OPTS
  --prompt='SESSIONIZER: '
  --tmux center,50%,40%"

# Build label->path map; quando o mesmo basename aparece em mais de um
# SEARCH_DIR, desambigua TODAS as ocorrencias com o dir pai (nao so a
# segunda em diante). Duas passadas: conta ocorrencias de cada basename,
# depois monta os labels. Evita o bug de colisao tripla (3+ pastas com o
# mesmo nome perdiam a entrada mais antiga).
mapfile -t _all_dirs < <(find "${SEARCH_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

declare -A base_count
for d in "${_all_dirs[@]}"; do
    base="${d##*/}"
    base_count["$base"]=$(( ${base_count[$base]:-0} + 1 ))
done

declare -A dir_map
for d in "${_all_dirs[@]}"; do
    base="${d##*/}"
    if [[ ${base_count[$base]} -gt 1 ]]; then
        label="${d%/*}/${base}"
    else
        label="$base"
    fi
    dir_map["$label"]="$d"
done

# ':' e '.' no nome fazem o tmux ler sessao:janela.pane errado ("template.repo" vira
# janela=template pane=repo), entao viram '_'. '/' vira '-' para nao colidir com o
# separador do label de desambiguacao.
to_session_name() {
    local n="$1"
    n="${n//./_}"
    n="${n//:/_}"
    echo "${n//\//-}"
}

# Sessao aberta vem como "* nome". O ctrl-x do fzf chama o proprio script nos
# modos --list e --kill.
list_entries() {
    local sessions s label
    # Sessoes popup-* pertencem ao toggle de popup e nao entram na lista.
    sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null |
        grep -v '^popup-' || true)

    declare -A session_set
    while IFS= read -r s; do [[ -n "$s" ]] && session_set["$s"]=1; done <<< "$sessions"

    while IFS= read -r s; do
        [[ -n "$s" ]] && printf '* %s\n' "$s"
    done <<< "$sessions" | sort
    for label in "${!dir_map[@]}"; do
        [[ -z "${session_set[$(to_session_name "$label")]}" ]] && printf '%s\n' "$label"
    done | sort
}

case "${1:-}" in
    --dirs)
        for label in "${!dir_map[@]}"; do
            printf '%s\t%s\n' "$label" "${dir_map[$label]}"
        done | sort
        exit 0
        ;;
    --list)
        list_entries
        exit 0
        ;;
    --kill)
        # Matar a sessao atual jogaria o cliente pra outra (detach-on-destroy off).
        [[ "$2" == '* '* && "${2#\* }" != "${SESSIONIZER_CURRENT:-}" ]] &&
            tmux kill-session -t "=${2#\* }"
        exit 0
        ;;
esac

if [[ $# -eq 1 ]]; then
    selected=$1
else
    export SESSIONIZER_CURRENT
    SESSIONIZER_CURRENT=$(tmux display-message -p '#{client_session}')
    self=$(realpath "$0")
    selected=$(list_entries | fzf \
        --bind="ctrl-x:execute-silent($self --kill {})+reload($self --list)") || exit 0
    selected="${selected#\* }"
fi

[[ -z "$selected" ]] && exit 0

session_name=$(to_session_name "$selected")

if tmux has-session -t="$session_name" 2>/dev/null; then
    tmux switch-client -t="$session_name"
else
    dir="${dir_map[$selected]:-}"
    size=(-x "$(tmux display-message -p '#{window_width}')" -y "$(tmux display-message -p '#{window_height}')")
    if [[ -n "$dir" ]]; then
        tmux new-session -ds "$session_name" -c "$dir" "${size[@]}"
    else
        tmux new-session -ds "$session_name" "${size[@]}"
    fi
    tmux switch-client -t="$session_name"
fi
