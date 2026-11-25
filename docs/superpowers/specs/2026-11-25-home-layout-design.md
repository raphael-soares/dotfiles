# Home por tipo, domínio um nível abaixo

## Intenção

As áreas compartilhadas (`Personal`, `Udesc`, `Unimed`, `TEAjudo`) e as locais
(`Design`, `Studio`) estão soltas no home, no mesmo nível de `Code` e
`Downloads`. O dono gosta da divisão por domínio (facilita o sync e não
fragmenta), mas não gosta da poluição visual nem da mistura conceitual: o
primeiro nível deve ser tipo de coisa, como já é `~/Code/<Área>`.

## Layout final

```
~/
├── Code/<Área>/<repo>     código (só notebook)
├── Documents/<Área>/      Personal, Udesc, Unimed, TEAjudo (pares do syncfast)
├── Creative/              projetos criativos multidisciplinares (só PC de casa)
├── Studio/                produção musical (só PC de casa)
├── Media/   Games/        exceções (só PC de casa)
└── Desktop/ Downloads/ Pictures/ Videos/
```

## Objetivos

- Nenhuma área solta no home além das exceções nomeadas acima.
- `XDG_DOCUMENTS_DIR` aponta para `~/Documents`; Nautilus e diálogos abrem lá.
- O Drive segue o mesmo layout: `Raphael:Personal` vira
  `Raphael:Documents/Personal`, e assim para as quatro áreas. `Raphael:Fotos`
  fica onde está (foto só existe no Drive).
- Cada área compartilhada continua sendo um par próprio do syncfast, agora
  apontando para o caminho novo dos dois lados, sem reenvio de conteúdo.
- `~/Design` vira `~/Creative`; o módulo `design/` do repo vira `creative/`.

## Não objetivos

- Mudar a estrutura interna das áreas (`Creative/Projetos`, `Biblioteca`,
  `Estilos` seguem iguais).
- Mudar pastas do Drive fora das quatro áreas e de `Raphael:Design` (que vira
  `Raphael:Creative`, para bater com o home).
- Mexer em `Media`, `Games`, `Studio` (ficam no home: Media por causa do
  hardlink do Radarr/Sonarr, Games porque o XDG não tem pasta de jogo, Studio
  porque o nome é de produção musical).

## Antiobjetivos

- Symlink de compatibilidade (`~/Unimed -> Documents/Unimed`): mantém a
  poluição e tende a ficar para sempre.
- Reenvio do conteúdo pro Drive ou par do syncfast duplicado.
- Caminho velho sobrevivendo em algum arquivo do repo ou config.

## Abordagens

1. **Troca de uma vez, local e Drive juntos (escolhida).** Com o sync
   pausado, move as pastas locais e as remotas (move do lado do servidor, sem
   baixar nem subir), atualiza XDG, pares do syncfast e referências, e só
   então religa o sync. Home e Drive ficam com o mesmo layout; o risco de
   referência esquecida é coberto por uma busca final que precisa voltar
   vazia.
2. Mover e deixar symlink temporário. Nada quebra no dia, mas não entrega o
   home limpo. Rejeitada.
3. Mover só o local e manter o Drive como está. Mais barato, mas Drive e home
   ficam com layouts diferentes. Rejeitada pelo dono.

## Sequência obrigatória

1. Desativar os quatro pares no syncfast nas duas máquinas.
2. Mover as pastas remotas no Drive (server-side).
3. Mover as pastas locais em cada máquina.
4. Atualizar `local` e `remote` dos pares e as demais referências.
5. Religar os pares e conferir que o primeiro sync não transfere conteúdo.

## O que muda

- **Repo:** `ai/AGENTS.md` (tabela de áreas, regra "não existem `~/Documents`",
  linha do `XDG_DOCUMENTS_DIR`); skills `artcraft`, `cofre`, `video`; módulo
  `design/` renomeado para `creative/` (`bin/design-deploy`, `bin/craft-mcp`,
  `apps`), `docs/design.md`, `docs/machines.md`, `docs/media.md`,
  `media/qbittorrent/preferences.json`, `tests/design_deploy.sh`,
  `tests/secrets.sh`, `work/bin/vpn`, e `desktop/syncfast/config.toml` (campos
  `local` e `remote` dos quatro pares; `id` não muda). Specs antigas em
  `docs/superpowers/specs/` são histórico e não mudam.
- **XDG:** `~/.config/user-dirs.dirs` não é gerado pelo repo. Passa a ser
  versionado num módulo existente (escolha do construtor), com
  `DOCUMENTS=$HOME/Documents`, para as duas máquinas ficarem iguais.
- **Fora do repo, por máquina:** favoritos do GTK, ZenNotes, config do Claude
  Desktop, `ui.json` dos apps Craft.
- **Restrição:** antes de mover, confirmar como o syncfast guarda a base de
  cada par (por `id` ou por caminho). Se for por caminho, a base precisa ser
  migrada ou refeita sem transferência (os dois lados já idênticos), senão o
  religamento vira um sync inicial com risco de conflito.
- **Aceite:** busca por `~/(Personal|Udesc|Unimed|TEAjudo|Design)` e
  `$HOME/...` equivalentes no repo (fora das specs antigas) e no `~/.config`
  volta vazia; syncfast não reenvia nada após a troca.

## Para o construtor decidir

- Ferramenta do move server-side no Drive (rclone `moveto` no mesmo remote é
  o candidato óbvio).
- Se a migração vira script no repo ou checklist em `docs/`.
