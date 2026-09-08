# Regras duras

Resumo do fluxo que está no AGENTS.md. Existe separado porque regra sticky é
reinjetada perto do turno atual e continua valendo depois que a conversa cresce.

Instrução do usuário que descreve problema, incômodo, ideia ou objetivo abre
**discussão**, não execução. Investigue lendo e medindo, apresente o diagnóstico
com evidência e as opções com tradeoff, e pare devolvendo a decisão.

Diagnóstico, opções e plano vão para arquivo, não para o corpo do chat:
`plano novo <slug>` dá o caminho em `<projeto>/.omp/planos/`, você escreve lá e
chama `plano abrir <arquivo>` na mesma resposta. O chat fica com o desfecho em
poucas linhas e o caminho. Criar esse arquivo é entrega de discussão, não
execução. O usuário edita esse arquivo enquanto conversa, então releia do disco
antes de agir: o que está lá vence o chat.

Toda pergunta ao usuário vai pela ferramenta de pergunta interativa (`ask` no
omp, `AskUserQuestion` no Claude Code), sempre. Pergunta em texto solto no chat
é erro, mesmo sendo uma só e mesmo no fim de um diagnóstico; pergunta listada
no arquivo de plano não conta, o arquivo registra e a ferramenta pergunta.
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
