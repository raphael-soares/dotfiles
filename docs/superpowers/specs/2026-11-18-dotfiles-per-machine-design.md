# Dotfiles per machine with dotter

## Intent

The repo serves two PCs and does not know it. `install.sh` asks group by group
on every run, the groups live as bash inside it, and a file that belongs to one
machine goes to both (the TV modeline in `hypr/monitors.lua`, the udev rule for
the Fuxi-H3 DAC in `sistema/`). The root has 22 loose stow packages next to
`docs/`, `packages/` and `sistema/`.

The owner wants clearer blocks and a file that says what goes to each machine.

| Machine (hostname) | System | Role |
|---|---|---|
| laptop (`arch`) | Arch + Hyprland | work, programming, college |
| home (`fedora`) | Fedora + KDE | games, design, music |

## Goals

- One file per machine lists its modules; running one command on the machine
  applies exactly that, with no questions.
- Root organized by layer (terminal, desktop, ai, work, docs).
- What belongs to a single machine lives in a module that only that machine
  enables.
- Keep using symlinks: editing `~/.config/...` (by hand or by an agent) edits
  the repo.

## Out of scope

- KDE config. The home PC only gets the common part; Plasma stays as it is.
- Secrets: they stay in `~/.env.local` and `~/.bash_profile.local`, outside the
  repo.
- The herdr-app setup stays in the `herdr-setup` repo, only cloned and
  installed.

## Anti-goals

- An app file turning into a copy for no reason. A dotter template is a copy:
  only use it when the app has no include.
- The laptop's Hyprland ending up in emergency mode after the switch.
- App state (omp sessions, Claude cache, Noctalia state) falling back into the
  repo.

## Approaches

| Option | Gain | Cost | Decision |
|---|---|---|---|
| dotter | `global.toml` with modules, `.dotter/<hostname>.toml` per machine picked automatically, per-file symlink, variables, hooks with `dotter.packages`, `owner` for root files | migrate the mapping to TOML; no dnf package | chosen by the owner |
| stow + one file per machine read by `install.sh` | no new tool | difference inside a file has no solution; the home-grown script grows | rejected |
| chezmoi | the most complete (secrets, run_once scripts) | works with copies and `chezmoi apply`, clashes with an agent editing the live config | rejected |

Facts checked in the dotter code (0.13.x): without `.dotter/local.toml`, it
loads `.dotter/<hostname>.toml`; the hook sees `dotter.packages.<name>`; a
symbolic target accepts `owner` and `recurse`.

## Design

### Repo layout

```
.dotter/
  global.toml        modules: repo file -> destination, variables
  arch.toml          packages = [...] for the laptop
  fedora.toml        packages = [...] for the home PC
  post_deploy.sh     distro packages, /etc, gsettings, herdr-setup, enterprise profile
  adopt.sh           first apply on a machine that already has config
terminal/  bash git starship fzf mise nvim ghostty fastfetch
desktop/   fonts webapps audio (with the Fuxi) syncfast
hyprland/  hypr portal noctalia gtk greetd
ai/        internal layout unchanged
work/      bin (vpn, omp-agendado-work), shell (ompe, SESSIONIZER_DIRS)
tests/     machines.sh and adopt.sh, in a fake HOME
docs/
README.md
.env.example
```

Each root folder is a dotter module, with the same name that appears in the
machine file. Inside each app folder there are only the app's files, without
the home prefix (`terminal/ghostty/config`, not
`ghostty/.config/ghostty/config`). The destination lives in `global.toml`. The
distro package list stays in the module, as `packages.<distro>.txt`.

`ai/` keeps its internal tree (`ai/.omp/agent/...`, `ai/.claude/...`,
`ai/.local/bin/...`, `ai/skills`). Scripts, skills and `AGENTS.md` cite those
paths (`~/.dotfiles/ai/.omp/overlays/enterprise.yml`,
`~/.dotfiles/ai/.omp/sem-humano.md`, `~/.dotfiles/ai/skills`); touching them
breaks references for no gain.

### Dotter modules

The dotter modules follow what changes between machines, not one per app, so
each machine's file fits on one line.

