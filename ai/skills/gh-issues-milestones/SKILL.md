---
name: gh-issues-milestones
description: Use when creating, editing, moving, splitting or closing GitHub issues and milestones with gh in any repo that organizes work by milestone; empty milestone filter, duplicated issue after batch, stale issue bodies.
---

# Issues e milestones pelo gh

A convenção (título `NN. Nome`, sufixo `17a.`, `00. Saúde técnica`, descrição de
uma frase) está na seção Milestones das regras fixas. Esta skill é o como fazer.
Repo com skill própria de issues (prefixo do `ficha.json`) soma as regras dela a
estas.

## O estado mora no GitHub

Fila, ordem e dependências ficam na descrição de cada milestone e nas
dependências nativas das issues. Nunca copie a lista de milestones para skill,
doc ou memória: ela envelhece no primeiro merge. Antes de decidir onde uma issue
entra, consulte:

```bash
gh api "repos/<dono>/<repo>/milestones?state=open&per_page=100" \
  --jq 'sort_by(.title)[] | "\(.number)\t\(.title)\t\(.description)"'
```

O número interno (`.number`, usado na API e na URL) difere do número do título.
`gh issue list --milestone "<título com acento>"` pode voltar vazio sem erro:
liste as issues pela API com o número, `issues?milestone=<n>&state=all`. Logo
depois de fechar ou mover, a lista e os contadores da milestone ainda mostram o
estado antigo por alguns segundos.

## Procedimento

1. **Milestone.** Criar: `gh api -X POST repos/<dono>/<repo>/milestones -f title=... -f description=...`,
   depois de procurar o título exato em `milestones?state=all`. Renomear ou
   fechar: `PATCH .../milestones/<n> -f title=... -f state=closed`. Milestone sem
   issue aberta se fecha.
2. **Criar issues.** Corpo sempre por `--body-file` (ou stdin), nunca inline.
   Milestone na criação: `gh issue create --milestone "<título>"`.
   - Lote: torne o script idempotente (procure pelo título exato antes de
     criar) e use timeout alto. Interrompido no meio? Liste as issues recentes
     antes de repetir: a última pode ter sido criada sem devolver a URL.
   - Issues que se citam: crie todas, depois um segundo passe de
     `gh issue edit --body-file` com os números já conhecidos.
   - Antes de criar, procure issue com o mesmo assunto, inclusive fechada.
3. **Dependência é nativa:** `gh issue edit N --add-blocked-by M`, não só no
   texto. Duas issues que tocam o mesmo arquivo ganham dependência para fixar a
   ordem.
4. **Editar corpo existente.** Leia com `gh issue view N --json body --jq .body`,
   confira `body.count(antigo) == 1` antes do `replace` e grave com
   `--body-file`. Sem a conferência, troca o trecho errado ou não troca nada em
   silêncio.
5. **Dividir milestone.** Renomeie a original para a primeira parte (o número
   interno e o histórico das fechadas ficam com ela) e crie as outras com sufixo
   (`20a`, `20b`...). Para cada issue que muda de parte, num passe só:
   - título: `[NN.k]` vira o código novo (`[20.6]` vira `[20b.1]`);
   - corpo: as citações `#n [NN.k]` das issues movidas e qualquer link para a
     milestone antiga passam a apontar para a parte nova;
   - `gh issue edit --milestone "<título novo>"`.
   Issue fechada não muda de título. No fim, procure `\[NN\.\d+\]` nos corpos
   abertos: sobra só citação de fechada.
6. **Plano abandonado** (issues citam branch, onda ou passo que a execução
   pulou). Meça a realidade (`issues?milestone=<n>&state=all` contra o código
   no branch remoto), discuta com o dono e só então: feche como `not planned`
   o passo que não existe, levando o critério de pronto para a issue que fica;
   reescreva os corpos abertos; reescreva a descrição da milestone.
7. **Fechar.** `gh issue close N --reason completed|"not planned" --comment "..."`
   citando a PR ou o commit. Duplicata ganha a label `duplicate`. `Closes #N` de
   PR em outro repo não fecha a issue: cite `<dono>/<repo>#N` e feche à mão.

## Verificação

- A lista de milestones abertas, ordenada por título, bate com a fila decidida.
- `issues?milestone=none&state=open` (sem PRs) só traz o que a regra do repo
  aceita sem milestone.
- Dependências: `gh issue list --search "is:open is:blocked"` traz só issues com
  bloqueador aberto.
- Corpos abertos sem travessão, meia-risca ou placeholder.
