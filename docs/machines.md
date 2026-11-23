# Machines in detail

## What the deploy does besides links

`.dotter/post_deploy.sh` runs after every `dotter deploy`, only for the modules
the machine has:

- installs missing packages from `<module>/packages.<distro>.txt` (`yay`/`pacman`
  on Arch, `dnf` on Fedora);
- copies the Fuxi-H3 udev rule and the greetd config to `/etc` with sudo;
- sets gsettings, `gcr-ssh-agent`, the work omp profile, and reloads Hyprland.

`DOTFILES_LINKS_ONLY=1 dotter deploy` creates only the links.

## First run

`.dotter/adopt.sh` removes old links into the repo (from stow), moves every
real file in the way to `~/.dotfiles-backup/<date>/` and deploys. Nothing is
deleted.

## Hyprland per machine

`hyprland` is the same config on both machines. What only one of them needs
lives in its `~/.config/hypr-machine/machine.lua`, linked by `laptop` on `arch`
and by `home` on `fedora`. It returns `monitors` (rules by output name, read by
`monitors.lua`) and `setup`, which `hyprland.lua` calls last. A machine without
the directory runs the shared config with the wildcard monitor rule.

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
shell needs). The VPN reads `~/Unimed/Envs/vpn.env`. A project loads its own
`.env` with direnv (`.envrc` with `dotenv ~/TEAjudo/Env/api-local.env`). The
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