| Dotter module | Content | laptop | home |
|---|---|---|---|
| `terminal` | bash, git, starship, fzf, mise, nvim, ghostty, fastfetch; clones and installs `herdr-setup` | yes | yes |
| `ai` | omp and Claude Code (personal profile), skills, the `ai` `~/.local/bin` minus `omp-agendado-work` | yes | yes |
| `desktop` | fonts, webapps, audio (A2DP only, hide pro-audio, Fuxi-H3: `55-fuxi-soft-mixer.conf` and the udev rule `91-fuxi-h3-mixer.rules`), syncfast | yes | yes |
| `hyprland` | hypr, portal, noctalia, gtk, Ghostty's `theme = noctalia`, greetd and its PAM; in the hook: gsettings, `~/.icons/default`, flatpak override, `gcr-ssh-agent.socket` | yes | no |
| `work` | vpn, `ompe`, `SESSIONIZER_DIRS`, `omp-agendado-work`, `ai/.omp/overlays/enterprise.yml`; in the hook: the `~/.omp/profiles/enterprise/agent` links and the enterprise profile's `plugin install` | yes | no |

A module can link a file from any folder in the repo. `overlays/enterprise.yml`
stays in `ai/`, because `ompe` cites the path, but only the `work` module links
it. `omp-agendado-work` goes to `work/bin`: nobody cites its path, only its
name. The home PC gets nothing from the enterprise profile.

syncfast's `noctalia.json` theme stays as it is: when the theme goes missing,
syncfast falls back to the embedded light or dark theme (`Themes::resolve`).

```toml
# .dotter/arch.toml
packages = ["terminal", "ai", "desktop", "hyprland", "work"]

# .dotter/fedora.toml
packages = ["terminal", "ai", "desktop"]
```

### Difference inside a file

Prefer the app's own include over a template:

- Ghostty: the common `config` ends with `config-file = ?machine.conf`. The
  `hyprland` module links a `machine.conf` with `theme = noctalia`. On the home
  PC the file does not exist and Ghostty uses its default theme.
- `monitors.lua`, `gtk` and the rest of Hyprland only exist on the laptop, so
  they stay as they are.

### Whole directory or file by file

The same rule `linkar()` followed, now in `global.toml`:

- A directory that only the repo writes becomes a single link
  (`recurse = false`): a new file an agent creates shows up in the repo without
  a new deploy. Examples: `ai/skills`,
  `~/.omp/agent/{extensions,rules,prompts,themes}`, `~/.config/hypr`,
  `~/.config/nvim`, `~/.config/noctalia-plugins`.
- A directory where the app writes state (`~/.omp/agent`, `~/.claude`,
  `~/.local/state/noctalia`, `~/.config/syncfast`, `~/.local/bin`) is linked
  file by file, so state never lands in the repo. A new file there needs
  `dotter deploy`.

The builder checks each directory against the criterion; when in doubt, file by
file.

### Distro packages

The list lives in the folder of the module that needs it:
`packages.arch.txt` and `packages.fedora.txt`. Since each machine has a fixed
distro, only the lists that some machine uses exist: a laptop-only module has
only the Arch list. `post_deploy.sh` installs the lists of the enabled modules,
only what is missing (`yay`/`pacman` on Arch, `dnf` on Fedora), as
`instalar_pacotes` does today. Skipping the installation stays possible
(environment variable in the hook).

### /etc

Only two `/etc` files stay in the repo, each in the module that needs it:
greetd with its PAM (`hyprland`) and the Fuxi udev rule (`desktop`, on both
machines). There is no `sistema` module anymore.

A root file does not become a symlink into the home: PAM and greetd pointing to
a file the user edits without sudo is a hole. They are copied with root
ownership, by dotter (target with `owner = "root"`, template type) or by
`post_deploy.sh` with `sudo install -Dm644`, as today. The builder chooses after
checking that neither has `{{`, which the template would interpret.

The Fuxi is used on both machines, wired on the laptop and with a dongle on the
home PC, and its microphone is USB audio, which A2DP only does not affect. The
udev rule recognizes the cable by USB ID `040b:0897` and the WirePlumber one by
name `Fuxi-H3-00`. If the dongle shows up with another ID or name, the two rules
do not run on the home PC and nothing breaks. The home PC walkthrough checks
with `lsusb` and `wpctl status` whether the dongle has the same muted right
channel problem before any adjustment. The rule calls `amixer`, so `alsa-utils`
goes into the Fedora package list.

### What goes away

- `install.sh`: the logic moves to `global.toml`, the machine files and
  `post_deploy.sh`.
- Legacy: `tmux/`, `workmux/`, `omp-legado/`, `packages/legado.*`. Git history
  keeps them.
- `packages/`: the lists move into the modules; the Fedora lists of
  laptop-only modules (`vpn.fedora.txt`) go away.
