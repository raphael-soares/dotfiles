## Máquinas e módulos

Os dotfiles servem dois PCs, e o [dotter](https://github.com/SuperCuber/dotter)
decide o que vai em cada um pelo hostname: ele lê `.dotter/<hostname>.toml`,
que lista os módulos da máquina. O notebook se chama `arch` e o PC de casa,
`fedora`; máquina com outro nome precisa de um `.dotter/<nome>.toml`.

| Módulo | O que tem | `arch` (notebook, Hyprland) | `fedora` (casa, KDE) |
|---|---|---|---|
| `terminal` | bash, git, starship, fzf, mise, nvim, ghostty, fastfetch; clona e instala o `herdr-setup` | sim | sim |
| `ai` | omp e Claude Code (perfil pessoal), skills, scripts do `~/.local/bin` | sim | sim |
| `desktop` | fontes, webapps, WirePlumber (só A2DP no Bluetooth, sem pro-audio, mixer do Fuxi-H3) e a regra udev do Fuxi, config do syncfast | sim | sim |
| `hyprland` | Hyprland, portal, Noctalia, GTK, tema do Ghostty, greetd e o PAM dele | sim | não |
| `trabalho` | `vpn`, `ompe`, `SESSIONIZER_DIRS`, `omp-agendado-work`, perfil enterprise do omp | sim | não |

Cada pasta da raiz é um módulo. O que vai para onde está em
`.dotter/global.toml`; arquivo novo entra lá, no módulo certo. A lista de
pacotes da distro fica no módulo (`pacotes.arch.txt`, `pacotes.fedora.txt`) e o
`.dotter/post_deploy.sh` instala só o que falta (`yay`/`pacman` no Arch, `dnf`
no Fedora). Ele também copia para o `/etc`, com sudo, a regra udev do Fuxi e o
greetd, e faz o resto que não é link: gsettings, `gcr-ssh-agent`, perfil
enterprise, recarregar o Hyprland.

## Máquina nova

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
```

Instale o dotter: no Arch, `yay -S dotter-rs-bin`; no Fedora, que não tem pacote,
baixe o `dotter-linux-x64-musl` do
[último release](https://github.com/SuperCuber/dotter/releases/latest) para
`~/.local/bin/dotter` e dê `chmod +x`.

Na primeira vez, rode:

```bash
~/.dotfiles/.dotter/adotar.sh
```

Ele tira os links antigos que apontam para o repo (os do stow), guarda em
`~/.dotfiles-backup/<data>/` todo arquivo real que estiver no caminho de um
link e aplica. Nada é apagado: confira o backup e jogue fora o que não quiser.
Depois disso, para aplicar uma mudança, basta `cd ~/.dotfiles && dotter deploy`.

`DOTFILES_SO_LINKS=1 dotter deploy` cria só os links, sem instalar pacote nem
mexer no `/etc` ou na sessão.

### Casa (`fedora`)

Antes de confiar nas regras do Fuxi-H3 com o dongle, confira se ele aparece
igual ao cabo:

- `lsusb` mostra o ID `040b:0897`? É o que a regra udev procura.
- `wpctl status` mostra um dispositivo com `Fuxi-H3-00` no nome? É o que o
  `55-fuxi-soft-mixer.conf` procura.

Se algum dos dois for diferente, ajuste a regra antes de aplicar.

## Testes

`tests/maquinas.sh arch`, `tests/maquinas.sh fedora` e `tests/adotar.sh`
aplicam num HOME falso e conferem o que cada máquina recebe.

## Segredos

Ficam fora do repo, em `~/.env.local` (criado a partir do `.env.example` na
primeira aplicação) e `~/.bash_profile.local`.

## Visual

As decisões visuais do desktop (cor, forma, fonte, movimento, ícones) e onde
cada uma mora estão em [`docs/design-system.md`](docs/design-system.md).
