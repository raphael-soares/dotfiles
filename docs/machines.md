# Machines in detail

## What the deploy does besides links

`dotter deploy` only configures the home. `.dotter/pre_deploy.sh` runs before
it and makes `~/Documents` and `~/Pictures/Wallpaper` links into `~/Drive`, so
dotter never meets a real folder there. `.dotter/post_deploy.sh` runs after
it, only for the modules the machine has, and never uses sudo, installs or
downloads anything. The only thing it removes is Ghostty's own `config.ghostty`
when it holds nothing but comments. A step that fails prints `==> failed: ...`
and the next ones still run:

- sets gsettings, `gcr-ssh-agent`, the xdg-mime defaults and the Flatpak cursor
  override, and merges the Ghostty, Sunshine and Moonlight settings;
- runs `secrets check`, restarts WirePlumber when its rules change, reloads Hyprland;
- links the work omp profile (including `mcp.json` and `agents`) and runs
  `media-deploy` and `creative-deploy`;
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
  Nautilus extension and the omp plugin.

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
after 10 s. Reading the input needs the `i2c` group on Arch (`missing.sh` prints
the command). To find a code: `ddcutil --brief getvcp 60` with the monitor on each input.

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

Greetd is shared too: `hyprland/manual.sh` installs `/etc/greetd/config.toml`
(the greeter account is `greeter` on Arch and `greetd` on Fedora) and enables
the service; `laptop` and `home` only add their own PAM file.

## Fuxi-H3 on the `fedora` machine

Before trusting the rules with the dongle, check that it shows up like the
cable does:

- `lsusb` lists ID `040b:0897` (what the udev rule matches);
- `wpctl status` lists a device named `Fuxi-H3-00` (what
  `55-fuxi-soft-mixer.conf` matches).

## Secrets

The owner's machine secrets live in the Bitwarden folder `Dotfiles`, read and
written through `rbw` only. The item name says where it lands: `env personal`
(shell and VPN), `env aws`, `env media`, `ssh config`, `ssh config.d/<name>.conf`
and `ssh key <name>`. Anything else in the folder is left alone. The repository
holds no secret, not even encrypted. The Bitwarden master password is the only
thing a new machine needs.

A new machine: `rbw unlock`, then `dotter deploy`. `missing.sh terminal` prints
`rbw unlock && secrets pull` while the local copies are absent.

- edit an item in the Bitwarden app, then run `secrets pull`;
- `secrets put "<item>" <file>` (or stdin) creates or replaces an item without
  printing it; that is how agents and scripts store a new key or token;
- `secrets pull` syncs the folder and writes each item to its place, mode 600,
  only when it changed: `~/.ssh` (deriving each key's `.pub`) and local copies of
  the `env` items in `~/.local/state/secrets/`. The deploy runs
  `secrets pull --if-unlocked`, so it never asks for the password: with `rbw`
  locked it keeps what is already on disk. `known_hosts`, `authorized_keys` and
  other local files are left alone; the `sshd` module adds `personal.pub` to
  `authorized_keys`, so both machines reach each other;
- `secrets run -- <command>` runs the command with `env personal` as variables
  (`vpn` uses it; the bashrc never loads it at shell start);
- `media-deploy` writes `~/.config/media/media.env` (mode 600) from `env media`
  and, when it generates a key, stores it back with `secrets put`;
- `secrets aws` prints `env aws` as the JSON of `credential_process`, which
  `terminal/aws/config` uses for the default profile; it works from services and
  scheduled jobs because it reads the local copy;
- `secrets check` reports missing local copies, a secret file others can read, a
  plain-text credential left in the home (`~/.netrc`, an AWS credentials file, a
  `.env` with a key, token or password outside `~/Code`) and, with `rbw`
  unlocked, a key in `~/.ssh/keys` with no vault item; the deploy and
  `media-drift` run it.

The copies on disk (`~/.ssh`, the state folder, `media.env`) are plain on
purpose: the media stack and SSH between the machines run with nobody logged in.
Design: `docs/superpowers/specs/2026-11-26-segredos-no-cofre-design.md`.

Code projects keep their secrets in the project's own store (TEAjudo: AWS SSM under
`/teajudo/<env>/`) and a gitignored local `.env` made from `.env.example`, holding no
secret. Neither goes through `secrets` or the vault. `vault env <note> <file>` writes
any secure note back to a file (mode 600) without printing it.
`~/.bash_profile.local` stays a local file.

The session environment (XDG base directories, the variables that move
dotfiles there, such as `AWS_CONFIG_FILE`, `GNUPGHOME` and `GOPATH`, plus `PATH`,
`EDITOR` and `BROWSER`) lives in `terminal/env/session.conf`. `BROWSER` is the
`zen` wrapper in `terminal/bin`, since a value with spaces cannot go in that
file. The AWS CLI needs no credentials variable: `terminal/aws/config` resolves the
key through `credential_process`. The shells source the file once per login
(`SESSION_ENV` marks it). systemd reads it as `environment.d` for user services,
`~/.profile` sources it for the graphical login and the bashrc for every shell, so
a service or a program started from Hyprland sees the same paths as a terminal.
A change there reaches the graphical session and the user services after a new login.

`vault` (also `terminal/bin`) is the vault for people and agents, on `rbw`:
`ls`, `folders` and `dupes` print metadata only, `rm` deletes, `add` stores a
generated or file/variable secret without echoing it, `note` and `env` move a
file in and out of an item's notes, and `vault run <item> VAR -- cmd` hands one
secret to one command. The `cofre` skill holds the agent rules. `rbw` is the
only Bitwarden client: one login, unlocked for 8 hours. Moving an item to
another folder and renaming it are done in the Bitwarden app, since `rbw`
cannot.

## Tests

Tests cover only what fails silently and costs a lot: the deploy, the secrets
and the scripts that move or delete files on their own. The rest (configs,
helpers, skill tooling) breaks where you see it and has no test. Each script
runs on its own with `bash tests/<name>.sh`:

- `machines.sh arch|fedora` and `adopt.sh` deploy into a fake HOME and check
  the links, the rendered hook and the `~/Documents` and `~/Pictures/Wallpaper`
  links each machine gets;
- `secrets.sh` covers `secrets check`, `ssh`, `init`, `aws` and the stray-file scan;
- `media_deploy.sh` covers the media stack deploy and its per-service secrets;
- `media_cleanup.sh` and `triage.sh` cover what deletes or moves files.

Every PR and push to `main` runs `.github/workflows/checks.yml`: all of the
above, shellcheck at warning level and gitleaks on the tree and the new
commits. Merge only when it is green. The scripts that stub `PATH` call the real
`bash` and `env` through `type -P`, because a harness with its own builtins
would otherwise ignore the stubs.

## Visual

Desktop design decisions live in [`design-system.md`](design-system.md).
