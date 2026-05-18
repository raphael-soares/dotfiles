# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Config |
|---|---|
| `bash` | `~/.bashrc` |
| `tmux` | `~/.config/tmux/` |
| `alacritty` | `~/.config/alacritty/` |
| `git` | `~/.gitconfig` + `~/.config/git/` |
| `starship` | `~/.config/starship.toml` |
| `fzf` | `~/.config/fzf/fzf.sh` |
| `local` | `~/.local/bin/claudecommit`, `~/.local/bin/vpn` |

## Setup

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
cp .env.example ~/.env.local   # fill in your secrets
stow bash tmux alacritty git starship fzf local
```

### Secrets

`~/.env.local` is sourced automatically by `.bashrc`. Copy the example and fill in your values:

```bash
cp .env.example ~/.env.local
# edit ~/.env.local and add your keys
```

### tmux plugins

Plugins are managed by [TPM](https://github.com/tmux-plugins/tpm) — install separately:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# inside tmux: prefix + I to install plugins
```

### Alacritty font

Requires [JetBrainsMono Nerd Font](https://www.nerdfonts.com/).

## Scripts (`~/.local/bin`)

### `claudecommit`

Interactive conventional commit message generator powered by AI.

- Uses `claude-haiku` by default
- Uses `gemini-2.5-flash` if `GEMINI_API_KEY` is set in `~/.env.local`
- Generates 3 suggestions from staged/unstaged diff
- Navigate with `j/k` or arrow keys, pick with Enter or `1/2/3`
- Press `e` to edit before committing

```bash
git add -A
claudecommit
```

### `vpn`

Connects to the Unimed VPN via `openfortivpn` and configures full-tunnel DNS.

- Requires config at `/etc/openfortivpn/unimed.conf` (not in repo — contains credentials)
- Waits for `ppp0` interface, then sets DNS servers `10.36.1.15` / `10.36.1.16`
- Cleans up DNS on disconnect

```bash
vpn
```

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

Managed in a separate repo: [Raphael-Soares/nvim](https://github.com/Raphael-Soares/nvim)
