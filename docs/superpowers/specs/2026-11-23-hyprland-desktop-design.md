# Hyprland on the home desktop, next to Plasma

## Intent

The laptop (Arch) runs Hyprland and the desktop (Fedora 44 KDE) runs Plasma.
Keeping two desktops apart, and switching habits between them, costs the owner
more than it gives. The desktop moves to Hyprland with the laptop's config, and
Plasma stays installed as a fallback session for a while.

The migration has seven phases: split the config, install side by side, daily
use, audio, games, music and design, Sunshine on Hyprland, then make Hyprland
the default and remove Plasma. This spec covers the first two. Each later phase
gets its own spec.

## Goals

- The desktop's Plasma Login Manager offers a Hyprland session. Logging in gives
  Noctalia, the wallpaper and the laptop's keybinds, with the LG at
  1920x1080@144.
- The laptop behaves exactly as today after a deploy: monitor modes, the TV
  modeline, the remote desktop toggle, lid handling, greetd, Teams.
- `tests/machines.sh arch` and `tests/machines.sh fedora` pass with the split.

## Non-goals

- Autologin or Sunshine on Hyprland (phase 6). Autologin keeps entering Plasma.
- The desktop's XDG autostart entries (Discord, Steam, OpenRGB, qBittorrent,
  gpu-screen-recorder) inside Hyprland: Hyprland does not run
  `~/.config/autostart`, so they stay Plasma-only until phase 2.
- The lock screen hook that mutes the laptop's speaker by sink name: on the
  desktop the sink does not exist and the hook does nothing (phase 3).
- Game window rules, an audio mixer, DAW and plugin rules (phases 3 to 5).
- greetd on the desktop, removing Plasma or the `home/kwin` pieces (phase 7).

## Anti-goals

- Two copies of the Hyprland config.
- The laptop's TV modeline reaching the LG: both machines name their monitor
  `DP-1`.
- Breaking the Plasma autologin that Sunshine depends on.
- The Plasma session rewriting files in the repo through a link.
- One package coming from two repos, so `dnf` picks whichever builds higher.

## Constraints

- Hyprland is not in the Fedora 44 repos, and Fedora's own Noctalia (5.4.1)
  trails Arch's (5.6.0). The shared Lua config, Noctalia settings and plugins
  only work when both machines run the same versions. On 2026-11-23 the
  `lionheartp/Hyprland` COPR ships Hyprland 0.57.2 (Arch: 0.57.2) and
  `noctalia-git` 5.6.0 plus 8 commits (Arch: 5.6.0).
- `~/.config/hypr` stays a link to the whole directory. Swapping it while
  Hyprland runs drops the session into emergency mode, and Noctalia writes
  `noctalia.lua` into it.

## Approaches

| Option | Trade-off | Decision |
|---|---|---|
| Shared config plus one machine file per computer, like ghostty's `machine.conf` | the `DP-1` clash disappears, each machine declares only its own extras; `monitors.lua` takes its rules from outside | owner's pick |
| One config that detects the machine by hostname or hardware | no dotter change, but `if laptop` branches spread through the config and monitors need matching by model | rejected |
| A second config directory for the desktop | fastest, two copies drift | rejected |
| GTK look of the laptop on both sessions | Hyprland looks right from day one; Plasma's GTK apps take the laptop look | owner's pick |
| GTK look of KDE until phase 7 | Plasma untouched, Hyprland's GTK apps differ from the laptop until then | rejected |
| COPR `lionheartp/Hyprland` for Hyprland, portal, hyprshot and `noctalia-git` | same versions as the laptop from one COPR; Noctalia is a git snapshot and may carry unreleased bugs | owner's pick |
| Fedora's Noctalia 5.4.1 with Hyprland from `nett00n/hyprland` | reviewed stable package, two releases behind the laptop's settings and plugins | rejected |

## Design

### Machine file

- Each machine links a directory to `~/.config/hypr-machine/`. `hyprland.lua`
  adds it to `package.path` and loads `machine` from it. Without the directory
  the session starts with the shared config only.
