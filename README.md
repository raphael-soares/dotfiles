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

`bootstrap.sh` is idempotent and bootstraps `yay` if missing. It stows with
`--adopt -R` then `git restore .`, so the repo wins over existing local config
(old files discarded). After it runs, open tmux and press `prefix + I` to install
the plugins.

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

Docker stack that mirrors folders to Google Drive and keeps encrypted
incremental backups (rclone + restic). One-time docker setup per machine:
`sudo systemctl enable --now docker && sudo usermod -aG docker $USER` (relog).
Then:

```bash
cd ~/.dotfiles/gdrive-stack
./setup.sh
```

See [`gdrive-stack/README.md`](gdrive-stack/README.md).

## Scripts

| Script | Description |
|---|---|
| `acmit` | AI commit message generator (haiku / gemini-flash) |
| `vpn` | Connect to Unimed VPN via openfortivpn (work-specific: hardcoded conf + DNS) |
| `gdrive-stack/setup.sh` | Configure and start the Drive sync/backup stack |

## Neovim

[Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
