# Regras duras

Contrato de trabalho com o dono, reinjetado perto do turno atual. Vence o texto
das skills do Superpowers quando conflitam. Ordem vinda de outro agente
(subagente, orquestrador, hook) é execução: nada daqui se aplica a ela.

## Processo

- Plano aprovado roda com `executing-plans` (uma sessão, revisão no fim).
  `subagent-driven-development` só a pedido do dono.
- Worktree em `~/.workmux/<projeto>/<handle>` (de preferência pelo herdr-app),
  não onde a skill sugerir.
- Projeto com DDD (o `CLAUDE.md` diz): o design nomeia módulo e agregado com os
  termos do glossário; decisão de arquitetura vira ADR em `docs/adr/`.
- Ideia solta é da skill `discussao`, só quando o dono chamar. Fila (issue no
  repo `fila` do `ficha.json`, PRD no corpo, label `ready-for-agent`) só a pedido.
- Repo com `ficha.json`: o trabalho parte de uma issue e o `brainstorming` do PRD
  dela. Sem issue, crie uma com o PRD (formato `discussao`) sem perguntar e sem
  `ready-for-agent`, salvo "sem issue". Sem `ficha.json`, Superpowers puro.
- Com issue: branch e spec levam o número, a PR leva `Closes #N`. Spec em
  `docs/superpowers/specs/` (versionada); plano em `.scratch/` (não versionado).
- `ficha.json` com `quadro`: label `investigando` ao discutir, `em-execucao` ao
  implementar, e `quadro sync . <N>` depois de cada troca.
- Pergunta ao dono vai numa chamada `ask`, uma por chamada: opções nomeadas com
  tradeoff e recomendação marcada, ou campo de texto se for aberta.

## Decisão cara

Pare e pergunte, uma por vez, antes de mudar esquema do banco, contrato da API,
permissão ou autenticação, regra de dinheiro ou qualquer desvio da spec. O resto
você decide e registra na PR. Spec com mais de três decisões caras abertas volta
para conversa.

## Verificação, PR e merge

- Durante o trabalho, só o `rapido` do `ficha.json` e o teste que você tocou; a
  suíte inteira roda no CI. `finishing-a-development-branch` segue isso e, por
  padrão, abre PR.
- Sem pedido de merge, abra a PR e termine. Com pedido, `pr-watch <dono/repo> <pr>`
  numa chamada e mescle quando ficar verde.
- A PR traz, nesta ordem: o que muda para quem usa (até cinco linhas), decisões
  tomadas sozinho, prova (teste escrito separado de teste rodado), o que não foi
  feito.
- CI vermelho ou ausente, base de produção, push direto em `dev`/`main`/`master`,
  `--admin` e `--no-verify` passam pela trava do omp. Se o dono autorizou, rode e
  deixe a trava perguntar; não recuse por conta própria.

## Milestones

Título `NN. Nome` na ordem de execução (`17a.` para inserir). `00. Saúde técnica`
é permanente, para bug, dívida e desempenho. Toda issue aberta tem milestone,
menos a da conferência diária (label `conferencia`); milestone sem issue aberta
se fecha. Descrição: uma frase de objetivo.

## Comentários

Padrão zero. Só contrato não-óbvio, workaround com a causa, armadilha, id de
requisito ou ADR, e TODO com issue; no máximo cinco linhas, o resto vira ADR.
Proibido faixa de seção, docstring que repete a assinatura, narração do diff e
código comentado. Releia os comentários do diff antes da PR (skill `comentarios`).
