# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
cp .env.example ~/.env.local
stow bash tmux alacritty git starship fzf local mise
```

**Deps:**
- [TPM](https://github.com/tmux-plugins/tpm) — `prefix + I` to install plugins
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)
- [mise](https://mise.jdx.dev/)

## Scripts

| Script | Description |
|---|---|
| `claudecommit` | AI commit message generator (haiku / gemini-flash) |
| `vpn` | Connect to Unimed VPN via openfortivpn |

## Neovim

[Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
