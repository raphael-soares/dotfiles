#!/usr/bin/env bash
# Onboarding detector.
# Dispara em SessionStart. Se a sessao abre num projeto de codigo SEM setup do
# Claude (sem CLAUDE.md e sem .claude/), injeta um lembrete para o Claude rodar a
# skill project-init antes de qualquer tarefa. Nao roda nada sozinho — so avisa.
#
# Requer jq. Sem jq, ou fora de um projeto de codigo, sai limpo sem avisar nada.

set -u
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"
[ -d "$cwd" ] || exit 0

# Ja tem setup? Entao nao e virgem — silencio.
[ -f "$cwd/CLAUDE.md" ] && exit 0
[ -f "$cwd/.claude/CLAUDE.md" ] && exit 0
[ -d "$cwd/.claude" ] && exit 0

# So age quando ha sinal claro de projeto de codigo (evita home, dotfiles, repo
# de config). Precisa de um manifesto de build ou uma pasta src/.
is_code=0
for m in package.json pom.xml build.gradle build.gradle.kts go.mod Cargo.toml \
         pyproject.toml requirements.txt composer.json Gemfile src; do
  [ -e "$cwd/$m" ] && { is_code=1; break; }
done
[ "$is_code" -eq 1 ] || exit 0

msg="Este projeto nao tem setup do Claude (sem CLAUDE.md, sem .claude/). ANTES de \
qualquer tarefa, rode a skill project-init: explore o repo, entreviste o usuario \
sobre produto/dominio/invariantes e crie a base (CLAUDE.md, CONTEXT.md, primeiro \
ADR). Se o usuario so quer algo rapido e pontual, ofereca rodar o onboarding \
antes em vez de assumir."

jq -nc --arg msg "$msg" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $msg}}'
exit 0
