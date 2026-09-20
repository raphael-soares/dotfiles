---
name: comentarios
description: Escrever, revisar ou apagar comentário de código (inline, docstring, JSDoc, Javadoc, comentário de template) com orçamento por categoria e teto de linhas. Use ANTES de escrever ou alterar qualquer comentário, ao revisar código cheio de comentário, e na revisão final do card antes de abrir PR.
---

# Comentários

O padrão é zero. Comentário é dívida que se paga em três moedas: token em toda leitura
do arquivo, ruído pra quem lê o código e mentira quando o código muda e ele fica. A
pesquisa é consistente nisso: até metade das mudanças de comentário acontece descolada
do código, e comentário desatualizado atrapalha mais do que comentário nenhum.

## Os dois testes, antes de escrever

1. **Dá pra escrever esse comentário só lendo a linha de baixo?** Então apaga. Se o
   código precisa de explicação pra ser entendido, o conserto é nome melhor ou função
   extraída, não comentário.
2. **Isso é sobre o código ou sobre a decisão?** Decisão (por que escolhemos assim, o
   que foi descartado, que restrição do negócio mandou) é ADR. No código fica o id.

## As cinco categorias, e só elas

| Categoria | Exemplo | Teto |
|---|---|---|
| Contrato não-óbvio | `Tempo em ms. Fim exclusivo. Quem chama fecha o stream.` | 3 linhas |
| Workaround | `Vuetify 3.9 não emite update:modelValue em select múltiplo vazio (issue #19842).` | 3 linhas |
| Armadilha | `Itera de trás pra frente: splice no meio reindexa o resto.` | 2 linhas |
| Rastreabilidade | `REQ-AUD-08`, `ADR-0012` | 1 linha |
| TODO com dono | `TODO(#123): trocar quando o endpoint de lote existir.` | 1 linha |

Contrato só em API que outro módulo consome. Função interna não ganha docstring.
Workaround sem a causa nomeada não é workaround, é desculpa: conserta o código.

Nenhum bloco passa de cinco linhas, em nenhum arquivo, nem no topo.

## Ruim -> bom

| Ruim | Bom |
|---|---|
| `<!-- Diálogo de confirmação de exclusão -->` sobre `<ConfirmDialog>` | nada |
| `<!-- 9. Diálogo de Detalhes da Priorização (REQ-AUD-05) -->` | `<!-- REQ-AUD-05 -->` |
| `// ===== Computed =====` | nada |
| `/** Retorna o total da guia. */` sobre `obterTotal()` | nada |
| `// agora também trata o caso de lista vazia` | nada, o diff já mostra |
| `// gambiarra: o backend devia mandar isso pronto, mas por enquanto...` | conserta, ou `TODO(#id)` de uma linha |
| 23 linhas explicando por que a ordem das chamadas é essa | `// Ordem obrigatória: ADR-0012.` mais o ADR |

## Ensaio vira ADR

Passou de cinco linhas, o texto sai do código e vira `docs/adr/NNNN-slug.md` no formato
padrão (contexto, decisão, consequências). No código fica uma linha com o id. Projeto
sem `docs/adr/`, crie a pasta junto com o ADR; projeto que guarda decisão em outro lugar,
use o lugar dele. O que já está escrito na spec do projeto não vira ADR: cita o id do
requisito.

Ganho: quem lê o código não paga o texto, quem quer a decisão acha ela inteira, e o
histórico fica versionado num arquivo que não some numa refatoração.

## Docstring, JSDoc e Javadoc

Existem pra quem **usa** o símbolo sem abrir o corpo dele, e dizem só o que a assinatura
não diz: unidade, nulo, limite, efeito colateral, exceção que o chamador trata, quem
libera o recurso. Nunca descrevem a implementação, e nunca repetem o nome do método em
prosa. Em símbolo interno, o padrão continua sendo zero.

## Comentário em teste

O nome do teste é a documentação (`deveRejeitarDivisaoPorZero`). Comentário em teste só
quando o cenário é não-óbvio: um dado de fixture com valor estranho que existe por um
motivo, um `sleep` que existe por causa de relógio. Faixa `// Arrange`, `// Act`,
`// Assert` não entra: a linha em branco já separa os três blocos.

## Idioma e forma

Comentário em pt-BR, como o resto do código, salvo repo cujo código já está em inglês:
aí segue o repo. Frase direta, minúscula quando é continuação, sem travessão, sem emoji,
sem citar o agente, o prompt ou o card.

## A revisão, antes de abrir PR

Na revisão final do card, liste os comentários que o **seu** diff adicionou:

```bash
git diff <base>...HEAD -U0 | grep -E '^\+[[:space:]]*(//|/\*|\*|#|<!--)'
```

Pra cada linha: cai numa das cinco categorias? Não, apaga. O bloco passou de cinco
linhas? Vira ADR. Sobrou comentário descrevendo código que você reescreveu? Atualiza ou
apaga, porque comentário errado é pior que ausente.

## Erros que se repetem

- Traduzir o código pra português em cima dele.
- Faixa de seção pra organizar arquivo grande. O conserto é dividir o arquivo.
- Docblock de boas-vindas no topo de todo arquivo novo.
- Explicar a alternativa descartada dentro do código.
- Deixar comentário velho descrevendo o comportamento antigo depois de mudar a função.
- `TODO` sem issue, que ninguém vai achar de novo.
