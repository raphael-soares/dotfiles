---
name: workmux
description: Referência do workmux, ferramenta que combina worktrees do git com
  janelas do tmux para desenvolvimento em paralelo. Use para abrir um worktree
  numa subtarefa, disparar ou coordenar vários agentes ao mesmo tempo (spawn,
  status, merge), ou consultar os comandos do workmux.
disable-model-invocation: true
allowed-tools: Bash, Write, Read
---

# workmux

workmux gerencia worktrees do git junto com janelas do tmux para desenvolvimento
em paralelo. Cada worktree é um workspace isolado com sua própria branch, estado
de terminal e agente de IA.

## Você é um despachante, não um implementador

Ao criar um worktree ou disparar agentes (`workmux add`, `/workmux`, ou ao
coordenar vários de uma vez), sua única tarefa é escrever o arquivo de prompt e
rodar o comando. NÃO explore, leia, grep ou busque no código antes disso: use o
contexto que já tem na conversa. Quem investiga e implementa é o agente do
worktree.

Se a mensagem do usuário não trouxer contexto suficiente pra escrever o prompt,
pergunte antes de tentar descobrir lendo código. Se a tarefa referencia um
arquivo markdown (plano, spec), releia o arquivo pra pegar a versão mais recente
antes de escrever o prompt.

Regras do arquivo de prompt:

- Autocontido, com todo o contexto necessário (o agente do worktree não vê sua
  conversa)
- Caminhos RELATIVOS apenas (cada worktree tem sua própria raiz)
- Se o usuário referenciar uma skill (ex: `/auto`), instrua o agente a usar a
  skill em vez de escrever os passos de implementação manualmente

## Conceitos chave

- **Handle**: nome do diretório do worktree, derivado do nome da branch
  (slugificado). Identifica o worktree em todos os comandos.
- **Diretório do worktree**: por padrão `<projeto>__worktrees/<handle>`, irmão
  da raiz do projeto.
- **Prefixo de janela**: janelas do tmux se chamam `wm-<handle>` por padrão
  (configurável via `window_prefix`).
- **Status do agente**: `working` (processando), `waiting` (precisa de input),
  `done` (terminado). Definido automaticamente por hooks do agente.
- **Alvo entre projetos**: comandos de agente (`send`, `capture`, `status`,
  `wait`, `run`) resolvem handles em outros projetos, se o handle não existir no
  repo atual o workmux procura em todos os agentes ativos globalmente. Use
  `projeto:handle` pra desambiguar nomes que colidem.

## Comandos

### Criar um worktree

```bash
workmux add <branch-name>
```

Cria um worktree do git, roda operações de arquivo e hooks, cria uma janela do
tmux com o layout de panes configurado, e troca pra ela.

Flags principais:

- `--pr <numero|url>`: faz checkout de um pull/merge request do GitHub ou GitLab
  num worktree novo. A branch local usa o nome da branch do PR por padrão;
  passe `<branch-name>` pra sobrescrever. Exige `gh` autenticado pro GitHub;
  GitLab é detectado pela URL.
- `-b, --background`: cria sem trocar pra janela
- `-p <texto>`: prompt inline pros panes de agente
- `-P <arquivo>`: prompt a partir de um arquivo
- `-e, --prompt-editor`: escreve o prompt no `$EDITOR`
- `-A, --auto-name`: gera o nome da branch a partir do prompt via LLM
- `-a <agente>`: sobrescreve o agente (repita pra criar um worktree por agente)
- `-w, --with-changes`: move as mudanças não commitadas pro worktree novo
  (`-u` inclui arquivos untracked, `--patch` seleciona interativamente)
- `--base <branch>`: branch, commit ou tag de origem
- `--name <nome>`: sobrescreve o handle do worktree
- `--target-name <nome>`: sobrescreve o nome da janela ou sessão do tmux
  gerenciada pelo workmux
