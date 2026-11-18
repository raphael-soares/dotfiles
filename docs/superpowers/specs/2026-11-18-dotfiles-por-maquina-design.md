# Dotfiles por máquina com dotter

## Intenção

O repo serve dois PCs e não sabe disso. O `install.sh` pergunta grupo por grupo
a cada execução, os grupos moram em bash dentro dele, e arquivo de uma máquina
só vai para as duas (o modeline da TV no `hypr/monitors.lua`, a regra udev do
DAC Fuxi-H3 no `sistema/`). A raiz tem 22 pacotes do stow soltos ao lado de
`docs/`, `packages/` e `sistema/`.

O dono quer blocos mais claros e um arquivo que diga o que vai para cada
máquina.

| Máquina | Sistema | Papel |
|---|---|---|
| notebook | Arch + Hyprland | trabalho, programação, faculdade |
| casa | Fedora + KDE | jogos, design, música |

## Objetivos

- Um arquivo por máquina lista os módulos dela; rodar um comando na máquina
  aplica exatamente aquilo, sem pergunta.
- Raiz organizada por camada (terminal, desktop, ai, trabalho, docs).
- O que é de uma máquina só fica num módulo que só aquela máquina habilita.
- Continuar com symlink: editar `~/.config/...` (à mão ou por agente) edita o
  repo.

## Fora do escopo

- Config do KDE. A casa leva só o comum; o Plasma fica como está.
- Segredos: continuam em `~/.env.local` e `~/.bash_profile.local`, fora do repo.
- O setup do herdr-app continua no repo `herdr-setup`, só clonado e instalado.

## Anti-objetivos

- Arquivo de app virar cópia sem motivo. Template do dotter é cópia: só usar
  quando o app não tiver include.
- Hyprland do notebook ficar em modo de emergência depois da troca.
- Estado de app (sessões do omp, cache do Claude, estado do Noctalia) voltar a
  cair dentro do repo.

## Abordagens

| Opção | Ganho | Custo | Decisão |
|---|---|---|---|
| dotter | `global.toml` com módulos, `.dotter/<hostname>.toml` por máquina escolhido sozinho, symlink por arquivo, variáveis, hooks com `dotter.packages`, `owner` para arquivo de root | migrar o mapeamento para TOML; sem pacote no dnf | escolhida pelo dono |
| stow + um arquivo por máquina lido pelo `install.sh` | nenhuma ferramenta nova | diferença dentro de arquivo sem solução; o script caseiro cresce | descartada |
| chezmoi | o mais completo (segredos, scripts run_once) | trabalha com cópia e `chezmoi apply`, briga com agente editando a config viva | descartada |

Fatos conferidos no código do dotter (0.13.x): sem `.dotter/local.toml`, ele
carrega `.dotter/<hostname>.toml`; o hook vê `dotter.packages.<nome>`; alvo
simbólico aceita `owner` e `recurse`.

## Desenho

### Layout do repo

```
.dotter/
  global.toml        módulos: arquivo do repo -> destino, variáveis
  notebook.toml      packages = [...] do notebook
  casa.toml          packages = [...] da casa
  post_deploy.sh     pacotes da distro, /etc, gsettings, herdr-setup, perfil enterprise
  adotar.sh          primeira aplicação numa máquina que já tem config
terminal/  bash git starship fzf mise nvim ghostty fastfetch
desktop/   fontes webapps audio (com o Fuxi) syncfast
hyprland/  hypr portal noctalia gtk greetd
ai/        layout interno sem mudança
trabalho/  bin (vpn, omp-agendado-work), shell (ompe, SESSIONIZER_DIRS)
tests/     maquinas.sh e adotar.sh, num HOME falso
docs/
README.md
.env.example
```

Cada pasta da raiz é um módulo do dotter, com o mesmo nome que aparece no
arquivo da máquina. Dentro de cada pasta de app ficam só os arquivos do app,
sem o prefixo do home (`terminal/ghostty/config`, não
`ghostty/.config/ghostty/config`). O destino mora no `global.toml`. A lista de
pacotes da distro fica no módulo, em `pacotes.<distro>.txt`.

`ai/` mantém a árvore interna (`ai/.omp/agent/...`, `ai/.claude/...`,
`ai/.local/bin/...`, `ai/skills`). Scripts, skills e o `AGENTS.md` citam esses
caminhos (`~/.dotfiles/ai/.omp/overlays/enterprise.yml`,
`~/.dotfiles/ai/.omp/sem-humano.md`, `~/.dotfiles/ai/skills`); mexer neles
quebra referências sem ganho.

### Módulos do dotter

Os módulos do dotter seguem o que muda entre máquinas, não um por app, para o
arquivo de cada máquina caber em uma linha.

