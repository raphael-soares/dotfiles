## Install

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles && \
cd ~/.dotfiles && \
./install.sh
```

Cada pasta da raiz é uma ferramenta, um pacote do stow. Para pegar só uma, sem
o resto: `git clone` do repo e `stow -t ~ <pasta>` de dentro dele.

| Pacote | O que faz | Precisa de | Observação |
|---|---|---|---|
| `bash` | `.bashrc` (histórico, aliases, PATH, mise, fzf, starship) e `.bash_profile` | bash | carrega `~/.config/shell/rc.d/*.sh`, `~/.env.local` e `~/.bash_profile.local` quando existem |
| `alacritty` | config do terminal e temas | alacritty, JetBrainsMono Nerd Font | usa `oneblack` e, por cima, o `noctalia.toml` quando ele existir (o Noctalia gera só no notebook) |
| `tmux` | `tmux.conf`, sessionizer de projetos (`prefix + Tab`), de ssh e integração com o workmux | tmux, fzf | o sessionizer lê `TMUX_SESSIONIZER_DIRS`; sem ela varre o home |
| `nvim` | config do Neovim com lazy.nvim, LSP, DAP e Java | neovim, git | os plugins se instalam na primeira abertura |
| `git` | `.gitconfig` (nvimdiff, credencial pelo `gh`) e ignore global | git, gh | o `[user]` tem nome e e-mail do Raphael: troque |
| `fzf` | opções e cores do fzf, por índice ANSI | fzf | |
| `starship` | prompt | starship | |
| `mise` | versões globais de node, python, java e lua | mise | |
| `workmux` | config global do workmux (worktrees em `~/.workmux`) | workmux | |
| `ai` | AGENTS.md, skills, omp, Claude Code e `~/.local/bin/omp-jdtls` | omp, claude, jq | pessoal, vale como referência; o `lsp.json` tem um caminho absoluto do home do Raphael |
| `gtk` | `settings.ini` do GTK 3 e 4 (tema escuro, fonte, cursor) | adw-gtk-theme | |
| `fontes` | fontconfig: Inter como sans-serif, JetBrainsMono Nerd Font como monospace | as duas fontes | |
| `webapps` | atalhos `.desktop` e ícones do Spotify e do WhatsApp | `spotifast` e `zapfast` no PATH | |
| `hypr` | Hyprland em Lua e o portal do xdg | hyprland, xdg-desktop-portal-hyprland | |
| `noctalia` | plugins, estado e wallpaper do Noctalia | noctalia | o estado tem caminhos do Raphael: referência, não para instalar |
| `audio` | WirePlumber só com A2DP no Bluetooth: caixa BT não cai em mono 16 kHz, mas nenhum fone BT tem microfone | pipewire, wireplumber | |
| `vpn` | `~/.local/bin/vpn up\|down\|status`, VPN Fortinet SSL pelo NetworkManager | networkmanager-fortisslvpn | lê os `VPN_*` do `~/.env.local` |
| `raphael` | `TMUX_SESSIONIZER_DIRS`, `ompe`, config do syncfast e atalho do Alacritty | | só do Raphael |

O `install.sh` agrupa os pacotes e, rodado sem argumento, pergunta grupo por
grupo. Dá para passar direto (`./install.sh terminal ai`):

| Grupo | Pacotes do stow | Distros |
|---|---|---|
| `terminal` | bash tmux alacritty git starship fzf mise nvim workmux | Arch, Fedora |
| `ai` | ai | Arch, Fedora |
| `desktop` | gtk fontes webapps | Arch, Fedora |
| `hyprland` | hypr noctalia | Arch |
| `audio` | audio | Arch, Fedora |
| `sistema` | nenhum: copia `sistema/` para `/etc` com sudo | Arch |
| `vpn` | vpn | Arch, Fedora |
| `raphael` | raphael | Arch, Fedora |

`hyprland` e `sistema` são só Arch: em outra distro o `install.sh` avisa e pula.
Os pacotes da distro de cada grupo estão em `packages/<grupo>.<distro>.txt` e
são instalados só se faltarem (`yay`/`pacman` no Arch, `dnf` no Fedora).
`--sem-pacotes` só linka os arquivos.

Segredos ficam fora do repo, em `~/.env.local` (criado a partir do
`.env.example`) e `~/.bash_profile.local`. O resto do que é pessoal está no
pacote `raphael`.

## Visual

As decisões visuais do desktop (cor, forma, fonte, movimento, ícones) e onde
cada uma mora estão em [`docs/design-system.md`](docs/design-system.md).
