---
name: questionario
description: Use quando o dono pedir questionário, sabatina, "me pergunta", "me testa", treino para prova ou revisão com perguntas uma por vez, em qualquer disciplina da faculdade.
---

# Questionário: uma pergunta por vez, com repetição do que errou

Sessão de treino interativa. Cada pergunta vai numa chamada `ask`, a resposta é
corrigida na hora, e o que ele errar volta mais tarde com outra cara até ele
acertar.

## Antes da primeira pergunta

1. Descubra a disciplina e o escopo pelo diretório (`~/Udesc/<disciplina>`):
   `README.md`, resumo da prova (`provas/pN/1-resumo.*`), aulas, slides. Não
   pergunte o que dá para ler.
2. Se existir `estilo-<professor>.md` nesta pasta para a disciplina, siga-o.
   Sistemas Operacionais (Marisangila Alves): `estilo-marisangila.md`.
3. Leia os simulados e gabaritos que existirem só para **não repetir** as
   questões deles: o simulado é treino que ele ainda vai fazer.
4. Crie o estado em `.scratch/questionario.md` na raiz da disciplina (sobrevive
   à compactação da conversa):

```
# Questionário <disciplina>, <data>
Escopo: <temas>
Feitas: 0  Acertos: 0
## Fila de retorno
- volta na pergunta 7: conceito "TLB x tabela de páginas" (errou na 3, trocou abrangência)
## Histórico
- 1 concorrência, V/F, 8/8
```

A primeira chamada `ask` diz em uma linha como funciona e já traz a pergunta 1.

## Cada pergunta

Formato da chamada `ask`:

- `<legend>`: "Pergunta N (tema)" e o enunciado no estilo do professor.
- Uma alternativa certa: `radio` com `name="r"` e as letras como `value`.
- V/F, relacionar colunas ou "quais são verdadeiras" com vários itens: os itens
  num `<p>` ou `<pre>`, e a resposta num `<input type="text">` com o formato no
  `placeholder` (`V F F V ...` ou `4,1,3,5,2`).
- Nunca marque alternativa com `checked`: a resposta padrão seria a certa ou
  enviesaria.

Varie tema e formato. Não faça duas seguidas do mesmo tema, salvo se ele pedir
um tema só.

## Correção, na mesma resposta da pergunta seguinte

Corrija em texto curto e mande a próxima pergunta na mesma vez (texto da
correção antes, chamada `ask` em seguida). A correção tem, nesta ordem:

1. Certo ou errado, e a resposta certa.
2. Para cada item errado: por que é falso, nomeando o conceito vizinho cuja
   definição foi trocada ("isso é a latência rotacional, não o seek").
3. Uma frase para fixar a diferença, só quando ele errou.

Acerto não ganha explicação longa: "Certo." e a próxima. Atualize o arquivo de
estado a cada resposta.

## Repetição do que errou

- Errou qualquer item: o **conceito** entra na fila de retorno para voltar 3 a
  5 perguntas depois.
- Quando voltar, mude a forma: outro formato, outra frase, o conceito vizinho
  no lugar. Repetir a mesma pergunta só testa memória da frase.
- Acertou no retorno: sai da fila. Errou de novo: volta outra vez, mais perto
  (2 a 3 perguntas depois).
- Pergunta da fila tem prioridade sobre conteúdo novo quando chega a vez dela.

## Fim

A sessão acaba quando ele pedir, ou quando o escopo estiver coberto e a fila
vazia. Feche com: acertos sobre total, os conceitos que precisaram de mais de
uma volta, e qual aula ou capítulo do resumo rever para cada um. Apague
`.scratch/questionario.md`.

## Erros comuns

| Erro | Certo |
|---|---|
| Mandar várias perguntas de uma vez | Uma por chamada `ask` |
| Pergunta em texto solto no chat | Sempre `ask` |
| Item falso absurdo, fácil de descartar | Item falso que troca a definição pelo conceito vizinho |
| Conta, código ou simulação longa quando a prova é teórica | Conceito, comparação e erro comum |
| Copiar questão do simulado | Questão nova sobre o mesmo conceito |
| Errou e a mesma frase volta igual | Conceito volta com outra forma |
| Explicar demais o acerto | "Certo." e segue |
