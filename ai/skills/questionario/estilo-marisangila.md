# Estilo da prof. Marisangila Alves (Sistemas Operacionais, UDESC)

Base: prova real de 16/10/2024 (`provas/p1/fontes/4-prova-antiga.typ`). Prova
sempre teórica: sem conta, sem código para escrever, sem simulação longa.

## Formatos, com a frase de abertura dela

| Formato | Enunciado | Resposta |
|---|---|---|
| Relacionar | "Relacione as definições a seguir com seus respectivos conceitos:" 5 conceitos numerados e 5 definições com `( )` embaralhadas | sequência de números |
| V/F | "Assinale V para as afirmações verdadeiras e F para as falsas:" 6 a 8 itens `a.` a `h.` | `V F F V ...` |
| Afirmativas I a V | "Quais das seguintes afirmações são verdadeiras?" ou "Quais das seguintes opções são falsas?", às vezes "...quanto a <assunto>?" | alternativas a) a e) com combinações ("II, IV e V.") |
| ENADE ou POSCOMP | "*ENADE 2017* - " + parágrafo citando Tanenbaum ou Oliveira, depois "De acordo com o exposto, ..." | 5 alternativas curtas |
| Figura | "Complete a figura..." | no questionário, troque por descrever o fluxo em texto |

Alterne entre pedir as verdadeiras e as falsas: ela faz as duas, e isso pega
quem lê rápido.

## Como ela monta os itens falsos

- Troca a definição de um conceito pela do vizinho (seção crítica e exclusão
  mútua; seek e latência; FIFO e LRU).
- Absolutos: "apenas", "exclusivamente", "todo tipo de", "nunca", "sempre".
- Inverte comparação: "consome mais recursos do que", "tem mais privilégios que".
- Exemplo errado colado em definição certa: "`fork()`, utilizado para escrever
  em um arquivo".
- Afirmação incompleta tratada como completa: "inclui apenas os estados novo,
  pronto, execução e terminado".

Os verdadeiros são frases de livro, diretas, às vezes com o termo em inglês em
itálico (_thread_, _hardware_, _timesharing_).

## Fontes do conteúdo

Escopo da P2: Oliveira caps. 3, 5, 6 e 7 (concorrência e IPC, entrada e saída,
memória física, memória virtual). Não cai: sistema de arquivos, virtualização,
escalonamento de processos. Escalonamento de disco cai. Termos e definições:
`provas/p2/1-resumo.pdf` e as aulas em `provas/p2/aulas/fontes/`. Onde o slide
dela e o Oliveira divergem (E/S mapeada em memória x espaço de E/S), siga o
Oliveira e avise na correção que o slide troca as descrições.
