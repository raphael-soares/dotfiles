#!/usr/bin/env bash
set -euo pipefail

# Menu do workmux, aberto pelo prefix + a. Cada entrada do display-menu chama
# um subcomando deste mesmo script.
#
# O prompt do agente nunca e interpolado numa linha de comando: no caminho
# rapido ele fica numa variavel do bash, no caminho do editor vira arquivo
# passado com -P. Aspas e apostrofo no texto nao quebram nada.

SELF="${HOME}/.config/tmux/tmux-workmux.sh"

# Agentes que o workmux sabe injetar prompt, com a tecla de cada um no submenu.
# 'c' ja e do claude, entao o codex fica com 'x'.
declare -A AGENT_KEYS=([claude]=c [codex]=x [gemini]=g [opencode]=o [pi]=p)
AGENT_ORDER=(claude codex gemini opencode pi)

# O popup nao e um pane, entao display-message responde sobre o pane ativo, que
# e de onde a tecla foi apertada.
origin_cwd() { tmux display-message -p -F '#{pane_current_path}'; }
origin_session() { tmux display-message -p -F '#{session_name}'; }

# Comando tmux que abre um popup rodando um subcomando daqui. O -d com formato
# faz o proprio tmux resolver o diretorio do pane de origem.
popup_cmd() {
    printf "display-popup -d '#{pane_current_path}' -w %s -h %s -E '%s %s'" \
        "$1" "$2" "$SELF" "${*:3}"
}

in_worktree() {
    local git_dir
    git_dir=$(cd "$(origin_cwd)" 2>/dev/null && git rev-parse --git-dir 2>/dev/null) || return 1
    [[ "$git_dir" == */worktrees/* ]]
}

# O ambiente do servidor tmux traz EDITOR=nano herdado do sistema. Aqui o nvim
# ganha, que e o que esta configurado no resto do setup.
pick_editor() {
    if command -v nvim >/dev/null; then
        echo nvim
    else
        echo "${VISUAL:-${EDITOR:-vi}}"
    fi
}

# Arquivo do prompt longo. Global de proposito: o trap de EXIT roda depois que
# a funcao ja voltou, entao uma variavel local dela nao existiria mais.
PROMPT_FILE=""
limpa_prompt_file() {
    [[ -n "$PROMPT_FILE" ]] && rm -f "$PROMPT_FILE"
    return 0
}
trap limpa_prompt_file EXIT

# Popup fecha junto com o script. Sem isso, erro do workmux passa em branco.
pause_on_error() {
    printf '\n'
    read -rsn1 -p "falhou. qualquer tecla fecha."
}

cmd_menu() {
    local items=()
    items+=("agente novo (prompt rapido)" a "$(popup_cmd 80% 12 add)")
    items+=("agente novo (prompt no editor)" A "$(popup_cmd 80% 80% add-editor)")
    items+=("agente novo (escolher agente)" g "run-shell '$SELF menu-agents'")
    items+=("")
    items+=("abrir worktree" o "run-shell '$SELF open'")
    items+=("dashboard" d "display-popup -w 90% -h 80% -E 'workmux dashboard'")
    items+=("sidebar" s "run-shell 'workmux sidebar'")
    items+=("pular pro agente pronto" j "run-shell 'workmux last-done'")

    if in_worktree; then
        items+=("")
        items+=("merge deste worktree" m "run-shell '$SELF confirm merge'")
        items+=("rebase na base" R "run-shell '$SELF confirm rebase'")
        items+=("remover este worktree" r "run-shell '$SELF confirm remove'")
    fi

    tmux display-menu -T ' workmux ' -x C -y C "${items[@]}"
}

cmd_menu_agents() {
    local items=() agente
    for agente in "${AGENT_ORDER[@]}"; do
        command -v "$agente" >/dev/null || continue
        items+=("$agente" "${AGENT_KEYS[$agente]}" "$(popup_cmd 80% 12 add "$agente")")
    done

    if [[ ${#items[@]} -eq 0 ]]; then
        tmux display-message "nenhum agente encontrado no PATH"
        return
    fi

    tmux display-menu -T ' agente ' -x C -y C "${items[@]}"
}

cmd_add() {
    local agente="${1:-}"
    local prompt

    read -r -e -p "prompt> " prompt || exit 0
    [[ -z "${prompt//[[:space:]]/}" ]] && exit 0

    local args=(add --auto-name --parent-session "$(origin_session)")
    [[ -n "$agente" ]] && args+=(--agent "$agente")
    args+=(--prompt "$prompt")

    workmux "${args[@]}" || pause_on_error
}

cmd_add_editor() {
    local agente="${1:-}"
    PROMPT_FILE=$(mktemp -t workmux-prompt.XXXXXX.md)

    "$(pick_editor)" "$PROMPT_FILE"

    # Editor fechado sem salvar nada, ou so com espaco em branco: desiste.
    grep -q '[^[:space:]]' "$PROMPT_FILE" 2>/dev/null || exit 0

    local args=(add --auto-name --parent-session "$(origin_session)")
    [[ -n "$agente" ]] && args+=(--agent "$agente")
    args+=(--prompt-file "$PROMPT_FILE")

    workmux "${args[@]}" || pause_on_error
}

cmd_open() {
    cd "$(origin_cwd)" || exit 1

    local linhas selecionado handle
    linhas=$(workmux list --json 2>/dev/null |
        jq -r '.[]
            | select(.is_main | not)
            | [.handle, .branch, (if .is_open then "aberto" else "fechado" end)]
            | @tsv') || {
        tmux display-message "workmux list falhou aqui"
        exit 1
    }

    if [[ -z "$linhas" ]]; then
        tmux display-message "nenhum worktree neste projeto"
        exit 0
    fi

    # shellcheck source=/dev/null
    [[ -f ~/.config/fzf/fzf.sh ]] && source ~/.config/fzf/fzf.sh
    export FZF_DEFAULT_OPTS="${FZF_BASE_OPTS:-}
      --prompt='WORKTREE: '
      --tmux center,60%,40%"

    selecionado=$(column -t -s $'\t' <<<"$linhas" | fzf) || exit 0
    handle="${selecionado%% *}"
    [[ -n "$handle" ]] || exit 0

    workmux open --parent-session "$(origin_session)" "$handle"
}

cmd_confirm() {
    local acao="$1" pergunta
    case "$acao" in
    merge) pergunta="merge deste worktree na base e limpar tudo?" ;;
    rebase) pergunta="rebase deste worktree na base?" ;;
    remove) pergunta="remover worktree, janela e branch?" ;;
    *)
        tmux display-message "acao desconhecida: $acao"
        return 1
        ;;
    esac

    tmux confirm-before -p "$pergunta (y/n) " "$(popup_cmd 80% 60% run "$acao")"
}

cmd_run() {
    cd "$(origin_cwd)" || exit 1
    workmux "$@" || pause_on_error
}

if ! command -v workmux >/dev/null; then
    tmux display-message "workmux nao esta instalado"
    exit 1
fi

case "${1:-menu}" in
menu) cmd_menu ;;
menu-agents) cmd_menu_agents ;;
add) cmd_add "${2:-}" ;;
add-editor) cmd_add_editor "${2:-}" ;;
open) cmd_open ;;
confirm) cmd_confirm "${2:?falta a acao}" ;;
run) cmd_run "${@:2}" ;;
*)
    echo "uso: ${0##*/} {menu|menu-agents|add|add-editor|open|confirm|run}" >&2
    exit 1
    ;;
esac
