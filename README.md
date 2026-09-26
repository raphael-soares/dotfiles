## Install

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles && \
cd ~/.dotfiles && \
./install.sh
```

Cada pasta da raiz é um pacote do stow. O `install.sh` agrupa os pacotes em
camadas e, rodado sem argumento, pergunta quais instalar. Dá para passar direto
(`./install.sh terminal ai`):

| Camada | O que entra | Onde |
|---|---|---|
| `terminal` | bash, tmux, nvim, git, fzf, starship, mise, alacritty, workmux, `~/.local/bin` | qualquer máquina |
| `ai` | AGENTS.md, skills, omp e Claude Code | qualquer máquina |
| `desktop` | Hyprland, Noctalia, tema GTK/portal | máquina com Hyprland |
| `audio` | WirePlumber só com A2DP no Bluetooth: caixa BT não cai em mono 16 kHz, mas nenhum fone BT tem microfone | máquina que precisa disso |
| `sistema` | greetd, PAM do greetd, plymouth, copiados para `/etc` com sudo | máquina com Hyprland |

Os pacotes de cada camada estão em `packages/<camada>.txt` e são instalados com
`yay` (ou `pacman`) só se faltarem. `--sem-pacotes` só linka os arquivos.

O que é só de uma máquina fica fora do repo: `~/.env.local` (criado a partir do
`.env.example`) e `~/.bash_profile.local`.