- From `sistema/`, decided with the owner: docker `daemon.json`, zram, journald,
  paccache, plymouth and thermald's `enable` leave the repo. What is already in
  the laptop's `/etc` stays as it is; it just stops being versioned.
- Package `raphael`: `SESSIONIZER_DIRS` and `ompe` go to `work/`, the syncfast
  config to `desktop/syncfast`. `config.toml.v*` stays ignored.
- The root `.omp/` folder (`.omp/planos/`): the builder checks whether it is
  still useful; if not, it goes.
- `.gitignore` rules that existed because stow linked the whole folder (Claude
  and omp sessions, Noctalia state, `gtk-*/` besides `settings.ini`). The secret
  ones stay (`.env*`, `.bash_profile.local`), plus `.dotter/local.toml` and
  `.dotter/cache*`.

### Hostname

dotter picks the file by hostname. The PCs keep the names they already have
(owner's decision): the laptop is `arch` and the home PC is `fedora`, so the
files are called `arch.toml` and `fedora.toml`.

### Installing on a new machine

```
git clone ... ~/.dotfiles && cd ~/.dotfiles
# laptop: yay -S dotter-rs-bin
# home: release binary from GitHub in ~/.local/bin (there is no dnf package)
dotter deploy
```

The README now describes this and the table of modules per machine, in place of
the stow package and group tables.

## Switch on the laptop (live system)

The stow symlinks point into `~/.dotfiles`, and Hyprland is running. Risks and
how to handle them:

- Hyprland in emergency mode: removing and recreating the `hyprland.lua` link
  triggers the reload without the file, and it does not reload when the link
  comes back. After `dotter deploy`: `hyprctl reload && noctalia msg
  config-reload`, and check `hyprctl configerrors` is empty and `hyprctl binds`
  has binds.
- dotter conflict with the stow links: dotter does not overwrite a file that
  is not its own. The order is to undo the stow links (`stow -D` per package, or
  delete the symlinks that point to the repo) and run `dotter deploy` in the
  same session.
- gsettings: the hook must not overwrite the live icon theme with the repo's
  value; align the repo to the current value (`gsettings get ...`) beforehand.
- Atomic write: an app that writes to a temp file and renames replaces the
  symlink with a real file. Today this already happens with
  `gtk-4.0/settings.ini` (nwg-look). After the switch, check that these are
  still symlinks after the app writes: `noctalia/settings.toml`,
  `syncfast/config.toml`, `nvim/lazy-lock.json`, `~/.claude/settings.json`,
  `~/.omp/agent/config.yml`. Whatever becomes a real file goes to a managed copy
  (template) or leaves the repo, and the decision is recorded in the PR.

## Switch on the home PC

It is not known whether the home PC has stow links, real files or nothing. The
walkthrough handles all three cases without asking: it undoes the symlinks that
point to `~/.dotfiles`, moves any real file sitting on a dotter destination to
`~/.dotfiles-backup/<date>/`, and only then runs `dotter deploy`. This replaces
`install.sh`'s `--adopt`. The same step serves the laptop.

## Order

`~/.dotfiles` is on the `feat/superpowers` branch, which has not entered
`main` yet, and has uncommitted changes (`ai/`, `README.md`, the removal of
`herdr-app/`). The reorganization moves almost every file: start after that
work enters `main`, branching from it, so as not to fight it in the merge.

## Acceptance

- On the laptop, `dotter deploy` with no argument applies the five modules; no
  file that existed before disappears from the home and the links point to the
  repo.
- Hyprland, Noctalia, greetd, Ghostty with the `noctalia` theme, omp (personal
  and `ompe`), Claude Code, vpn and the Fuxi on both channels work as before the
  switch.
- `git status` clean after using the laptop for a while (app state does not
  land in the repo).
- On the home PC, `dotter deploy` applies `terminal`, `ai` and `desktop`,
  installs what is missing through dnf and creates nothing for Hyprland or work;
  from `/etc`, only the Fuxi rule.
- The repo root has no stow package, `install.sh` or `packages/` left.

## For the builder to decide

- Exact folder names inside each layer and the mapping of each file.
- `/etc` through dotter's `owner` or through the hook (criterion above).
- How the hook receives "skip packages".
- Whether `ai/skills` and the other internal `ai/` symlinks go as a directory
  (`recurse = false`) or file by file.
- Validation on the home PC: the owner runs it there; the builder delivers the
  walkthrough.
