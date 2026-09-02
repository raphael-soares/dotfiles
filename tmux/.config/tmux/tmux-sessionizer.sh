#!/usr/bin/env bash

# Os diretorios varridos saem de TMUX_SESSIONIZER_DIRS, no ~/.env.local
# (veja o .env.example). O tmux chama este script por run-shell, que nao passa
# pelo .bashrc, entao o arquivo e carregado aqui. Se a variavel ja veio
# setada no ambiente (ex.: override manual pra teste), respeita ela e nao
# deixa o .env.local pisar em cima.
[[ -z "${TMUX_SESSIONIZER_DIRS:-}" && -f ~/.env.local ]] && source ~/.env.local

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

source ~/.config/fzf/fzf.sh
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

# Convert display label to safe tmux session name.
# tmux usa ':' pra separar sessao:janela e '.' pra janela.pane; qualquer um
# desses caracteres no meio do nome faz o tmux interpretar o alvo errado
# (ex.: "template.repo" vira janela=template pane=repo). Troca os dois por
# '_' em qualquer posicao, nao so no inicio. '/' -> '-' pra evitar colisao
# com o separador de path usado no label de desambiguacao.
to_session_name() {
    local n="$1"
    n="${n//./_}"
    n="${n//:/_}"
    echo "${n//\//-}"
}

if [[ $# -eq 1 ]]; then
    selected=$1
else
    # Sessoes popup-* pertencem ao toggle de popup e nao entram na lista.
    sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null |
        grep -v '^popup-' || true)

    declare -A session_set
    while IFS= read -r s; do [[ -n "$s" ]] && session_set["$s"]=1; done <<< "$sessions"

    # Dirs whose session name doesn't match any active session
    dir_names=""
    for label in "${!dir_map[@]}"; do
        sname=$(to_session_name "$label")
        [[ -z "${session_set[$sname]}" ]] && dir_names+="$label"$'\n'
    done

    # Active sessions marked with *
    session_lines=""
    while IFS= read -r s; do
        [[ -n "$s" ]] && session_lines+="* $s"$'\n'
    done <<< "$sessions"

    selected=$( (printf '%s' "$session_lines"; printf '%s' "$dir_names") | sort -u | fzf ) || exit 0
    selected="${selected#\* }"
fi

[[ -z "$selected" ]] && exit 0

session_name=$(to_session_name "$selected")

if tmux has-session -t="$session_name" 2>/dev/null; then
    tmux switch-client -t="$session_name"
else
    dir="${dir_map[$selected]:-}"
    if [[ -n "$dir" ]]; then
        tmux new-session -ds "$session_name" -c "$dir"
    else
        tmux new-session -ds "$session_name"
    fi
    tmux switch-client -t="$session_name"
fi
