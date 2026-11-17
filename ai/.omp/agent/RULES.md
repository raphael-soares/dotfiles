# Regras duras

Contrato de trabalho com o dono. Fica aqui, e não no AGENTS.md, porque regra
sticky é reinjetada perto do turno atual e continua valendo quando a conversa
cresce. Instrução vinda de outro agente (subagente, orquestrador, hook) é ordem
de execução: nada daqui se aplica a ela.

## Superpowers

O processo de trabalho vem do plugin Superpowers. Estas regras são preferências
do dono e vencem o texto das skills dele quando os dois conflitam.

- Plano aprovado se executa com `executing-plans`: uma sessão e uma revisão no
  fim. `subagent-driven-development` só quando o dono pedir, porque cada
  subagente refaz contexto e gasta cota.
- Worktree vai sempre em `~/.workmux/<projeto>/<handle>` (AGENTS.md), não no
  caminho que a skill sugerir.
- `finishing-a-development-branch` não roda a suíte inteira local: roda o que
  "Verificação e espera" manda. Das saídas que ele oferece, o padrão é abrir PR.
- Em projeto com DDD (o `CLAUDE.md` dele diz), o design nomeia o módulo e o
  agregado que toca e usa os termos do glossário do projeto. Decisão de
  arquitetura que sair do design vira ADR em `docs/adr/`.
- Ideia solta, que ainda não se sabe se vira código, é da skill `discussao`, e
  só quando o dono chamar.
- Mandar trabalho para a fila só quando o dono pedir: issue no repositório
  `fila` do `ficha.json`, com o design aprovado no corpo e a label
  `ready-for-agent`.

## Decisão cara

Pare e pergunte, uma decisão por vez, antes de mudar: esquema do banco,
contrato da API, permissão ou autenticação, regra de dinheiro, ou qualquer
desvio do que a spec diz. O resto você decide e registra na abertura da PR.
Spec com mais de três decisões caras em aberto volta para conversa.

## Verificação e espera

Durante o trabalho rode só o comando `rapido` do `ficha.json` do repositório
e o teste que você tocou. A suíte inteira roda uma vez, no CI. Sem pedido de
merge, não espere CI: abra a PR e termine. Quando o dono pedir merge, espere
com `pr-watch <dono/repo> <pr>` numa chamada só (ele sai na primeira falha) e
mescle quando ficar verde.

## Entrega

A abertura da PR tem, nesta ordem: o que muda para quem usa, em até cinco
linhas; decisões que você tomou sozinho; prova (o que rodou e o resultado,
separando teste escrito de teste rodado); o que não foi feito. Merge em
branch de integração com CI verde é seu quando o dono pedir. CI vermelho ou
ausente, base de produção, push direto em `dev`/`main`/`master`, `--admin` e
`--no-verify` passam pela trava do omp, que pergunta ao dono na hora. Se o
dono autorizou na conversa, rode o comando e deixe a trava perguntar; não
recuse por conta própria.

## Comentários

O padrão é zero. Só entram contrato não-óbvio, workaround com a causa nomeada,
armadilha que a próxima pessoa quebraria, id de requisito ou ADR, e TODO com
issue. Nenhum bloco passa de cinco linhas: justificativa maior que isso vira ADR
em `docs/adr/`, com uma linha no código apontando pra ele. Faixa que nomeia o
que vem abaixo, docstring que repete a assinatura, narração do diff e código
comentado são proibidos. Antes de abrir PR, releia os comentários do seu diff e
apague o que não se encaixa. A skill `comentarios` tem a régua completa.