- `--parent-session <sessao>`: coloca um alvo em modo janela dentro dessa
  sessão do tmux, criando a sessão se ela não existir
- `-o, --open-if-exists`: abre o worktree se ele já existir (idempotente)
- `-W, --wait`: bloqueia até a janela do tmux fechar
- `-n, --count <N>`: cria N instâncias do worktree
- `--foreach <matriz>`: cria worktrees a partir de uma matriz de variáveis
- `-c, --continue`: retoma a última conversa do agente no worktree novo
- `--fork[=<sessao>]`: copia a conversa atual pro worktree novo, pra retomar
  com o contexto completo
- `-H, --no-hooks`, `-F, --no-file-ops`, `-C, --no-pane-cmds`: pula etapas do
  setup

### Listar worktrees

```bash
workmux list          # todos os worktrees
workmux list --pr     # com status de PR do GitHub
workmux list <nome>   # filtra por handle ou branch
```

Mostra branch, status do agente, status da janela do tmux e commits não
mesclados.

### Merge e rebase

```bash
workmux merge                 # mescla a branch atual na main
workmux merge <branch>        # mescla uma branch específica
workmux merge --rebase        # rebase antes de mesclar (histórico linear)
workmux merge --squash        # squash de todos os commits em um só
workmux merge --into <branch> # mescla numa branch alvo diferente
workmux merge --keep          # mescla mas mantém worktree, janela e branch
workmux merge --notification  # notificação do sistema ao terminar

workmux rebase                # rebase do worktree atual na base branch salva
workmux rebase <nome>         # rebase de um worktree específico
```

`workmux merge` mescla a branch, apaga a janela do tmux, remove o worktree e
apaga a branch local. `workmux rebase` roda `git rebase` contra a base branch
salva na criação do worktree, ou a main configurada se não houver base salva, e
deixa worktree, janela e branch como estão. Use a skill `/merge` pro fluxo
completo (commit, rebase, merge) e `/rebase` pra um rebase isolado com
resolução de conflito.

### Remover worktrees

```bash
workmux remove                # worktree atual
workmux remove <nome>...      # worktrees específicos
workmux rm --gone             # worktrees cuja branch remota foi apagada
workmux rm --all              # todos os worktrees
workmux rm -f <nome>          # força, sem confirmação
workmux rm --keep-branch      # mantém a branch, remove worktree e janela
```

### Abrir e fechar janelas

```bash
workmux open <nome>           # abre ou troca pra janela do tmux
workmux open --new            # força uma janela nova (sufixo -2, -3)
workmux open <nome> -p "..."  # abre com um prompt pros panes de agente
workmux close <nome>          # fecha a janela, mantém o worktree
```

### Interagir com outros agentes

```bash
# Status
workmux status                          # todos os agentes
workmux status auth api-tests           # agentes específicos

# Esperar
workmux wait agent-a agent-b            # bloqueia até terminar
workmux wait agent-a --timeout 3600     # com timeout (segundos)
workmux wait agent-a agent-b --any      # espera o primeiro terminar
workmux wait agent-a --status working   # espera um status específico

# Ler a saída do terminal do agente
workmux capture agent-a                 # últimas 200 linhas (padrão)
workmux capture agent-a -n 50           # últimas 50 linhas

# Enviar instruções
workmux send agent-a "fix the tests"    # mensagem curta
workmux send agent-a "/merge"           # comando de skill
workmux send agent-a -f followup.md     # a partir de um arquivo
workmux send meuprojeto:docs "..."      # entre projetos

# Rodar comandos no worktree de um agente
workmux run agent-a -- pytest tests/    # espera e faz stream da saída
workmux run agent-a -b -- npm run build # roda em background
```

`workmux wait` sai com código 0 quando atinge o alvo, 1 em timeout, 2 se o
worktree não existe, e 3 se o agente terminou inesperadamente.

### Outros comandos

