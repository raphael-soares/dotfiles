# dotfiles

Arch Linux dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

One command installs every dependency through `yay` (repos + AUR), clones TPM,
and stows everything:

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

`bootstrap.sh` is idempotent and bootstraps `yay` itself if it's missing. It stows
with `--adopt -R` followed by `git restore .`, so the repo's config wins over any
config the machine already had (the old local files are discarded). After it runs,
start tmux and press `prefix + I` to install the tmux plugins.

### Manual stow

If you only want to re-link configs without touching packages:

```bash
stow bash tmux alacritty git starship fzf local mise   # or add --adopt -R to override
```

**Packages installed** (see `bootstrap.sh` for the full list): stow, github-cli,
tmux, alacritty, starship, fzf, mise, neovim, jq, openfortivpn,
ttf-jetbrains-mono-nerd, docker, docker-compose, rclone, and from the AUR
claude-code.

## Google Drive sync + backup

Stack Docker que espelha pastas pro Google Drive e mantém backups incrementais
encriptados (rclone + restic). Setup com um comando:

```bash
cd ~/.dotfiles/gdrive-stack
./setup.sh
```

`setup.sh` gera o `.env`, faz o OAuth do Drive no navegador e sobe o container.
Depois é só editar `gdrive-stack/config/jobs.yaml` com o que sincronizar/backupar.
Detalhes em [`gdrive-stack/README.md`](gdrive-stack/README.md).

Pré-requisito do docker (uma vez por máquina): `sudo systemctl enable --now docker`
e `sudo usermod -aG docker $USER` (relogue).

## Scripts

| Script | Description |
|---|---|
| `acmit` | AI commit message generator (haiku / gemini-flash) |
| `vpn` | Connect to Unimed VPN via openfortivpn (work-specific: hardcoded conf + DNS) |
| `gdrive-stack/setup.sh` | Configura e sobe o stack de sync/backup no Google Drive |

## Neovim

[Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
