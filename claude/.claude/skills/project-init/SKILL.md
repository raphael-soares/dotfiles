---
name: project-init
description: Onboarding de um projeto novo (sem CLAUDE.md). Explora o repo, entrevista o usuário e cria a base que o resto do fluxo precisa — CLAUDE.md, CONTEXT.md e o primeiro ADR — ANTES de qualquer tarefa. Use quando o projeto não tem setup do Claude, quando o usuário pede para "configurar o projeto", "onboarding", "criar o CLAUDE.md", ou quando uma sessão começa num repo virgem.
---

# project-init — preparar um projeto para trabalhar

Um projeto sem `CLAUDE.md` é um projeto que o Claude não entende. Antes de
implementar, refatorar ou revisar qualquer coisa, monte a base: explore o
código, **entreviste o usuário** sobre o produto e o domínio, e escreva os
documentos que as outras skills consomem (`po`, `grill-me`,
`domain-driven-design`).

> Converse em **pt-BR, em prosa clara**. Isto é descoberta, não execução — não
> comprima, não vá para o modo caveman aqui.

Não pule a entrevista. Ler o código diz o COMO; só o usuário sabe o QUÊ e o
PORQUÊ — o domínio, os perfis, os invariantes, o que está fora dos limites.

## O ciclo

1. **Checagem** — o projeto já tem `CLAUDE.md`? Se sim, não é virgem: pergunte
   se é para revisar/atualizar a base, e não sobrescreva sem confirmação.
2. **Exploração** — leia o repo e levante o que dá para inferir sozinho.
3. **Entrevista** — uma pergunta por vez, com sua resposta recomendada. É o
   coração da skill.
4. **Convergência** — resuma o que entendeu e peça um "sim" explícito.
5. **Escrita** — crie os arquivos da base e mostre o que foi criado.
6. **Próximo passo** — diga ao usuário que o projeto está pronto e como começar.

## 1. Checagem

Procure `CLAUDE.md` na raiz e um `.claude/`. Se existirem, o projeto já tem base
— ofereça revisar/completar em vez de recriar. Se não existirem, siga.

## 2. Exploração — descubra o que o código já conta

Antes de perguntar, levante sozinho (assim a entrevista vira confirmação, não
interrogatório do zero):

- **Stack e build** — manifestos (`package.json`, `pom.xml`, `build.gradle`,
  `go.mod`, `Cargo.toml`, `pyproject.toml`, etc.), versões, framework.
- **Como rodar e testar** — scripts, `Makefile`, `docker-compose.yml`, README.
- **Estrutura** — pastas principais, pontos de entrada, camadas/módulos.
- **Domínio aparente** — nomes de entidades, tabelas, rotas, migrations.
- **Git** — branches que existem, branch padrão, hooks, convenção de commit.
- **Docs já existentes** — README, `docs/`, ADRs, specs.

Liste o que achou e marque o que é **suposição a confirmar** com o usuário.

## 3. Entrevista — entenda o produto

Uma frente por vez, com recomendação sua a partir do que explorou. Não despeje
tudo de uma vez; aprofunde o ponto mais incerto primeiro. Cubra:

- **Produto** — o que o sistema faz e para quem. Qual problema resolve.
- **Perfis / usuários** — quem usa e o que cada papel pode fazer (vira a base do
  RBAC e do que o `po` chama de "perfil afetado").
- **Linguagem ubíqua** — as entidades centrais e os termos do domínio, no nome
  que o negócio usa. Confirme os que você inferiu do código.
- **Invariantes invioláveis** — as regras que nunca podem ser quebradas
  (isolamento de tenant, SSOT, "X nasce de Y, nunca à mão", limites de
  segurança/privacidade). São o que as outras skills vão defender.
- **Fluxo de git** — branch de integração, branch protegida, padrão de commit,
  como abre PR.
- **Rodar / testar / buildar** — confirme os comandos que você inferiu.
- **Prioridade e fora-de-escopo** — o que importa agora, o que não se deve mexer.

Se uma área não tem resposta clara, registre como lacuna — é risco conhecido, não
buraco para preencher inventando.

## 4. Convergência

Devolva um resumo curto: produto em uma frase, perfis, entidades centrais,
invariantes, comandos de run/test, fluxo de git. Pergunte: **"Fecho a base
assim?"** Só escreva os arquivos com confirmação explícita.

## 5. Escrita — a base do projeto

Crie estes arquivos. Use a linguagem ubíqua confirmada na entrevista em todos.

### `CLAUDE.md` (raiz) — o mapa do projeto

```markdown
# CLAUDE.md — <Nome do projeto>

## O que é
<1–2 frases: o produto e para quem.>

## Stack
| Componente | Tech |
|---|---|
| <ex: API> | <...> |
| <ex: Frontend> | <...> |
| <ex: Infra> | <...> |

## Comandos
\```bash
<rodar>      # ...
<testar>     # ...
<buildar>    # ...
\```

## Git
- Branch de integração: `<dev>` · Branch protegida: `<main>`
- <padrão de branch e de commit; nunca commitar direto na protegida>

## Invariantes invioláveis
- <regra 1 — o porquê>
- <regra 2 — o porquê>

## Perfis e papéis
| Papel | Pode |
|---|---|
| <...> | <...> |

## Mapa de documentação
| Doc | Quando ler |
|---|---|
| `CONTEXT.md` | Linguagem do domínio, entidades, bounded contexts |
| `docs/adr/` | Decisões de arquitetura e o porquê delas |
| <docs que forem surgindo> | <...> |
```

### `CONTEXT.md` (raiz) — a linguagem do domínio

Glossário ubíquo + visão de bounded contexts. É o que `domain-driven-design` e
`po` consomem. Estrutura:

```markdown
# CONTEXT — <Nome do projeto>

## Domínio em uma frase
<...>

## Bounded contexts
- **<contexto>** — <responsabilidade, o que entra e sai>

## Glossário ubíquo
| Termo | Significado no domínio |
|---|---|
| <Entidade> | <o que é, no vocabulário do negócio> |

## Invariantes
- <as mesmas regras do CLAUDE.md, em termos de domínio>
```

### `docs/adr/0001-registrar-decisoes-com-adr.md` — semente do log de decisões

O primeiro ADR registra a própria decisão de usar ADRs. Use o formato padrão
(contexto, decisão, consequências). A partir daqui, toda decisão de arquitetura
vira um ADR novo nessa pasta.

```markdown
# 1. Registrar decisões de arquitetura com ADRs

Data: <AAAA-MM-DD>
Status: aceito

## Contexto
Precisamos de um registro leve do PORQUÊ das decisões de arquitetura, para o time
e para os agentes que trabalham no projeto.

## Decisão
Registrar cada decisão significativa como um ADR em `docs/adr/`, numerado e
imutável depois de aceito. Mudou de ideia? Novo ADR que supera o anterior.

## Consequências
Histórico de decisões versionado e navegável; uma etapa a mais ao decidir algo
estrutural.
```

### `.claude/po-plans/` — pasta dos planos do PO

Crie a pasta (com um `.gitkeep`) para a skill `po` escrever os planos depois.

## 6. Próximo passo

Avise que a base está pronta e aponte o começo do fluxo: refinar o primeiro card
com `/po`, que agora vai ler este `CLAUDE.md` para domínio, perfis e invariantes.

## Limites

- Não implemente feature nenhuma aqui — esta skill só monta a base.
- Não invente domínio: termo, regra ou perfil que não veio do usuário nem do
  código, pergunte.
- Não sobrescreva um `CLAUDE.md`/`CONTEXT.md` existente sem confirmação.