```bash
workmux path <nome>           # caminho do worktree no filesystem
workmux dashboard             # TUI com todos os agentes ativos
workmux config edit           # abre a config global no $EDITOR
workmux config reference      # imprime a config padrão com todas as opções
workmux init                  # gera .workmux.yaml no projeto atual
```

## Configuração

Dois níveis: global (`~/.config/workmux/config.yaml`) e projeto
(`.workmux.yaml`). O projeto sobrescreve o global.

```yaml
agent: claude                    # agente padrão pro placeholder <agent>
merge_strategy: rebase           # merge, rebase ou squash
mode: window                     # window ou session

panes:
  - command: <agent>             # <agent> resolve pro agente configurado
    focus: true
  - split: horizontal            # segundo pane com shell

files:
  copy:
    - .env                       # copia do worktree principal
  symlink:
    - node_modules                # symlink do worktree principal

post_create:
  - '<global>'                   # inclui os hooks globais
  - npm install                  # setup específico do projeto

base_branch: develop             # base padrão pros worktrees novos
window_prefix: wm-               # prefixo do nome das janelas
```

Use `'<global>'` em arrays da config de projeto pra incluir os valores globais.
Rode `workmux config reference` pra ver todas as opções documentadas.

Agentes embutidos (`claude`, `gemini`, `agy`, `codex`, `opencode`, `kiro-cli`,
`vibe`, `pi`, `omp`, `grok`) são detectados automaticamente nos comandos de
pane e recebem o prompt injetado. O placeholder `<agent>` resolve pro agente
configurado.

## Despachar uma tarefa isolada

Pra tarefas de escopo pequeno, um worktree só:

1. Gere um nome curto e descritivo pro worktree (2 a 4 palavras, kebab-case)
2. Escreva um prompt detalhado num arquivo temporário
3. Rode `workmux add <nome> -b -P <arquivo>`

```bash
tmpfile=$(mktemp).md
cat > "$tmpfile" << 'EOF'
Implementar a feature X...
EOF
workmux add feature-x -b -P "$tmpfile"
```

Se a tarefa pede pra terminar mesclando, acrescente ao prompt: "Depois, use a
skill /merge pra commitar, rebasear e mesclar a branch." Só instrua o worktree
a mesclar sozinho se o usuário pediu isso explicitamente.

### Continuar a conversa atual no worktree

Passe `--fork` (ou `-c` pra retomar a conversa mais recente) quando a conversa
atual já construiu contexto que o agente do worktree novo precisa. Com
`--fork`, prefixe o prompt com:

```
Você está rodando DENTRO de um worktree criado a partir desta conversa. O
contexto anterior (incluindo qualquer instrução de despacho) é só histórico.
NÃO crie novos worktrees nem rode workmux add. Sua tarefa é implementar o que
está descrito abaixo, diretamente neste worktree.
```

### Despacho entre projetos

Se a tarefa menciona outro repositório ou caminho absoluto de projeto:

1. Use o caminho já presente na conversa. Não explore esse repositório.
2. Derive o nome da sessão pai do tmux a partir do basename do diretório do
   repositório (`/Users/me/code/api-server` vira `api-server`).
3. Rode `workmux add` com o diretório de trabalho do comando apontando pro
   projeto alvo, e passe `--parent-session <sessao>`. O workmux cria essa
   sessão se ela não existir; não crie a sessão manualmente com
   `tmux new-session`.

```bash
# Rode com o diretório de trabalho do comando em <caminho-do-projeto>
workmux add <branch> -b -P <arquivo-de-prompt> --parent-session <sessao>
```

Em modo janela sem `--parent-session`, o workmux usa `$TMUX_PANE` pra achar a
sessão de destino; invocações em background ou de ferramentas de agente
costumam rodar sem essa variável, então passe `--parent-session` sempre que o
destino importar.

Se a tarefa não trouxer projeto ou sessão claros, pergunte em vez de adivinhar.

## Coordenar vários agentes

