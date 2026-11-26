# dotfiles

Terminal, desktop and agent config for my two machines, applied with
[dotter](https://github.com/SuperCuber/dotter).

## Install

```bash
git clone git@github.com:Raphael-Soares/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
.dotter/adopt.sh    # first run: backs up anything in the way, then links
dotter deploy       # every run after that
.dotter/missing.sh  # what is still to do by hand: packages, sudo steps
```

The deploy only configures the home: it never uses sudo or installs anything.
It ends by printing the commands still to run by hand, which
`.dotter/missing.sh` also prints on its own ([details](docs/machines.md)).

Get dotter with `yay -S dotter-rs-bin` on Arch, or from the
[releases](https://github.com/SuperCuber/dotter/releases/latest) elsewhere.

## Machines

dotter picks `.dotter/<hostname>.toml`.

| Module | What it is | `arch` | `fedora` |
|---|---|---|---|
| `terminal` | shell, git, editor, prompt, Ghostty | ✓ | ✓ |
| `ai` | omp, Claude Code, skills | ✓ | ✓ |
| `desktop` | fonts, web apps, audio, syncfast | ✓ | ✓ |
| `hyprland` | Hyprland, Noctalia, GTK, greetd and remote access between the two machines ([remote access](docs/remote-desktop.md)) | ✓ | ✓ |
| `laptop` | the laptop's monitors and lid, the greetd PAM file | ✓ | |
| `work` | VPN and the work omp profile | ✓ | |
| `sshd` | key-only SSH and mDNS, so each machine reaches the other ([remote access](docs/remote-desktop.md)) | ✓ | ✓ |
| `home` | the desktop's monitor, EDID override, greetd PAM file, Noctalia settings, and suspend with wake on LAN instead of power-off ([wake on LAN](docs/wake-on-lan.md)) | | ✓ |
| `media` | Jellyfin, Radarr, Sonarr, Prowlarr and Bazarr as Docker containers, plus qBittorrent and Jellyfin Desktop; releases are picked in Stremio Enhanced ([media](docs/media.md)) | | ✓ |
| `creative` | omp drives the ArtCraft apps (VectorCraft, PhotoCraft and the rest), without a window by default ([creative](docs/creative.md)) | | ✓ |

## Add a file

Put it in its module folder and map it in `.dotter/global.toml`. A package or a
step to run by hand goes in the module's `packages.<distro>.txt`, `flatpaks.txt` or
`manual.sh`. A test in `tests/` only when a failure would be silent and costly
(secrets, deploy, deleting or moving files). Secrets go in the Bitwarden folder
`Dotfiles` (`secrets put`), never in the repository.

More in [`docs/`](docs/machines.md); where each folder of the home lives is in
[`docs/home.md`](docs/home.md).
