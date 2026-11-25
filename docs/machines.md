# Machines in detail

## What the deploy does besides links

`dotter deploy` only configures the home. `.dotter/post_deploy.sh` runs after
it, only for the modules the machine has, and never uses sudo, installs,
downloads or removes anything:

- sets gsettings, `gcr-ssh-agent`, the xdg-mime defaults and the Flatpak cursor
  override, and merges the Ghostty, Sunshine and Moonlight settings;
- pulls the secrets, restarts WirePlumber when its rules change, reloads Hyprland;
- links the work omp profile and runs `media-deploy` and `creative-deploy`;
- ends with `.dotter/missing.sh` for the same modules.

`.dotter/missing.sh [module...]` only reads the machine and prints what is
still to do by hand, one block per module, under "Still to do by hand:". With
no modules it takes the ones this machine deploys; a complete module prints
nothing. Each module lists its own steps in `<module>/manual.sh`:

- packages from `<module>/packages.<distro>.txt` (`dnf` on Fedora; on Arch one
  `yay` line, or without yay `pacman` for repo packages and the AUR names apart);
- apps from `<module>/flatpaks.txt`, in the user installation. User apps go
  here, so both machines get the same version and name. What talks to the
  system (portals, Sunshine, Moonlight, Flameshot, Nautilus) stays native;
- system files (udev rule, greetd config and PAM file, Sunshine units, sshd
  drop-in, EDID), services to enable, firewall rules, linger, `setcap`, the
  kernel argument and the tuned profile, each as the `sudo` command to run;
- what the repo does not package: Spotifast and ZapFast rpms, Stremio Enhanced
  (`media/install/stremio-enhanced`, fedora only), Arr Pick, herdr-setup, the syncfast
  Nautilus extension, the omp plugin and the Bitwarden MCP for Claude Code.

Run the printed commands, then `missing.sh` again until it prints nothing.
A step for a distro the machine does not run is never printed. Packages or apps
dropped from a list are not uninstalled.

`DOTFILES_LINKS_ONLY=1 dotter deploy` creates only the links.

## First run

`.dotter/adopt.sh` removes old links into the repo (from stow), moves every
real file in the way to `~/.dotfiles-backup/<date>/` and deploys. Nothing is
deleted.

## Hyprland per machine

`hyprland` is the same config on both machines. What only one of them needs
lives in its `~/.config/hypr-machine/machine.lua`, linked by `laptop` on `arch`
and by `home` on `fedora`. It returns `monitors` (fields by output name, read by
`monitors.lua`) and `setup`, which `hyprland.lua` calls last. A field a machine
leaves out comes from the wildcard rule (`highrr`, `auto`, scale 1), so the LG
UltraGear runs at 144 Hz on both machines without a rule of its own; the laptop
only declares where each screen sits.

A rule with `shared = { model = ..., peer_input = ... }` (the monitor's model as
`ddcutil detect` names it, and its DDC input code for the other machine's cable)
starts `bin/monitor-away`, which asks that monitor every second which input it
shows. While it shows the other machine, `monitors.lua` turns the output off and
the laptop works on its own screen; the lid still counts it as plugged in. When
it switches back, the output returns and `laptop/hypr/machine.lua` moves
workspaces 1 to 10 onto it. A monitor that stops answering is turned back on
after 10 s. Reading the input needs the `i2c` group on Arch (the deploy adds
it). To find a code: `ddcutil --brief getvcp 60` with the monitor on each input.

Noctalia works the same way. `hyprland/noctalia/base.toml` is the shared
base in `~/.config/noctalia/`, with the default theme (Gruvbox, dark) and
wallpaper. Each machine links its own `machine.toml` next to it
(`laptop/noctalia/machine.toml` or `home/noctalia/machine.toml`) for settings
that belong to that machine: idle, hooks, greeter sync, the desktop's center
section and hidden battery widget. Noctalia merges every `*.toml` there in name
order, so `machine.toml` wins over `base.toml`. Arrays are replaced, not merged:
a machine sets a whole widget list only when it really differs from the base.

The repo keeps no state. Noctalia's interface writes theme, wallpaper and bar
changes to `~/.local/state/noctalia/settings.toml`, a plain file on each
machine that wins over the config and never reaches git. To make a change the
new default, copy the key into the base or the machine's `machine.toml`.

One app file stays a real file instead of a link, because the app rewrites it:
`~/.config/ghostty/config` (Noctalia's Ghostty template edits its theme line) only
includes the linked `base` and `machine.conf`.

## Fuxi-H3 on the `fedora` machine

Before trusting the rules with the dongle, check that it shows up like the
cable does:

- `lsusb` lists ID `040b:0897` (what the udev rule matches);
- `wpctl status` lists a device named `Fuxi-H3-00` (what
  `55-fuxi-soft-mixer.conf` matches).

## Secrets

Secret files never enter the repo. Each one is an item in the Bitwarden folder
`dotfiles`: the item name is its path under `$HOME` and the notes hold the
content. `secrets` (in `terminal/bin`, on both machines) moves them with `rbw`:

- `secrets setup` once per machine: email, 8 hour unlock, `rbw` and `bw` login;
- `secrets pull` writes every item to its path with mode 600 (the deploy runs
  it);
- `secrets push <file>` stores a file in the vault (new or changed);
- `secrets check` needs no unlocked vault and reports a secret file others can
  read, one not in the vault (`~/.config/secrets/*`, `~/.config/media/media.env`,
  `~/*/Env/*.env`, `~/*/Envs/*.env`) or one missing here; `media-drift` runs it.

`~/.config/secrets/shell.env` is loaded by the bashrc (keep it to keys every
shell needs). The VPN reads `~/Documents/Unimed/Envs/vpn.env`. A project loads its own
`.env` with direnv (`.envrc` with `dotenv ~/Documents/TEAjudo/Env/api-local.env`). The
`Env` and `Envs` folders are not synced to Google Drive. `~/.bash_profile.local`
stays a local file.

`vault` (also `terminal/bin`) is the vault for people and agents: `ls`,
`folders` and `dupes` print metadata only, `mv`/`rename`/`rm` organize, `add`
stores a generated or file/variable secret without echoing it, and
`vault run <item> VAR -- cmd` hands one secret to one command. The `cofre` skill
holds the agent rules. The official Bitwarden MCP server is registered for omp
(`ai/.omp/agent/mcp.json`) and Claude Code (post-deploy) for what `vault` lacks.

## Tests

`tests/machines.sh arch`, `tests/machines.sh fedora` and `tests/adopt.sh`
deploy into a fake HOME and check what each machine gets.
Every PR and push to `main` runs `.github/workflows/checks.yml`: all of
`tests/`, shellcheck at warning level and gitleaks on the tree and the new
commits. Merge only when it is green.

## Visual

Desktop design decisions live in [`design-system.md`](design-system.md).
