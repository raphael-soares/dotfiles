# The deploy applies configuration; the owner installs

## Why

The repo is where configuration lives. Over time `.dotter/post_deploy.sh` grew into
a package manager: it installs and removes dnf, pacman, AUR and Flatpak packages,
enables COPRs, downloads release files, and runs sudo for kernel, boot and system
service changes. A deploy can uninstall something the owner installed for another
reason, and every deploy asks for a password, so it can never run unattended.

The owner decides what enters or leaves the system. The repo may tell him what a
machine still needs, as commands ready to paste, for the distro he is on.

## Rule

- Anything in the user's home that only configures is applied automatically.
- Anything that needs sudo, installs, or downloads is a red flag: it leaves the repo,
  or it becomes a printed command the owner runs by hand.
- Nothing removes packages.

## Goals

- `dotter deploy` never calls sudo, never installs, never downloads a package, release
  file or repository.
- Each module is atomic: it works on its own, and its manual steps stand on their
  own. The owner may want only part of the dotfiles, so a module's commands include
  everything that module needs (its COPR, the Flathub remote, its packages, its
  system steps) and nothing from another module.
- One command lists what still needs doing by hand, as one block per module, adapted
  to the distro: `sudo pacman -S` / `yay -S` names from `packages.arch.txt` on Arch,
  `sudo dnf install` names from `packages.fedora.txt` on Fedora, `flatpak install`
  for Flathub apps. It takes module names to show only those; without them it shows
  the modules this machine deploys.
- It prints only what is not applied yet. A module with everything in place prints
  nothing, not even its header.
- The deploy runs that command at the end, so a deploy still shows what is missing.

## Non-goals

- No removal lists, no cleanup of old installs.
- No change to what each machine is configured to do: same modules, same files.
- No interactive "run it for me?" prompt.

## Anti-goals

- A printed command that does something other than what it says, or that the owner
  cannot read and understand in one line.
- Commands printed every deploy for things already in place (noise that teaches the
  owner to ignore the block).
- Losing a fix silently: when a manual step is missing, the block says so until it is
  applied.

## Layers

| Layer | What | How |
|---|---|---|
| 1. Automatic | links; `gsettings`, `xdg-mime`; `systemctl --user`; settings merged into real files (pcmanfm-qt, Moonlight, sunshine.conf, apps.json, ghostty); `flatpak override --user`; secrets pull | `post_deploy.sh`, as today |
| 2. Manual | packages, Flatpaks, the Flathub remote, COPRs; Spotifast and ZapFast rpms; Stremio Enhanced; Arr Pick; herdr-setup clone; syncfast Nautilus extension; superpowers omp plugin; every sudo step (below) | printed by the new command |
| 3. Out | `remove.*.txt`, `remove_packages`; uninstalling Flathub Stremio and Haruna; removing the nett00n COPR; deleting `manual-pick.plugin.*` | deleted |

Sudo steps that move to layer 2:

- files copied into `/etc` and `/usr/lib/firmware`: the Fuxi-H3 udev rule, greetd
  `config.toml` (rendered per distro), greetd PAM (laptop and home), sshd
  `50-key-only.conf`, the Sunshine system units (rendered with user, uid, home),
  the LG EDID and `dracut.conf.d/edid.conf`;
- what follows a changed file: `udevadm control --reload`, `systemctl daemon-reload`
  and restart, `systemctl reload sshd`, `dracut -f --regenerate-all`;
- `systemctl enable --now` of sunshine-prelogin, remote-serving, sshd, avahi-daemon;
  `systemctl enable --force greetd`;
- firewall ports: Sunshine, ssh and mDNS, 7878 and 8990;
- `usermod -aG i2c`, `loginctl enable-linger`, `setcap cap_sys_admin+p` on sunshine;
- `grubby` DP-1 EDID kernel argument; `tuned-adm profile throughput-performance`.

## Approaches

