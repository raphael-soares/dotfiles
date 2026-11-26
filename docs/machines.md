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

The owner's secrets live encrypted with sops and age in `secrets/`:
`personal.env` for the shell and the VPN, `media.env` for the media stack,
`aws.env` for the AWS CLI and SDKs, and `secrets/ssh/` for the SSH config and
private keys. In the `.env` files only values are encrypted and the key names stay
readable; each file under `secrets/ssh/` is encrypted whole, because the config
names servers and the repository is public. The age key is
`~/.config/sops/age/keys.txt` (mode 600), the same on both machines, backed up in
the vault item `age (dotfiles)`. It is the only thing a new machine needs: the
Bitwarden master password unlocks it, and it unlocks the rest.

A new machine: `rbw unlock`, then `secrets init` (writes the age key from the
vault without printing it), then `dotter deploy`. `missing.sh terminal` prints
the first two while the key is absent.

- `sops edit secrets/personal.env` adds or changes a value, and
  `sops edit secrets/ssh/config.d/unimed.conf` a host;
- a new SSH key goes in with
  `sops encrypt --input-type binary --output-type binary --filename-override secrets/ssh/keys/<name> <file> > secrets/ssh/keys/<name>`;
- `secrets ssh`, run by the deploy, decrypts `secrets/ssh/` into the same paths
  under `~/.ssh` (mode 600), rewrites only what changed and derives each key's
  `.pub`. `known_hosts`, `authorized_keys` and other local files are left alone;
  the `sshd` module adds `personal.pub` to `authorized_keys`, so both machines
  reach each other;
- `secrets run -- <command>` runs the command with `personal.env` as variables
  (`vpn` uses it; the bashrc never decrypts at shell start);
- `media-deploy` decrypts `media.env` to `~/.config/media/media.env` (mode 600)
  and, when it generates a key, encrypts it back for a commit;
- `secrets aws` prints `aws.env` as the JSON of `credential_process`, which
  `terminal/aws/config` uses for the default profile; the key never sits in plain
  text, never expires and works from services and scheduled jobs;
- `secrets check` reports a missing age key, a secret file others can read, a
  plain-text credential left in the home (`~/.netrc`, an AWS credentials file, a
  `.env` with a key, token or password outside `~/Code`), a `~/.ssh` file that
  differs from `secrets/ssh/` and a key in `~/.ssh/keys` that is not there; the
  deploy and `media-drift` run it.

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

`vault` (also `terminal/bin`) is the vault for people and agents: `ls`,
`folders` and `dupes` print metadata only, `mv`/`rename`/`rm` organize, `add`
stores a generated or file/variable secret without echoing it, and
`vault run <item> VAR -- cmd` hands one secret to one command. The `cofre` skill
holds the agent rules. The official Bitwarden MCP server is registered for omp
(`ai/.omp/agent/mcp.json`) and Claude Code (post-deploy) for what `vault` lacks.

Both Bitwarden clients stay on purpose. `rbw` is a native package, so it works on
a fresh machine before mise and npm exist: the age-key restore and
`vault run` use it, and its agent reads one item with no session variable. `bw`
(the Node CLI, installed by mise) is the only one that creates, moves and
organizes items and generates passwords, which `vault add`, `mv`, `rename`, `rm`
and `unlock` need. Each has its own login and unlocked session, so unlocking
one does not unlock the other.

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