- `machine.lua` returns `{ monitors = { [output] = { mode, position, scale } },
  setup = function }`, both optional. `monitors.lua` reads `monitors` instead of
  its inline `RULES`. `hyprland.lua` calls `setup()` last, after `keymaps` and
  `windowrules`, which also keeps the lid binds away from `hl.monitor`
  (hyprwm/Hyprland#14858).

### Laptop: new `laptop` module, in `arch.toml`

- `laptop/hypr/machine.lua`: the `DP-1` TV modeline and the `eDP-1` rule
  (moved from `monitors.lua`); in `setup`, the lid switch binds (moved from
  `keymaps.lua`), the Teams autostart (moved from `autostart.lua`) and
  `require("remote")`.
- `remote.lua` and `remote_state.lua` move to `laptop/hypr/`;
  `tests/remote_state.lua` and the CI step follow the new path.
- `laptop/packages.arch.txt`: greetd, noctalia-greeter, moonlight-qt (moved
  from `hyprland`). The greetd files and their post-deploy copy move to
  `laptop/`.
- The rest of `autostart.lua` stays shared: syncfast and EasyEffects
  (Flatpaks), zapfast, spotifast and udiskie are all installed on the desktop.
  Plasma starts its own copies from `~/.config/autostart` and Hyprland does not
  read that directory, so no session starts an app twice.

### Desktop: `home` module

- `home/hypr/machine.lua`: `DP-1` at 1920x1080@143.94 (the LG's top mode, the
  one Plasma uses today), position 0x0, scale 1.
- `fedora.toml` gains the `hyprland` module.

### Shared `hyprland` module

- `hyprland/packages.fedora.txt`: the Fedora names of what stays in
  `packages.arch.txt`, with `noctalia-git` for `noctalia`.
- On Fedora the post-deploy enables `lionheartp/Hyprland` before installing,
  the same shape as the LizardByte block for Sunshine.
- Every package has one source. satty (called by the hypr-shots plugin) is in
  neither Fedora nor `lionheartp`; if it comes from `nett00n/hyprland`, that
  repo is limited to satty (`includepkgs`), because its Hyprland build sorts
  above `lionheartp`'s.
- The GTK links, `gsettings`, Flatpak override and `~/.icons/default` now
  apply on the desktop too, exactly as the laptop has them today, mismatches
  between files included (Yaru in `settings.ini`, Yaru-olive-dark in
  `gsettings`, Papirus for Flatpaks, Adwaita cursor). Fedora ships the Yaru
  themes (`yaru-theme`, `yaru-icon-theme`, `yaru-gtk3-theme`).
- The desktop's real `~/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`
  go through `adopt.sh`, which backs them up.
- Plasma's `gtkconfig` kded module writes `settings.ini` when Plasma starts or
  its settings change, which would write into the repo through the link. The
  desktop's post-deploy turns off its autoload.
- Noctalia's `settings.toml` stays shared as is: its lock screen widgets
  already cover `DP-1`, which on the desktop is the LG.

### Tests and docs

- `tests/machines.sh`: the Hyprland paths move from laptop-only to both
  machines; `.config/hypr-machine` reaches `remote.lua` on arch and
  `machine.lua` without `remote.lua` on fedora. In the hook, greetd stays
  laptop-only, `hyprctl` becomes shared, and the COPR line is fedora-only.
- README module table: `hyprland` on both machines, a `laptop` row.
  `docs/machines.md`: a line on the machine file.

## Acceptance

- Desktop: deploy, pick Hyprland at the login screen. `hyprctl monitors` shows
  DP-1 at 143.94 Hz, `hyprctl configerrors` is empty, the Noctalia bar is up.
  Logging out and choosing Plasma gives a working Plasma.
- Reboot: autologin still enters Plasma.
- Laptop, deployed over `ssh laptop` (or locally if the deploy needs the
  session bus): `hyprctl configerrors` empty, `hyprctl monitors` unchanged,
  `~/.config/hypr-machine` present.

## Left to the builder

- The Fedora package for each item in `packages.arch.txt`. A package the
  shared config calls (socat, ddcutil, hyprshot, satty, grim, slurp) is
  required; any other one with no Fedora package is dropped and named in the PR.
- Confirming `gtkconfig` is what writes `settings.ini` on Plasma, before
  turning it off.
- Whether the shared post-deploy steps (`gsettings`, `gcr-ssh-agent.socket`)
  need a guard to run without a graphical session.
- Whether Noctalia's battery widget hides on a machine without a battery.