1. **One command that prints one block per module, also run at the end of the deploy.**
   Chosen. The owner copies the block of the module he wants, and can rerun the
   command alone, for one module (after a Sunshine update drops `setcap`, say).
2. Each step prints its own command inside the deploy. Rejected: commands end up
   scattered among other output and the owner has to collect them.

## Decided

- Arch: with `yay` present the package line is `yay -S --needed …` (it takes repo and
  AUR packages); without it, `sudo pacman -S --needed …` with the names `pacman`
  knows, and a note listing the rest as AUR.
- Fedora: `sudo dnf install …`; COPRs come before the packages that need them.
- Unknown distro: list the package names and say to install them by hand (as today).
- Order inside a module's block: repositories, packages, Flatpaks, downloads, system
  steps. A step two modules need (the Flathub remote, say) appears in each of them; it
  is idempotent, so running both blocks is safe.
- A file in `/etc` is "missing" when it differs from the repo (or the rendered
  template); its command copies it and runs what reloads it.
- Removal lists are deleted, not turned into commands. Existing leftovers (the
  nett00n COPR, Flathub Stremio, Haruna) stay until the owner removes them.
- A step belongs to the module that installs what it configures (owner's call):
  - the greetd config and PAM go to `laptop` and `home`, which install greetd;
  - the syncfast Nautilus extension goes to `hyprland`, with the syncfast Flatpak;
  - Spotifast and ZapFast (Fedora rpms, Arch AUR names) go to `hyprland`, with
    their window rules and autostart;
  - Arr Pick stays in `hyprland` with Stremio Enhanced: Radarr may be on another
    machine and the plugin only needs its URL.
- Exception (owner's call): media-deploy keeps pulling its container images and the
  whisper model by itself. Running the media stack is its configuration and it uses
  no sudo. The firewall ports before it become a manual step of `media`.
- Also manual: `omp plugin install` (`ai`, `work`), `claude mcp add bitwarden` (it runs
  `npx`), and `herdr-setup/install.sh` after its clone. `warn_missing` and the Nerd
  Font notice become entries in their module's block. `systemctl --user mask fumon`
  stays automatic.

My calls (owner may override):

- The command reads the module list from dotter's config for this machine
  (`.dotter/local.toml` and what it includes); a module named explicitly is checked
  even if this machine does not deploy it.
- A distro-specific step prints nothing on the other distro.
- Restart and reload follow from state: the command keeps a hash of each applied file
  in `$STATE` (as wireplumber does today), and prints the reload while the hash is
  stale. The kernel argument is read from `/proc/cmdline`; firewall ports with
  `firewall-cmd --query-port` (no root on Fedora). A check that cannot run prints the
  step with "could not check".
- Layer-1 steps whose tool is missing are skipped quietly; the module's block already
  lists the missing package.
- Arr Pick: the check is local (plugin file present). On a machine whose `gh` cannot
  read the private repo the command is still printed, with a note that it needs that
  access.
- Arch without `yay`: `pacman -Si` against the local sync database tells repo names
  from AUR names.

## Constraints

- Works on both machines (Arch laptop, Fedora desktop) and any module combination;
  module conditions stay as dotter renders them.
- Checks are read-only and need no network and no sudo (`rpm -q`, `pacman -T`,
  `flatpak info`, `cmp`, `systemctl is-enabled`, `getcap`, `id -nG`, `loginctl`,
  `grubby` and `firewall-cmd` read access permitting).
- The deploy must not fail because something manual is missing.

## Left to the builder

- Name and place of the command, and how it shares module conditions with dotter.
- How each check reads state without root, and the fallback when a check needs root
  (print the step with a note that it could not be checked).
- How "latest release" is checked without network for the downloads, and what the
  printed command for each download looks like.
- How the command's checks are stubbed so `tests/machines.sh` can assert each
  machine's blocks in the fake home, replacing today's greps of the rendered hook.
- Updating `tests/machines.sh`, `docs/machines.md`, `README.md` and the per-module
  docs that describe installing.