| Módulo dotter | Conteúdo | notebook | casa |
|---|---|---|---|
| `terminal` | bash, git, starship, fzf, mise, nvim, ghostty, fastfetch; clona e instala o `herdr-setup` | sim | sim |
| `ai` | omp e Claude Code (perfil pessoal), skills, `~/.local/bin` do `ai` menos `omp-agendado-work` | sim | sim |
| `desktop` | fontes, webapps, audio (A2DP só, esconder pro-audio, Fuxi-H3: `55-fuxi-soft-mixer.conf` e a regra udev `91-fuxi-h3-mixer.rules`), syncfast | sim | sim |
| `hyprland` | hypr, portal, noctalia, gtk, o `theme = noctalia` do Ghostty, greetd e o PAM dele; no hook: gsettings, `~/.icons/default`, override do flatpak, `gcr-ssh-agent.socket` | sim | não |
| `trabalho` | vpn, `ompe`, `SESSIONIZER_DIRS`, `omp-agendado-work`, `ai/.omp/overlays/enterprise.yml`; no hook: os links de `~/.omp/profiles/enterprise/agent` e o `plugin install` do perfil enterprise | sim | não |

Um módulo pode linkar arquivo de qualquer pasta do repo. O
`overlays/enterprise.yml` continua em `ai/`, porque o `ompe` cita o caminho,
mas só o módulo `trabalho` o linka. O `omp-agendado-work` vai para
`trabalho/bin`: ninguém cita o caminho dele, só o nome. A casa não recebe nada
do perfil enterprise.

O tema `noctalia.json` do syncfast fica como está: quando o tema some, o
syncfast cai no tema embutido claro ou escuro (`Themes::resolve`).

```toml
# .dotter/notebook.toml
packages = ["terminal", "ai", "desktop", "hyprland", "trabalho"]

# .dotter/casa.toml
packages = ["terminal", "ai", "desktop"]
```

### Diferença dentro de um arquivo

Preferir include do próprio app a template:

- Ghostty: o `config` comum termina em `config-file = ?maquina.conf`. O módulo
  `hyprland` linka um `maquina.conf` com `theme = noctalia`. Na casa o arquivo
  não existe e o Ghostty usa o tema padrão dele.
- `monitors.lua`, `gtk` e o resto do Hyprland só existem no notebook, então
  ficam como estão.

### Diretório inteiro ou arquivo por arquivo

Mesma regra que o `linkar()` seguia, agora no `global.toml`:

- Diretório que só o repo escreve vira um link só (`recurse = false`):
  arquivo novo que um agente cria aparece no repo sem novo deploy. Exemplos:
  `ai/skills`, `~/.omp/agent/{extensions,rules,prompts,themes}`,
  `~/.config/hypr`, `~/.config/nvim`, `~/.config/noctalia-plugins`.
- Diretório onde o app grava estado (`~/.omp/agent`, `~/.claude`,
  `~/.local/state/noctalia`, `~/.config/syncfast`, `~/.local/bin`) é linkado
  arquivo por arquivo, para o estado nunca cair no repo. Arquivo novo ali
  pede `dotter deploy`.

O builder confere cada diretório contra o critério; na dúvida, arquivo por
arquivo.

### Pacotes da distro

A lista fica na pasta do módulo que precisa dela: `pacotes.arch.txt` e
`pacotes.fedora.txt`. Como cada máquina tem uma distro fixa, só existe a lista
que alguma máquina usa: módulo só do notebook tem só a lista do Arch. O
`post_deploy.sh` instala as listas dos módulos habilitados, só o que falta
(`yay`/`pacman` no Arch, `dnf` no Fedora), como o `instalar_pacotes` faz hoje.
Pular a instalação continua possível (variável de ambiente no hook).

### /etc

Só dois arquivos de `/etc` ficam no repo, cada um no módulo que precisa dele:
o greetd com o PAM dele (`hyprland`) e a regra udev do Fuxi (`desktop`, nas
duas máquinas). Não existe mais módulo `sistema`.

Arquivo de root não vira symlink para o home: PAM e greetd apontando para um
arquivo que o usuário edita sem sudo é um furo. Eles são copiados com dono
root, pelo dotter (alvo com `owner = "root"`, tipo template) ou pelo
`post_deploy.sh` com `sudo install -Dm644`, como hoje. O builder escolhe depois
de conferir que nenhum dos dois tem `{{`, que o template interpretaria.

O Fuxi é usado nas duas máquinas, com cabo no notebook e com dongle na casa,
e o microfone dele é áudio USB, que o A2DP só não afeta. A regra udev
reconhece o cabo pelo ID USB `040b:0897` e a do WirePlumber pelo nome
`Fuxi-H3-00`. Se o dongle aparecer com outro ID ou nome, as duas regras não
rodam na casa e nada quebra. O passo a passo da casa confere com `lsusb` e
`wpctl status` se o dongle tem o mesmo problema do canal direito mudo antes de
qualquer ajuste. A regra chama `amixer`, então `alsa-utils` entra na lista de
pacotes do Fedora.

### O que sai

- `install.sh`: a lógica passa para o `global.toml`, os arquivos de máquina e o
  `post_deploy.sh`.
- Legado: `tmux/`, `workmux/`, `omp-legado/`, `packages/legado.*`. O histórico
  do git guarda.
- `packages/`: as listas vão para dentro dos módulos; as listas Fedora de
  módulos só do notebook (`vpn.fedora.txt`) somem.
