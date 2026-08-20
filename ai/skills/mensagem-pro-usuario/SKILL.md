---
name: mensagem-pro-usuario
description: Escrever ou revisar texto que uma pessoa vai ler — resposta de fim de tarefa, descrição de PR, mensagem de tela, e-mail, release note — em português simples, sem jargão interno. Use antes de mandar qualquer texto longo pro usuário, ao escrever corpo de PR, e ao criar ou revisar copy de UI. Não vale pra código, commit ou comentário.
---

# Mensagem pro usuário

Texto que uma pessoa lê tem um trabalho: ela entender de primeira. Se ela precisa reler, ou parar
pra decifrar uma palavra, o texto falhou — não importa se cada frase estava tecnicamente correta.

Esta skill é sobre **ser entendido**. A `writing-style` das guidelines é sobre **não soar como IA**.
As duas valem juntas; quando conflitarem, ser entendido ganha.

## O teste, antes de mandar

Leia como se fosse a outra pessoa e responda:

1. **Responde o que ela perguntou?** Se ela perguntou "terminou?", a primeira linha diz se terminou.
2. **Ela conhece todas as palavras?** Toda palavra que só existe dentro do código é dívida.
3. **Dá pra cortar metade?** Quase sempre dá. Corte.

Falhou em qualquer uma, reescreve.

## Comece pelo resultado, não pelo caminho

A primeira linha é o desfecho: o que ficou pronto, o que quebrou, o que falta, o que você precisa
dela. O caminho até lá vem depois, se vier.

| Ruim | Bom |
|---|---|
| "Investiguei o service, li o repositório e descobri que a query não filtrava..." | "O relatório mostrava paciente de outro convênio. Corrigido." |
| "Rodei type-check, lint e a suíte, todos limpos, e o build gerou a rota nova." | "Está tudo passando." |

Ela viu você trabalhando. Não narre de novo o que já apareceu na tela.

## Jargão: traduza ou corte

O termo interno entra só quando é o nome real da coisa **pra ela** — o que aparece na tela dela, no
contrato, no ticket. Fora disso, diga o efeito.

| Jargão | O que dizer |
|---|---|
| "prestador-scoped cross-operadora" | "a clínica vê os pacientes dela em todos os convênios" |
| "vai dar lazy load por linha" | "ficaria lento em lista grande" |
| "`??` só pega null e undefined" | "campo vazio passava batido" |
| "o squash colapsa no título do PR" | "no histórico vai aparecer só o título do PR" |
| "roster do prestador" (em tela) | "lista do prestador" |
| "DataIntegrityViolation vira 409" | "o cadastro falhava com erro de duplicado" |

Regra prática: se a frase só faz sentido pra quem leu o diff, ela é comentário de código, não
mensagem.

## Detalhe técnico só quando muda a decisão dela

Antes de explicar um detalhe, pergunte: **isso muda o que ela vai fazer agora?**

- Muda → uma linha, com o termo traduzido. ("Mergeie a api antes do front, senão a tela quebra.")
- Não muda → fora. O detalhe vive no código, no comentário, no corpo do commit.

Trade-off que você resolveu sozinho e deu certo não precisa de parágrafo. Basta a decisão.

## Tamanho

- **Resposta de chat:** o desfecho, e só o que ela precisa decidir. Se passou de uma tela, corte.
- **Descrição de PR:** o problema, a decisão e como verificar. Quem revisa lê o diff pro resto.
- **Texto de UI:** a frase mais curta que a pessoa entende sem contexto nenhum. Zero vocabulário
  interno — quem lê é o cliente, não o time.

## Formatação

Serve pra escanear, não pra decorar. Título e lista quando há itens de verdade; prosa quando é
raciocínio. Não transforme duas frases em tabela. Não use negrito em frase inteira.

## Erros que se repetem

- Recapitular o que ela acabou de ver acontecer.
- Listar tudo que foi verificado, quando "está passando" resolve.
- Explicar a alternativa que você descartou, sem ela ter perguntado.
- Termo em inglês solto ("scoped", "roster", "lazy", "snapshot") em texto pt-BR.
- Enterrar o que ela precisa fazer no fim do terceiro parágrafo.
- Pedir desculpa e explicar o erro em detalhe, em vez de dizer o que ficou consertado.
