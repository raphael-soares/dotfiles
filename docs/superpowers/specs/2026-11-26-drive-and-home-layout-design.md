# Drive separado, home local por XDG

Substitui `2026-11-25-home-layout-design.md` no que diz respeito a onde os
documentos moram e como o Drive se organiza.

## Intenção

A home de cada PC é local e segue o XDG. O que precisa existir nos dois PCs ou
no celular mora em `~/Drive`, espelho completo e offline da raiz do Google
Drive (`Raphael:`). A fronteira do sync fica visível no caminho: dentro de
`~/Drive` sincroniza, fora não. No Drive, a organização é por área.

## Regras

1. **Onde salvar:** vai precisar no outro PC ou no celular? `~/Drive/<área>`.
   Não? A pasta XDG local.
2. **Dentro de uma área:** trabalho com fim vai em `Projects/<projeto>`, com o
   mesmo nome do worktree ou da feature. Referência contínua vai numa categoria
   (2 a 3 por área). Projeto que acabou vai inteiro para `Archive/`.
3. **Código** fica só em `~/Code/<Área>/[<sistema>/]<repo>`. O Drive guarda
   documento de projeto, nunca código nem git; o README da pasta aponta para o repo.
4. **Dado pessoal de terceiro** (paciente, CPF) nunca sincroniza: fica em
   `attachments/` do repo, ignorado pelo git.
5. **Material de colega** é copiado para a pasta da disciplina, nunca como atalho.
6. **Segredo** fica no cofre ou no sops, nunca em pasta.
7. **Estrutura em inglês**, nome próprio, de disciplina e de obra no original.

## Drive (`Raphael:` = `~/Drive`, nos dois PCs)

```
~/Drive/
├── Personal/{Identity, Finance, Career, Photos, Wallpaper, Torrents, Archive}
├── Udesc/
│   ├── <SIGLA-disciplina>/              cursando
│   ├── University/
│   └── Archive/<ano>-<semestre>/<SIGLA-disciplina>/
├── Unimed/{Projects/<projeto>, Admin, Brand, Technical, Archive}
├── TEAjudo/{Projects/<projeto>, Legal, Commercial, Brand, Archive}
├── Documents/      ~/Documents aponta pra cá: documento sem área
├── Inbox/          porta do celular e da web
└── Backups/        só na nuvem: media/, fedora/. Nunca desce
```

- Um par do syncfast: `~/Drive` com `Raphael:`. Filtros: `- /Backups/**`,
  `- /Personal/Wallpaper/wallz/**`, `- /Personal/Wallpaper/forest-4.jpg`
  (symlink do dotter), `- *.mkv`, `- *.iso`, `- *.nsp`, `- *.xci`, `- *.nsz`.
  `*.mp4` deixa de ser barrado.
- Espelho, não `rclone mount`: o acervo é de cerca de 1 GB.
- A disciplina vai para `Archive/<semestre>/` quando o semestre acaba, no
  setup do semestre novo (skill `udesc-sincronizar-moodle`).

## Home local (XDG, sem sync)

| Pasta | Arch e Fedora | Só Fedora |
|---|---|---|
| `~/Documents` | symlink para `~/Drive/Documents` | |
| `~/Downloads` | entrada do navegador | |
| `~/Pictures` | `Screenshots/`, `Icons/`, `Wallpaper` (symlink para `~/Drive/Personal/Wallpaper`) | |
| `~/Videos` | `Recordings/` | |
| `~/Code` | `<Área>/[<sistema>/]<repo>`; monorepo em `~/Code/TEAjudo/teajudo` | |
| `~/Creative` | | `Projects/<Área>/<projeto>/`, `Library/`, `Styles/`, `Archive/` |
| `~/Studio` | | samples, presets, projetos |
| `~/Games` | | `PC/`, `Switch/`, `ROMs/<console>/`. A Steam fica em `~/.local/share/Steam` |
| `~/Media` | | `Movies/`, `Shows/`, `Books/`, `Downloads/` |

- Worktree só em `~/.workmux`. `~/.dotfiles` fica onde está (caminho do dotter).
- `flatpak override --user --filesystem=~/Drive` nos dois PCs, porque o
  symlink de `~/Documents` não basta para app com permissão `xdg-documents`.
- `~/Drive` primeiro nos favoritos do GTK.

## Backup do Fedora

`creative-backup` (módulo `creative`, timer diário) espelha `~/Creative` e
`~/Studio` em `Raphael:Backups/fedora/current/` e guarda o que foi trocado ou
apagado em `old/<data>/` por 30 dias. O backup do próprio syncfast (restic)
recusa destino dentro do par `~/Drive ↔ Raphael:`, e restic à parte pediria
outra senha para guardar; o conteúdo não é sensível, então fica sem
criptografia, como o resto do Drive. Detalhe em `docs/creative.md`.

## Triagem diária

- Todo dia às 8:00, herdr-automations no notebook, conta Personal. Execução
  perdida não roda atrasada.
- Atua só em `~/Downloads`, `~/Drive/Inbox` e prints soltos em `~/Pictures`.
- Script `triage` aplica as regras fixas: `.torrent` para
  `~/Drive/Personal/Torrents`, print para `~/Pictures/Screenshots`, CSV com
  coluna `Paciente` para `~/Code/TEAjudo/teajudo/attachments/inbox/`, arquivo
  de jogo para o Fedora quando ele responde.
- O agente decide o resto pela regra 2. Com certeza, move; na dúvida, deixa.
- Nunca apaga. Ignora arquivo mexido na última hora e download incompleto.
  Cada movimentação vai para `~/.local/state/triage/<data>.log`.
- Notificação no desktop só quando sobra pendência.

## Higiene

- Só o mise para versão de linguagem. Saem nvm, pyenv, sdkman e `.jdks`.
- As variáveis e mudanças que o `xdg-ninja` aponta como suportadas.
- `kondo` para artefato de build e `TF_PLUGIN_CACHE_DIR`.
- Saem lixeiras, `nvim_old`, `nvim_v2`, versões órfãs do syncfast, restos
  `.claude.json.tmp.*`. `.netrc` do Fedora vai para o cofre.

## Não objetivos

- Montar o Drive. Mover a Steam. Sincronizar `~/Code`, `~/Creative`, `~/Studio`,
  `~/Games` ou `~/Media`.
- Reorganizar dentro das áreas no dia a dia (a triagem não toca nelas).
