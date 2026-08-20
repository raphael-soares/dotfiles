# dotfiles

Config de terminal, gerenciada com [GNU Stow](https://www.gnu.org/software/stow/).
Só linha de comando: nada de desktop, gerenciador de janelas ou app gráfico.
O `bootstrap.sh` instala os pacotes via `yay` (Arch), mas os configs em si rodam
em qualquer Unix.

## Setup

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

O `bootstrap.sh` é idempotente: instala os pacotes, gera os locales, clona o TPM
e faz o stow. Ele aborta se o `yay` não estiver instalado. O stow roda com
`--adopt -R` seguido de `git restore .`, então o repo ganha de qualquer config
local que já exista (o arquivo antigo é descartado). Depois que terminar, abra o
tmux e aperte `prefix + I` para instalar os plugins.

### Stow manual

Para só refazer os links, sem mexer em pacote:

```bash
stow bash tmux alacritty git starship fzf local mise nvim ai
# use --adopt -R para sobrescrever config local existente
```

## Pacotes

Instalados pelo `bootstrap.sh` via `yay`: `stow`, `git`, `github-cli`, `tmux`,
`alacritty`, `starship`, `fzf`, `mise`, `neovim`, `jq`, `curl`, `openfortivpn`,
`ttf-jetbrains-mono-nerd` e, do AUR, `claude-code` e `opencode`. O
`@earendil-works/pi-coding-agent` vem por `npm -g`.

Runtimes (node, python, java, lua) ficam com o mise, em
`mise/.config/mise/config.toml`.

## Scripts

| Script | O que faz |
|---|---|
| `acmit` | Sugere três mensagens de commit a partir do diff. Usa a API do Gemini se `GEMINI_API_KEY` estiver setada, senão o Claude Code. |
| `vpn` | Conecta na VPN da Unimed com openfortivpn. Específico do trabalho: conf e DNS chumbados. |

Segredo fica em `~/.env.local`, que o `.bashrc` carrega no fim. O
`bootstrap.sh` cria o arquivo a partir do `.env.example` na primeira execução.

## Neovim

[Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
