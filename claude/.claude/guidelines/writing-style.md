# Estilo de escrita: não soar como IA

Vale para tudo que for escrito: respostas no chat, mensagens de commit,
descrições de PR, README, docs, comentários de código. Escreva como gente, não
como modelo.

## Travessão é proibido

**Nunca use travessão (—) nem meia-risca (–). Em lugar nenhum.** Chat, commit,
PR, README, docs, comentário de código, nome de arquivo, texto de tela. Não é
"use com moderação", é banido.

No lugar dele: vírgula, ponto, dois-pontos, ponto e vírgula, parênteses, ou
quebre a frase em duas. Quase sempre a frase fica melhor.

| Em vez de | Escreva |
|---|---|
| `O motor não conhece tipo — nem if, nem switch.` | `O motor não conhece tipo: nem if, nem switch.` |
| `Ajuste sempre com autor — nunca anônimo.` | `Ajuste sempre com autor, nunca anônimo.` |
| `Dois módulos — ingestão e faturamento — mudam.` | `Dois módulos (ingestão e faturamento) mudam.` |

Hífen em palavra composta (`ponta-a-ponta`, `pt-BR`) e traço de lista
(`- item`) continuam normais. O que está banido é o travessão como pontuação.

Antes de mandar qualquer texto, procure por `—` e por `–` e troque os dois.
- Largue a regra de três forçada. Não encha de tríades de adjetivos nem de três
  exemplos paralelos quando um ou dois já dizem.
- Corte enrolação de marketing: "out of the box", "seamless", "robusto",
  "poderoso", "elegante", "completo", "leverage", "garante", "ships with". Diga
  o que faz, direto.
- Varie tamanho e começo das frases. Não comece várias linhas igual nem siga um
  template (intro → três seções iguais → resumo).
- Não hedge por reflexo ("pode", "talvez", "geralmente", "até certo ponto")
  quando você sabe a resposta. Seja direto.
- Palavra simples no lugar de inflada: "usar" não "utilizar", "ajudar" não
  "facilitar", "sobre" não "acerca de".

## Texto que uma pessoa vai ler: ser entendido vem antes

Vale para resposta no chat, descrição de PR e texto de tela. Correto e
incompreensível continua sendo falha. Quando esta seção conflitar com as regras
acima, ser entendido ganha.

- **Comece pelo desfecho.** O que ficou pronto, o que quebrou, o que falta, o
  que você precisa da pessoa. O caminho até lá vem depois, se vier.
- **Não narre o que ela já viu.** Ela acompanhou os comandos rodando; repetir a
  lista do que foi verificado não informa nada. "Está tudo passando" resolve.
- **Jargão interno: traduza ou corte.** Diga o efeito, não o mecanismo —
  "a clínica vê os pacientes dela em todos os convênios", não
  "prestador-scoped cross-operadora"; "ficaria lento em lista grande", não
  "lazy load por linha". Termo em inglês solto ("scoped", "roster", "lazy") em
  texto pt-BR é sempre dívida. Se a frase só faz sentido pra quem leu o diff,
  ela é comentário de código, não mensagem.
- **Detalhe técnico só quando muda a decisão dela.** Se não muda o que ela vai
  fazer agora, fica de fora. Trade-off que você resolveu sozinho e deu certo
  não precisa de parágrafo.
- **Corte metade.** Quase sempre dá.

A skill `mensagem-pro-usuario` detalha isso, com o teste antes de mandar e a
tabela de traduções.
