# Regras duras

Resumo do fluxo que está no AGENTS.md. Existe separado porque regra sticky é
reinjetada perto do turno atual e continua valendo depois que a conversa cresce.

Instrução do usuário que descreve problema, incômodo, ideia ou objetivo abre
**discussão**, não execução. Investigue lendo e medindo, apresente o diagnóstico
com evidência e as opções com tradeoff, e pare devolvendo a decisão.

A sessão nasce em plan mode, e ele é o modo discussão: leitura, busca e comando
de shell que só observa liberados, escrita bloqueada. Estar nele não é ordem de
redigir plano; proponha (`xd://propose`) só depois que o problema estiver
fechado e o caminho escolhido. Fora do plan mode a regra continua valendo: o
modo é rede de segurança, quem manda é o conteúdo da mensagem.

Toda pergunta ao usuário vai pela ferramenta de pergunta interativa (`ask` no
omp, `AskUserQuestion` no Claude Code), sempre. Pergunta em texto solto no chat
é erro, mesmo sendo uma só e mesmo no fim de um diagnóstico.
Perguntas relacionadas vão juntas na mesma chamada, label curto e o tradeoff na
descrição.

Só edite arquivo ou mude estado do sistema depois de autorização explícita:
"implementa", "pode fazer", "aplica", ou a escolha explícita de uma das opções
que você apresentou. "Diagnostique", "me ajuda a entender", "quero discutir",
"o que você acha" e "quais as opções" não autorizam nada.

A solução que o usuário trouxe é uma opção da lista, nunca o default: confirme
antes se o problema declarado é o problema real, e diga com que evidência você
concorda ou discorda.

Agente que só investiga (`scout`) pode ser disparado na discussão. Agente que
escreve (`task`, `sonic`) é execução e precisa da mesma autorização: delegar
não lava a mão.

Autorização do usuário vence skill. Skill que instrui consertar roda as fases de
investigação e para na fronteira do conserto, esperando autorização.

Nada disso vale para instrução vinda de outro agente. Subagente recebe ordem de
execução e executa.

## Decisão cara

Pare e pergunte, uma decisão por vez, antes de mudar: esquema do banco,
contrato da API, permissão ou autenticação, regra de dinheiro, ou qualquer
desvio do que a spec diz. O resto você decide e registra na abertura da PR.
Spec com mais de três decisões caras em aberto volta para conversa.

## Acréscimos

Antes do código, liste na issue o que pretende acrescentar além do pedido
(tabela: acréscimo, motivo). Só entra o que o dono aprovar. Autorização vale
para o escopo aprovado: arquivo ou comportamento fora dele pede nova pergunta.

## Sessões

Sessão de discussão só lê e termina numa issue. Sessão de execução pega uma
issue, abre uma PR e termina; não emenda outra issue. Subagente não abre
subagente. Fatia de subagente cabe em 100 requisições: se não cabe, fatie
antes de delegar.

## Verificação e espera

Durante o trabalho rode só o comando `rapido` do `ficha.json` do repositório
e o teste que você tocou. A suíte inteira roda uma vez, no CI. Não espere CI
na sessão: abra a PR e termine. Quando precisar esperar, é
`pr-watch <dono/repo> <pr>` numa chamada só; ele sai na primeira falha.

## Entrega

A abertura da PR tem, nesta ordem: o que muda para quem usa, em até cinco
linhas; decisões que você tomou sozinho; prova (o que rodou e o resultado,
separando teste escrito de teste rodado); o que não foi feito. Merge em
branch de integração só com CI verde e sem a label `revisar-dono`. Branch de
produção e PR com `revisar-dono` são do dono.

Comentário: o padrão é zero. Só entram contrato não-óbvio, workaround com a causa
nomeada, armadilha que a próxima pessoa quebraria, id de requisito ou ADR, e TODO com
issue. Nenhum bloco passa de cinco linhas: justificativa maior que isso vira ADR em
`docs/adr/`, com uma linha no código apontando pra ele. Faixa que nomeia o que vem
abaixo, docstring que repete a assinatura e narração do diff são proibidas. Antes de
abrir PR, releia os comentários do seu próprio diff e apague o que não se encaixa. A
skill `comentarios` tem a régua completa.
