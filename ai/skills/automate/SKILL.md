---
name: automate
description: Use when the user invokes /automate or asks to schedule a recurring agent task (herdr-automations); interviews the user and creates the automation via the CLI.
---

# /automate

Cria uma automação agendada do herdr-automations a partir da conversa. Ela
aparece no painel Agenda do herdr-app (botão do robô ou `ctrl-space a`) e roda
num terminal do hc com o omp da conta escolhida.

## 1. Confira o CLI

Rode `herdr-automations list --json`. Se o comando falhar ou o campo `backend`
não for `hc`, diga ao usuário para instalar o herdr-setup (o instalador fica em
`~/Code/Personal/herdr-setup`; `~/.dotfiles/.dotter/missing.sh terminal` mostra
o clone, se faltar) e pare aqui.

## 2. Junte o que falta numa pergunta só

Preencha o que a conversa já responde. "Este repo" é a raiz git atual
(`git rev-parse --show-toplevel`). O resto vai numa única chamada `ask`, com:

- O que o agente deve fazer (textarea), já preenchido se o usuário disse.
- Quando (radio): Once, Hourly, Daily, Weekdays, Weekly, Custom cron. Junto, o
  horário (`HH:MM`; para Hourly, só o minuto), checkboxes de dia da semana
  para Weekly, um campo de texto para o cron do Custom e um campo de data
  (`YYYY-MM-DD`) para Once. Pedido de uma vez só ("essa madrugada às 3h",
  "amanhã às 9h", "sexta às 18h") já marca Once e preenche data e hora.
- Repositório (radio): o repo atual, as pastas locais dos spaces
  (`herdr-app ls`) e os repos de `~/Code/<Área>/[<sistema>/]<repo>` (até três
  níveis, `docs/home.md`) que têm `.git`
  (`find "$HOME/Code" -maxdepth 4 -name .git | sed 's|/\.git$||'`).
- Conta (radio): Personal (`omp-personal`) ou Work (`omp-work`). Marque Work
  quando o repo estiver em `~/Code/Unimed`, Personal no resto.
- Onde roda (radio): New worktree (padrão) ou Repo root.

## 3. Reescreva o pedido como prompt autossuficiente

O agente agendado não vê esta conversa. O prompt precisa dizer o objetivo, o
escopo (arquivos, PRs, issues), para onde vai o resultado (comentário na PR,
arquivo escrito, PR aberta) e quando parar. Nada de "como combinamos" ou
referência ao que só existe aqui.

## 4. Monte cron e nome

Mesmas regras do editor da Agenda:

| Quando | Cron |
|---|---|
| Hourly no minuto M | `M * * * *` |
| Daily às H:M | `M H * * *` |
| Weekdays às H:M | `M H * * 1-5` |
| Weekly às H:M nos dias d1, d2 (0 = domingo) | `M H * * d1,d2` em ordem |
| Custom | o cron como o usuário escreveu |
| Once em D às H:M | sem cron: `"at": "D" + "T" + "HH:MM"`, ex. `2026-11-18T03:00` |

Datas relativas saem de `date`: "essa madrugada" e "amanhã" são o dia
seguinte se a hora já passou ou é de madrugada; "hoje à noite" é hoje. Uma
entrada Once roda uma vez e some da lista depois (rodou, falhou ou perdeu a
hora). O notebook precisa estar acordado: se estiver suspenso na hora, a
execução fica marcada como perdida e não roda atrasada. Avise isso ao usuário.
O workspace fecha sozinho quando termina bem.

Hora e minuto sem zero à esquerda (`30 9 * * 1-5`). O nome é um slug curto em
kebab-case, sem acento.

## 5. Mostre, confirme, crie

Monte o JSON com exatamente estas chaves:

```json
{"name": "", "cron": "", "at": "", "repo": "/caminho/absoluto", "workspace": "worktree",
 "workspace_id": "", "agent": "", "template": "omp-personal", "model": "",
 "prompt": "", "mcp_config": "", "timeout_minutes": 60}
```

Valide com `printf %s "$json" | herdr-automations put --dry-run`. Se vier
`problem`, corrija e valide de novo. Com o dry-run limpo, mostre ao usuário
nome, quando em palavras, as próximas execuções do campo `next` (Once tem só uma), repo,
conta e o prompt final. Depois, uma chamada `ask` com Create e Adjust.

- Create: `printf %s "$json" | herdr-automations put`, depois
  `herdr-automations list` para provar que a entrada está lá.
- Adjust: pergunte o que muda, refaça o passo 4 e volte aqui.

Só rode `herdr-automations run <nome> --bg` se o usuário pedir para testar
agora.
