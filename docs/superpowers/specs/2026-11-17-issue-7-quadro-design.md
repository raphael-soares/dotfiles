# Board por repo atualizado pelos agentes: design

- **Issue:** raphael-soares/dotfiles#7 (o PRD está lá)
- **Data:** 2026-11-17
- **Entrega 2 de 3** (a 1 foi PRD e regras; a 3 é a conferência da manhã no herdr-automations)

## Por quê

O dono gerencia os agentes como uma software house: decide o quê e em que ordem,
e quer acompanhar o resto num board visual sem trabalho manual. O estado já existe
(labels da fila, responsável, PR); falta mostrá-lo.

## Objetivos

- Board do GitHub Projects por repo, com as colunas Backlog, Investigação, Pronta,
  Fazendo, Esperando você, Revisão, Feita, nesta ordem.
- O card anda sozinho quando o estado da issue muda.
- Criar o board de um repo é um comando.

## Não objetivos

- Board único para vários repos (decisão do dono: um por repo).
- Arrastar card no site mudar a label (o caminho é mudar a label).
- Conferência diária e resumo da manhã (entrega 3).
- Ligar board nos repos da TEAjudo: o desenho vale para qualquer repo com
  `ficha.json`, mas isso não faz parte desta entrega.

## Antigoals

- Board que mente: coluna diferente do estado real da issue.
- Board bloquear a fila: falha do board nunca para o trabalho.

## Abordagens

1. **Comando local `quadro` + board modelo com workflows nativos** (escolhida pelo
   dono). Atualiza na hora, sem secret nem workflow por repo. Custo: label mudada à
   mão no site só se reflete na próxima chamada do `quadro` (a conferência da manhã
   cobre).
2. `project-label-sync` por repo. Descartada: polling de 15 min, secret e workflow
   por repo, projeto sem uso conhecido.
3. Action própria por evento. Descartada: código e secret por repo para cobrir um
   caso (mudar label pelo site) que não é o do dono.

Repo sem board, ou sem fila, segue o fluxo simples (issue e PR interativas), sem
mudança (decisão do dono).

## Desenho

### Regra única de coluna

A coluna nunca é gravada como dado próprio: é calculada do estado da issue, na
primeira regra que casar.

| Estado | Coluna |
|---|---|
| fechada | Feita |
| login do `gh` entre os responsáveis | Esperando você |
| PR ligada | Revisão |
| label `em-execucao` | Fazendo |
| label `ready-for-agent` | Pronta |
| label `investigando` | Investigação |
| nenhuma das anteriores | Backlog |

"PR ligada" é PR aberta ou mesclada com head `fila/<N>` em qualquer repo de
`repos` do `ficha.json` (como a `fila` busca), ou que fecha a issue (`Closes #N`,
em `closedByPullRequestsReferences`). Mesclada conta porque a issue fica aberta
entre o merge e o fechamento; PR fechada sem merge não conta.

O board é do repositório onde as issues moram: o repo `fila` do `ficha.json`. Em
projeto com `repos`, as PRs ficam nos repos de código, mas o board, o link e a
label `investigando` são do repo da fila.

### Comando `ai/.local/bin/quadro`

Python, no mesmo estilo da `fila` (mesma pasta, `gh` como única dependência).

- `quadro sync <dir> [N ...]`: lê `quadro` do `ficha.json` de `<dir>`; sem o campo,
  sai 0 sem fazer nada. Para cada issue pedida (sem N: todas as abertas do repo da
  fila e os itens do board que ainda não estão em Feita), garante que ela está no
  board (`addProjectV2ItemById`) e grava a coluna calculada no campo Status
  (`updateProjectV2ItemFieldValue`). Só escreve quando a coluna muda. Item que não
  é issue (rascunho, PR solta) é ignorado.
- `quadro criar <dir>`: copia o board modelo (`copyProjectV2`) para a conta dona do
  repo da fila, com o nome do repo, liga esse repo ao board
  (`linkProjectV2ToRepository`), cria a label `investigando` se faltar e grava a URL
  em `quadro` no `ficha.json` (cria o arquivo com só esse campo se não existir).
- `quadro modelo`: cria o board modelo pela API (`createProjectV2` e o campo Status
  com as sete opções, na ordem acima) e imprime o número, que vira constante no
  `quadro`.
- Colunas casam com as opções do Status pelo nome exato, acentos incluídos. Falta
  de opção, do escopo `project` ou de acesso: chamado pela `fila`, o `sync` avisa e
  sai 0; chamado à mão, e no `criar`, sai com erro claro.

### Board modelo

Da conta `raphael-soares`. O dono liga na tela, uma vez, os workflows nativos
"Item closed" e "Pull request merged" levando a Feita: a API não tem mutation para
workflow, e `copyProjectV2` copia o modelo com eles. Sem auto-add: o `sync` já põe
a issue no board.

### `fluxo-desvio`

Os campos do contrato do portão (`portao`, `rapido`, `prova`, `risco`,
`nao_se_aplica`, `pendente`, `extras`) só são cobrados de repo que declara
`portao`. Repo com `ficha.json` sem `portao` e sem `repos` é de gestão leve:
exige `fila` e `integracao`, aceita `quadro`, e não passa pela verificação do
portão nem pela exigência de workflow chamar `scripts/portao`. O `ficha.json`
da TEAjudo não muda (decisão do dono).

### `ficha.json`

Campo novo opcional `quadro`: URL do Project. Documentado em `ai/docs/portao.md`.
Repo pessoal com fila declara no mínimo `fila` e `integracao`.

### Fila

A `fila` chama `quadro sync <dir> <N>` depois de cada mudança de estado: pegar a
issue (`em-execucao`), detectar as PRs abertas que a sessão criou (depois de
`prs_da_issue(..., "open")` em `processar`), passar ao dono (`dono()`), retomar,
mesclar (`concluir`) e fechar (`fechar()`). Falha do `quadro` vira aviso no log e a
fila segue.

### Sessões interativas

Regra no `RULES.md`, seção Superpowers: ao começar `discussao` ou `brainstorming`
sobre uma issue de repo com board, ponha a label `investigando`; ao implementar
interativamente, troque por `em-execucao`; depois de cada troca rode
`quadro sync . <N>`. A PR aberta e o fechamento seguem a tabela sozinhos.

### Teste

A regra de coluna é função pura, com teste em `ai/tests/test_quadro.py` no padrão
de `ai/tests/test_fila.py`: precedência da tabela, PR mesclada com issue aberta e
PR fechada sem merge.

## Calls do agente

- Coluna calculada, nunca gravada à parte (evita divergência).
- Board é do repo da fila, mesmo em projeto multi-repo.
- PR mesclada com issue aberta fica em Revisão; fechada sem merge não conta.
- Falha do `quadro` não bloqueia a fila.
- Modelo criado pela API; só os dois workflows nativos são na tela.
- Python e `gh`, no padrão da `fila`.

## Fica para quem implementa

- Consulta GraphQL exata e paginação.
- Mensagens de log e saída do `quadro`.
- Como achar o item de uma issue no board.