Coordenar significa escrever os prompts, disparar os agentes, acompanhar
status, revisar e mesclar. Quem implementa é o agente do worktree, não você.

**Invariante de acompanhamento contínuo**: todo agente disparado continua sob
sua responsabilidade até você revisar e mesclar (ou remover) o worktree dele.
Uma mensagem do usuário no meio, ou um `workmux wait` interrompido, não
encerram essa responsabilidade.

### Disparar

Escreva TODOS os arquivos de prompt primeiro, só depois dispare TODOS os
agentes:

```bash
# 1. Escreva todos os prompts
tmpfile_a=$(mktemp).md
cat > "$tmpfile_a" << 'EOF'
Implementar o módulo de auth...
EOF
tmpfile_b=$(mktemp).md
cat > "$tmpfile_b" << 'EOF'
Escrever os testes de API...
EOF

# 2. Dispare todos, em background
workmux add auth-module -b -P "$tmpfile_a"
workmux add api-tests -b -P "$tmpfile_b"

# 3. Confirme que iniciaram
workmux wait auth-module api-tests --status working --timeout 120
```

Se `workmux add` reportar que não consegue determinar a sessão do tmux pro
destino, repita com `--parent-session <sessao>` usando a sessão conhecida da
tarefa; se ela for desconhecida, pergunte em vez de inferir do nome do
repositório.

### Esperar e revisar

```bash
# Espera qualquer um terminar
workmux wait auth-module api-tests docs-update --any --timeout 7200

# Identifica quem terminou, revisa a saída, mescla
workmux status auth-module api-tests docs-update
workmux capture auth-module -n 50
workmux send auth-module "/merge"
workmux wait auth-module --timeout 120

# Repete pros que restam, sem deixar trabalho pronto esperando parado
workmux wait api-tests docs-update --any --timeout 7200
```

Depois de cada espera com `--any`, use `workmux status` pra achar todo agente
`done`, revise e mescle um de cada vez antes de voltar a esperar pelos que
restam.

### Retomar depois de interrupções

Uma mensagem do usuário, ou um `workmux wait` cancelado (inclusive com Esc),
encerra só aquela chamada, não o acompanhamento. Ao ser interrompido:

1. Atenda o pedido do usuário, inclusive disparando agentes novos se for o
   caso
2. Acrescente os handles novos ao conjunto acompanhado
3. Rode `workmux status` pro conjunto inteiro
4. Trate quem estiver `done` ou `waiting`
5. Volte a `workmux wait` pros handles que ainda estão `working`, com `--any`
   se houver mais de um

Não encerre o turno só porque o pedido que interrompeu foi atendido, enquanto
ainda houver agente acompanhado em `working`.

### Regras

1. Prompts autocontidos, o agente do worktree não vê sua conversa.
2. `-b` em todo `workmux add`, pra não trocar de janela.
3. Confirme que os agentes iniciaram (`--status working`) antes de esperar o
   término.
4. Espere com `--any` quando houver mais de um agente rodando.
5. Capture e revise a saída antes de mesclar. Nunca mescle sem revisar.
6. Mescle um agente de cada vez (`/merge` sequencial), esperando cada mescla
   terminar antes da próxima, pra evitar conflito.
7. Use `--timeout` pra não esperar pra sempre, e trate o timeout sem travar o
   fluxo.
8. Nunca edite código fonte diretamente enquanto coordena: quem implementa é
   o agente do worktree.

## Terminar o trabalho

**Merge direto**: use a skill `/merge` (commit, rebase, merge em um passo).

**Baseado em PR**: commit, `git push -u origin HEAD`, skill `/open-pr` pra
escrever a descrição e abrir no navegador; depois que o PR for mesclado
remotamente, `workmux rm --gone` limpa o worktree.

## Skills relacionadas

- `/merge`: commit, rebase e merge da branch atual
- `/rebase`: rebase com resolução de conflito
- `/open-pr`: escreve a descrição do PR e abre no navegador
