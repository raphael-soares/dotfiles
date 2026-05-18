# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Config |
|---|---|
| `tmux` | `~/.config/tmux/` |
| `alacritty` | `~/.config/alacritty/` |
| `git` | `~/.gitconfig` + `~/.config/git/` |
| `starship` | `~/.config/starship.toml` |
| `fzf` | `~/.config/fzf/fzf.sh` |

## Setup

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow tmux alacritty git starship fzf
```

### tmux plugins

Plugins are managed by [TPM](https://github.com/tmux-plugins/tpm) — install separately:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# inside tmux: prefix + I to install plugins
```

### Alacritty font

Requires [JetBrainsMono Nerd Font](https://www.nerdfonts.com/).

## Highlights

**tmux**
- Prefix: `C-Space`
- Vi mode keys for pane navigation (`h/j/k/l`)
- Sessionizer: `prefix + f`
- SSH sessionizer: `prefix + S`
- Popup terminal: `C-_`

**fzf**
- Theme-agnostic ANSI palette
- tmux-centered popup (40% width, 50% height)

**git**
- Editor: `nvim`
- Merge tool: `nvimdiff` with `LOCAL,BASE,REMOTE / MERGED` layout

## Neovim

Managed in a separate repo.
