# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
cp .env.example ~/.env.local
stow bash tmux alacritty git starship fzf local mise
```

### Existing configs conflict?

If a machine already has its own configs (e.g. a default `.bashrc`), plain `stow`
aborts with conflicts. To force the repo to win over whatever was there before:

```bash
stow --adopt -R bash tmux alacritty git starship fzf local mise
git restore .
```

`--adopt` pulls each conflicting file into the repo and replaces it with a symlink;
`git restore .` then resets those files back to the committed versions, so every
symlink points at the repo's config. Your old local files are discarded.

**Deps:**
- [TPM](https://github.com/tmux-plugins/tpm) — clone into the XDG path the config
  expects, then hit `prefix + I` inside tmux to install plugins:
  ```bash
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
  ```
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)
- [mise](https://mise.jdx.dev/) — installed however you like (AUR, `pacman`, or the
  official installer). `.bashrc` resolves it from `PATH`, so the binary location
  doesn't matter.

## Scripts

| Script | Description |
|---|---|
| `acmit` | AI commit message generator (haiku / gemini-flash) |
| `vpn` | Connect to Unimed VPN via openfortivpn (work-specific: hardcoded conf + DNS) |

## Neovim

[Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