- Do `sistema/`, decidido com o dono: docker `daemon.json`, zram, journald,
  paccache, plymouth e o `enable` do thermald saem do repo. O que já está no
  `/etc` do notebook fica como está; só deixa de ser versionado.
- Pacote `raphael`: `SESSIONIZER_DIRS` e `ompe` vão para `trabalho/`, a config
  do syncfast para `desktop/syncfast`. O `config.toml.v*` continua ignorado.
- Pasta `.omp/` da raiz (`.omp/planos/`): o builder confere se ainda serve; se
  não, sai.
- Regras do `.gitignore` que existiam porque o stow linkava a pasta inteira
  (sessões do Claude e do omp, estado do Noctalia, `gtk-*/` além do
  `settings.ini`). Ficam as de segredo (`.env*`, `.bash_profile.local`) e o
  `.dotter/local.toml` e `.dotter/cache*`.

### Hostname

O dotter escolhe o arquivo pelo hostname, e o deste notebook é `arch`. A
migração renomeia os dois PCs com `hostnamectl set-hostname notebook` e
`hostnamectl set-hostname casa`.

### Instalação numa máquina nova

```
git clone ... ~/.dotfiles && cd ~/.dotfiles
# notebook: yay -S dotter-rs
# casa: binário do release do GitHub em ~/.local/bin (não há pacote no dnf)
sudo hostnamectl set-hostname <notebook|casa>
dotter deploy
```

O README passa a descrever isso e a tabela de módulos por máquina, no lugar
das tabelas de pacote e grupo do stow.

## Troca no notebook (sistema vivo)

Os symlinks do stow apontam para dentro do `~/.dotfiles`, e o Hyprland está
rodando. Riscos e como tratar:

- Hyprland em modo de emergência: tirar e refazer o link de `hyprland.lua`
  dispara o reload sem o arquivo, e ele não recarrega quando o link volta.
  Depois do `dotter deploy`: `hyprctl reload && noctalia msg config-reload`,
  e conferir `hyprctl configerrors` vazio e `hyprctl binds` com binds.
- Conflito do dotter com os links do stow: o dotter não sobrescreve arquivo que
  não é dele. A ordem é desfazer os links do stow (`stow -D` por pacote, ou
  apagar os symlinks que apontam para o repo) e rodar `dotter deploy` na mesma
  sessão.
- gsettings: o hook não pode sobrescrever o tema de ícone vivo com o valor do
  repo; alinhar o repo ao valor atual (`gsettings get ...`) antes.
- Escrita atômica: app que grava num arquivo temporário e renomeia troca o
  symlink por arquivo real. Hoje isso já acontece com o `gtk-4.0/settings.ini`
  (nwg-look). Conferir depois da troca que continuam symlink, após o app
  gravar: `noctalia/settings.toml`, `syncfast/config.toml`,
  `nvim/lazy-lock.json`, `~/.claude/settings.json`, `~/.omp/agent/config.yml`.
  O que virar arquivo real vai para cópia gerida (template) ou sai do repo, e a
  decisão fica registrada na PR.

## Troca na casa

Não se sabe se a casa tem links do stow, arquivos reais ou nada. O passo a
passo trata os três casos sem perguntar: desfaz os symlinks que apontam para
o `~/.dotfiles`, move para `~/.dotfiles-backup/<data>/` qualquer arquivo real
que esteja num destino do dotter, e só então roda `dotter deploy`. É isso que
substitui o `--adopt` do `install.sh`. O mesmo passo serve ao notebook.

## Ordem

O `~/.dotfiles` está no branch `feat/superpowers`, que ainda não entrou na
`main`, e tem mudanças não commitadas (`ai/`, `README.md`, a saída do
`herdr-app/`). A reorganização move quase todo arquivo: começar depois que esse
trabalho entrar na `main`, partindo dela, para não brigar com ele no merge.

## Aceite

- No notebook, `dotter deploy` sem argumento aplica os cinco módulos; nenhum
  arquivo que existia antes some do home e os links apontam para o repo.
- Hyprland, Noctalia, greetd, Ghostty com tema `noctalia`, omp (pessoal e
  `ompe`), Claude Code, vpn e o Fuxi nos dois canais funcionam como antes da
  troca.
- `git status` limpo depois de usar o notebook um tempo (estado de app não cai
  no repo).
- Na casa, `dotter deploy` aplica `terminal`, `ai` e `desktop`, instala o que
  falta pelo dnf e não cria nada de Hyprland nem de trabalho; do `/etc`, só a
  regra do Fuxi.
- Na raiz do repo não sobra pacote do stow, `install.sh` nem `packages/`.

## Para o builder decidir

- Nome exato das pastas dentro de cada camada e o mapeamento de cada arquivo.
- `/etc` pelo `owner` do dotter ou pelo hook (critério acima).
- Como o hook recebe o "pular pacotes".
- Se `ai/skills` e os outros symlinks internos do `ai/` vão como diretório
  (`recurse = false`) ou arquivo por arquivo.
- Validação na casa: o dono roda lá; o builder entrega o passo a passo.
