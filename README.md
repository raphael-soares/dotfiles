# dotfiles

Terminal, desktop and agent config for my two machines, applied with
[dotter](https://github.com/SuperCuber/dotter).

## Install

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
.dotter/adopt.sh    # first run: backs up anything in the way, then links
dotter deploy       # every run after that
```

Get dotter with `yay -S dotter-rs-bin` on Arch, or from the
[releases](https://github.com/SuperCuber/dotter/releases/latest) elsewhere.

## Machines

dotter picks `.dotter/<hostname>.toml`.

| Module | What it is | `arch` | `fedora` |
|---|---|---|---|
| `terminal` | shell, git, editor, prompt, Ghostty | ✓ | ✓ |
| `ai` | omp, Claude Code, skills | ✓ | ✓ |
| `desktop` | fonts, web apps, audio, syncfast | ✓ | ✓ |
| `hyprland` | Hyprland, Noctalia, GTK, greetd | ✓ | |
| `work` | VPN and the work omp profile | ✓ | |
| `home` | SSH, Sunshine and autologin, so the laptop can reach it ([remote access](docs/remote-desktop.md)) | | ✓ |

## Add a file

Put it in its module folder and map it in `.dotter/global.toml`.

More in [`docs/`](docs/machines.md).
