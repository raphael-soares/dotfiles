---
name: merge
description: Commita, rebaseia e mescla a branch atual, limpando worktree e
  janela do tmux. Use ao terminar o trabalho numa branch que vai ser mesclada
  localmente, sem passar por PR.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

**Argumentos:** `$ARGUMENTS`

Verifique flags nos argumentos:

- `--keep`, `-k` → passa `--keep` pro `workmux merge` (mantém worktree e janela
  do tmux depois de mesclar)
- `--no-verify`, `-n` → passa `--no-verify` pro `workmux merge`

Remova as flags dos argumentos antes de seguir.

Este comando termina o trabalho na branch atual:

1. Commitando as mudanças pendentes
2. Rebaseando na base branch
3. Rodando `workmux merge` pra mesclar e limpar

## Passo 1: Commit

Confira mudanças staged, unstaged e untracked com `git status --porcelain`. Se
houver mudanças, adicione todas com `git add -A`, revise o diff staged e
commite seguindo a skill `git-commit`. Pule este passo se a working tree
estiver limpa.

## Passo 2: Rebase

Pegue a base branch da config do git:

```
git config --local --get "branch.$(git branch --show-current).workmux-base"
```

Se não houver base branch configurada, use "main" como padrão.

Rebaseie na base branch local (NÃO dê fetch no origin antes):

```
git rebase <base-branch>
```

IMPORTANTE: não rode `git fetch`. Não rebaseie em `origin/<branch>`. Só
rebaseie no nome da branch local (ex: `git rebase main`, nunca
`git rebase origin/main`).

Se houver conflito:

- ANTES de resolver qualquer conflito, entenda que mudanças foram feitas em
  cada arquivo conflitante na base branch
- Pra cada arquivo em conflito, rode `git log -p -n 3 <base-branch> -- <file>`
  pra ver as mudanças recentes nesse arquivo na base branch
- O objetivo é preservar AMBAS as mudanças: as da base branch e as da sua
  branch
- Depois de resolver cada conflito, dê stage no arquivo e continue com
  `git rebase --continue`
- Se um conflito for complexo ou ambíguo, peça orientação antes de seguir

## Passo 3: Merge

Rode: `workmux merge --rebase --notification [--keep] [--no-verify]`

Inclua `--keep` só se a flag `--keep` foi passada nos argumentos. Inclua
`--no-verify` só se a flag `--no-verify` foi passada nos argumentos.

Isso mescla a branch na base branch e limpa worktree e janela do tmux (a
menos que `--keep` tenha sido usado).
