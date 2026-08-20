#!/usr/bin/env bash
# Workflow conductor.
# Dispara em PostToolUse dos tools Skill e Agent. Lê tool_input do stdin (JSON),
# acha o próximo passo do pipeline e emite additionalContext para o Claude
# lembrar o usuário. Não força nada — só sugere o próximo passo do fluxo.
#
# O fluxo: po -> Plan -> tdd -> code-review -> git-commit -> push/PR.
# Requer jq. Sem jq, sai limpo sem fazer nada.

set -u

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"

skill="$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null)"
subagent="$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null)"

next=""

case "$skill" in
  project-init)
    next="Base do projeto criada (CLAUDE.md, CONTEXT.md, primeiro ADR). PROXIMO PASSO sugerido: /po para refinar o primeiro card — agora ele le o CLAUDE.md para dominio, perfis e invariantes."
    ;;
  po)
    next="Refino do PO concluido. PROXIMO PASSO sugerido: spawn Agent(subagent_type=Plan) para desenhar a implementacao, OU /grill-me para estressar o plano antes de codar."
    ;;
  tdd)
    next="Ciclo TDD concluido. PROXIMO PASSO sugerido: confirmar a feature no app rodando antes de seguir — teste passar nao prova UX nem integracao. Depois /code-review --fix."
    ;;
  diagnose)
    next="Diagnose concluido. PROXIMO PASSO sugerido: confirmar end-to-end que o fix funciona no app rodando, depois /code-review --fix antes do commit."
    ;;
  code-review)
    next="Code review concluido. PROXIMO PASSO sugerido: /git-commit para escrever o commit no formato Conventional Commits / release-please."
    ;;
  git-commit)
    next="Commit message gerada. PIPELINE COMPLETO para este card. Proximo: push da branch e abrir PR para a branch de integracao (ex: dev), nunca direto para a branch protegida (main)."
    ;;
  grill-me)
    next="Plano estressado. PROXIMO PASSO sugerido: /tdd para iniciar red-green-refactor com o plano endurecido."
    ;;
  handoff)
    next="Handoff salvo. PROXIMO PASSO sugerido: encerrar a sessao. A proxima deve comecar lendo o arquivo de handoff."
    ;;
esac

case "$subagent" in
  Plan)
    next="Plano arquitetural pronto. PROXIMO PASSO sugerido: /tdd para implementar red-green-refactor seguindo o plano."
    ;;
  Explore)
    # Explore e so pesquisa, sem proximo passo fixo.
    :
    ;;
esac

if [ -n "$next" ]; then
  jq -nc --arg msg "Workflow conductor: $next Inclua essa recomendacao no final da resposta ao usuario." \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $msg}}'
fi

exit 0
