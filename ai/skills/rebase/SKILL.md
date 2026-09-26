---
name: rebase
description: Rebaseia a branch atual com resolução de conflito cuidadosa. Use
  quando precisar atualizar a branch atual com a base (ou com origin) antes de
  continuar o trabalho ou de mesclar.
disable-model-invocation: true
allowed-tools: Read, Bash, Glob, Grep
---

Rebaseia a branch atual.

Argumentos: $ARGUMENTS

Comportamento:

- Sem argumentos: rebaseia na base branch salva da branch atual
  (`git config branch.<atual>.workmux-base`), caindo pra main local se não
  houver nenhuma configurada
- "origin": dá fetch no origin, rebaseia em origin/main
- "origin/branch": dá fetch no origin, rebaseia em origin/branch
- "branch": rebaseia na branch local (use "main" pra forçar rebase na main
  local)

Passos:

1. Confira mudanças locais com `git status --porcelain`:
   - Se a working tree tiver mudanças staged, unstaged ou untracked, dê
     stash com `git stash push --include-untracked -m "workmux rebase"`.
   - Lembre se este comando criou um stash. Stashes já existentes ficam
     intocados.
   - Se o stash falhar, pare antes de dar fetch ou rebase.
2. Interprete os argumentos:
   - Sem args → o alvo é a base branch salva da branch atual
     (`git config --get branch.$(git branch --show-current).workmux-base`);
     se estiver vazia, o alvo é "main". Sem fetch.
   - Contém "/" (ex: "origin/develop") → separa remote e branch, dá fetch no
     remote, o alvo é remote/branch
   - Só "origin" → dá fetch no origin, o alvo é "origin/main"
   - Qualquer outra coisa → o alvo é esse nome de branch, sem fetch
3. Se for dar fetch, rode: `git fetch <remote>`. Se o fetch ou a resolução do
   alvo falharem antes do rebase começar, restaure o stash criado no passo 1
   antes de parar.
4. Rode: `git rebase <target>`
5. Se houver conflito, trate com cuidado (veja abaixo)
6. Continue até o rebase terminar
7. Se o passo 1 criou um stash, restaure com `git stash pop --index`:
   - Restaure o stash só depois que o rebase terminar com sucesso.
   - Se a restauração gerar conflito, preserve o stash, reporte os conflitos
     e deixe os arquivos afetados pra resolução manual.

Tratamento de conflito:

- ANTES de resolver qualquer conflito, entenda que mudanças foram feitas em
  cada arquivo conflitante na branch alvo
- Pra cada arquivo em conflito, rode `git log -p -n 3 <target> -- <file>` pra
  ver as mudanças recentes nesse arquivo na branch alvo
- O objetivo é preservar AMBAS as mudanças: as da branch alvo e as da sua
  branch
- Depois de resolver cada conflito, dê stage no arquivo e continue com
  `git rebase --continue`
- Se um conflito for complexo ou ambíguo, peça orientação antes de seguir
