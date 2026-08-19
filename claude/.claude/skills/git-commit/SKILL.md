---
name: git-commit
description: Generate or review a git commit message (or PR title) using Conventional Commits tuned for release-please, so versions bump correctly and the CHANGELOG stays clean. Use this BEFORE every git commit, whenever writing a commit message, or when titling a pull request, in any repo that uses release-please or Conventional Commits. Takes precedence over caveman-commit.
---

# git-commit — commits que o release-please ama

Repos que usam **release-please** geram a versão e o `CHANGELOG.md` a partir do
histórico de commits. **O commit é o input; a release é o output.** Um commit
ruim = versão errada + changelog ruim, em silêncio. Mesmo sem release-please, o
formato abaixo mantém o histórico legível.

> Esta skill **substitui** a `caveman-commit` ao commitar: aqui o corpo do commit
> é informação útil, não ruído a cortar.

Se o `CLAUDE.md` do projeto declarar regras próprias de commit (escopos válidos,
estágio de versão, exceções), elas têm precedência sobre os exemplos genéricos
daqui.

## Formato

```
<tipo>(<escopo>)<!>: <descrição>
                              ← linha em branco
<corpo: o PORQUÊ da mudança>
                              ← linha em branco
<rodapés>
```

## Tipos — e o que cada um faz na release

| Tipo | Versão | CHANGELOG |
|---|---|---|
| `feat` | **minor** ↑ | ✅ Funcionalidades |
| `fix` | **patch** ↑ | ✅ Correções |
| `perf` | — | ✅ Performance |
| `refactor` | — | ✅ Refatoração |
| `docs` | — | ✅ Documentação |
| `test` · `chore` · `ci` · `build` · `style` · `revert` | — | ❌ oculto |

Quem **decide a versão** é `feat`, `fix` e quebras de contrato. Escolha o tipo
pelo que a mudança **é**, não pelo arquivo que você tocou (mexer num controller
para corrigir um bug é `fix`, não `refactor`).

**O estágio de versão muda o efeito de uma quebra.** Num projeto `0.x`, `feat` e
quebras costumam virar **minor** e o `1.0.0` é um marco manual; num projeto
`1.x+`, uma quebra vira **major**. Confira o estágio e a config de release no
`CLAUDE.md` ou no `release-please-config.json` do projeto antes de marcar versão.

## Quebra de contrato — a regra mais importante

Toda quebra **tem** que ser marcada. Sem a marca, o release-please corta a versão
errada e a quebra some do changelog — o pior tipo de bug de release.

Marque das duas formas:

1. `!` depois do escopo no header — `feat(api)!: ...`
2. um rodapé `BREAKING CHANGE: <o que quebrou e como migrar>`

É quebra quando: endpoint removido/renomeado, contrato de request/response
alterado, valor de enum removido, mudança de auth, migration que dropa/renomeia
coluna, mudança de comportamento padrão, env var renomeada.

```
feat(auth)!: exigir tenant no JWT em vez do header X-Tenant-Id

BREAKING CHANGE: o header X-Tenant-Id deixou de ser aceito. Clientes devem
enviar o tenant no claim do JWT. Tokens emitidos antes do deploy param de
funcionar.
```

## Escopo

Um escopo por commit, minúsculo. Não é obrigatório, mas é fortemente
recomendado — ajuda a escanear o changelog. Use os escopos que o `CLAUDE.md` do
projeto define; se não houver lista, use o módulo/área tocada (ex: `auth`, `api`,
`ui`, `deps`, `ci`, ou o nome do módulo de domínio).

## A descrição É a linha do changelog

O release-please copia a descrição **literal** para o `CHANGELOG.md`. Escreva-a
como nota de release, não como recado para você mesmo.

- Verbo no infinitivo, em pt-BR: "adicionar", "corrigir", "remover".
- Diz o que mudou para o usuário — sem nome de arquivo, sem jargão interno, sem
  "ajustes" / "mudanças".
- ≤ 72 caracteres. Sem ponto final.

| ❌ Ruim | ✅ Bom |
|---|---|
| `fix: ajuste no service` | `fix(saldo): corrigir saldo que ignorava lançamentos do dia` |
| `feat: mexe no controller` | `feat(agenda): adicionar validação de conflito de horário` |
| `chore: várias coisas` | `refactor(clinico): extrair cálculo para o domínio` |

## Corpo e rodapés

- **Corpo** — o **porquê**, quando não é óbvio: causa raiz de um bug, motivo de
  uma decisão, trade-off aceito. Quebre em ~100 colunas. Pode omitir se o título
  já diz tudo.
- **Rodapés** — `Refs: #123` ou `Closes #123` (linka e fecha a issue);
  `BREAKING CHANGE: ...` para quebras.
- **NUNCA** adicionar `Co-authored-by` nem qualquer atribuição de IA.

## Um commit = uma mudança lógica

Cada commit vira um item do changelog. "Corrige várias coisas" = um item vago.

- Uma feature ou uma correção por commit. Não misture refactor com feat.
- Migration de schema no **mesmo** commit do código que a usa.
- Nunca commitar código que quebra teste ou build.

## Título de PR (quando o merge é squash)

Com **squash merge**, o commit que vai para a branch é o **título do PR**, e é ele
que o release-please lê.

- O **título do PR** também tem que ser um Conventional Commit válido.
- `feature/* → dev`: pode squashar — o título do PR vira a linha do changelog.
- `dev → main` (ou para a branch protegida): prefira **merge commit**, não
  squash — assim o release-please enxerga cada commit e monta o changelog
  completo. Squashar a integração colapsa a release inteira em uma única linha.

## Checklist antes de commitar

1. O tipo reflete o que a mudança **é**? (`feat`/`fix` mexem na versão)
2. Quebra de contrato? → `!` no header **e** rodapé `BREAKING CHANGE:`.
3. A descrição lê bem como linha de changelog? ≤ 72 chars, sem ponto final.
4. Uma só mudança lógica neste commit?
5. O corpo explica o porquê (se não for óbvio)?
6. Sem `Co-authored-by`.
7. Testes e build passam.

Um hook `commit-msg` (commitlint, githooks) pode rejeitar header malformado — mas
ele só checa **estrutura**. Descrição boa é com você.
