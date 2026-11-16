#!/usr/bin/env bash
# Pastas para o sessionizer, uma por linha: label<TAB>caminho.

# O herdr-app roda o script sem passar pelo .bashrc, entao carrega aqui.
if [[ -z "${SESSIONIZER_DIRS:-}" ]]; then
    for _rc in "$HOME"/.config/shell/rc.d/*.sh; do [[ -r "$_rc" ]] && source "$_rc"; done
    [[ -f ~/.env.local ]] && source ~/.env.local
fi

SEARCH_DIRS=()
if [[ -n "${SESSIONIZER_DIRS:-}" ]]; then
    IFS=':' read -r -a SEARCH_DIRS <<< "$SESSIONIZER_DIRS"
    # ~ so vira $HOME quando o shell expande; vindo de variavel, e literal.
    SEARCH_DIRS=("${SEARCH_DIRS[@]/#\~/$HOME}")
fi

# Ignora os que nao existem: find aborta a varredura inteira num caminho invalido.
_existentes=()
for _d in "${SEARCH_DIRS[@]}"; do
    [[ -d "$_d" ]] && _existentes+=("$_d")
done
SEARCH_DIRS=("${_existentes[@]}")
[[ ${#SEARCH_DIRS[@]} -eq 0 ]] && SEARCH_DIRS=("$HOME")

mapfile -t _all_dirs < <(find "${SEARCH_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

# Basename repetido em mais de um SEARCH_DIR: todas as ocorrencias ganham o dir pai.
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

for label in "${!dir_map[@]}"; do
    printf '%s\t%s\n' "$label" "${dir_map[$label]}"
done | sort
