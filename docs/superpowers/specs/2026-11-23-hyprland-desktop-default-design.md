# Hyprland as the desktop's only session

Follows `2026-11-23-hyprland-desktop-design.md` (phases 0 and 1: the config
split and Hyprland next to Plasma), on the same branch.

## Intent

The owner wants the desktop on Hyprland for good, set up like the laptop: the
same shell, GNOME apps instead of KDE ones, and Plasma gone. He also wants each
machine to look different, so he can tell at a glance which one he is on.

The switch happens in two steps. This spec is the first: Hyprland becomes the
desktop's default and only daily session, and everything he uses has to work
there. Plasma stays installed and listed in the greeter as a fallback. After a
day or two of real use (Sunshine, games, Studio), a small second PR uninstalls
Plasma. Uninstalling is the only step that is hard to undo, so it waits for
proof that nothing depends on it.

## Goals

- The desktop boots through greetd and logs `raphael` straight into Hyprland,
  so Sunshine has a session after a reboot with nobody at the keyboard. After a
  logout, noctalia-greeter asks for the password, like the laptop.
- Each machine has its own Noctalia theme, wallpaper and idle settings. A theme
  picked in Noctalia's interface on one machine changes only that machine.
- GNOME apps like the laptop's, set as the desktop's defaults: Files
  (Nautilus), Image Viewer (Loupe), Papers, Showtime, Text Editor, Calculator,
  Disks, Passwords (Seahorse), pavucontrol and Mission Center.
- On the desktop the screen never turns off on its own and the machine never
  sleeps (Sunshine needs a live screen). Idle lock stays, with the shared
  timeout (Noctalia's default, 600 s).
- The desktop's saved secrets move from KWallet to gnome-keyring, the store
  that answers on Hyprland, and that store opens by itself after the
  autologin: apps start logged in, with no password prompt on screen.
- Logging into Hyprland on the desktop starts what Plasma starts today:
  Discord, Steam, OpenRGB, qBittorrent and gpu-screen-recorder, on top of the
  shared autostart (Noctalia, syncfast, EasyEffects, Spotifast, Zapfast,
  udiskie).
- The laptop keeps working as today: its theme, wallpaper, lock-mute hook,
  greetd and monitors.

## Non-goals

- Uninstalling Plasma, the KDE apps (Dolphin, Okular, Gwenview, Kate, KWrite,
  Spectacle, Ark, KCalc, the Haruna flatpak), Plasma Login Manager, `home/kwin`,
  roundcorners and the kded gtkconfig line. All of that is PR 2.
- Picking the desktop's final theme: the owner picks it in Noctalia.
- Game, DAW and design window rules beyond what exists. They come in when real
  use shows a need; the DAW is not known yet.
- Changing the laptop's default apps.

## Anti-goals

- A Noctalia theme change on one machine dirtying the repo for the other, or a
  theme apply rewriting a tracked file that is shared by both machines.
- The desktop rebooting into a login screen: Sunshine would stream a greeter
  that the laptop can only clear by typing the password through Moonlight.
- An app starting twice on login (from `autostart.lua` and from somewhere else).
- Plasma being unrecoverable before PR 2: going back must be two documented
  `systemctl` commands and a reboot.
- KWallet's secrets lost or written to a file on the way to gnome-keyring.

## Constraints

- Fedora's greetd runs the greeter as user `greetd`; Arch uses `greeter`. The
  laptop's `laptop/greetd/config.toml` cannot be shared as is.
- Fedora's own `/etc/pam.d/greetd` loads `pam_gnome_keyring` (from
  `gnome-keyring-pam`); the laptop's `laptop/greetd/pam` is written for Arch
  (`system-local-login`) and denies every login on Fedora. The desktop had a
  stray copy of it, so `home/greetd/pam` ships Fedora's file.
- `/usr/share/wayland-sessions/hyprland.desktop` runs `/usr/bin/start-hyprland`
  on Fedora (lionheartp).
- Noctalia reads every `*.toml` in `~/.config/noctalia/`, then the state file
  `~/.local/state/noctalia/settings.toml` on top. Its interface writes only to
  the state file, and only the keys that were changed. Today the state file is
  the shared `hyprland/noctalia/settings.toml`, linked on both machines.
- The `hyprtoolkit` Noctalia template writes `~/.config/hypr/hyprtoolkit.conf`.
  `~/.config/hypr` is a link to `hyprland/hypr/`, and the file is tracked, so
  every theme apply rewrites a shared tracked file.
- `ghostty.conf` (`~/.config/ghostty/machine.conf`) only says
  `theme = noctalia`; the colors land in `~/.config/ghostty/themes/`, outside
  the repo. Ghostty needs no split.
- Mission Center has no Fedora package; the laptop runs it as a flatpak
  (`io.missioncenter.MissionCenter`). The other GNOME apps are in Fedora's
  repos.
- The repo installs no flatpaks today; the post_deploy hook only sets flatpak
  overrides.
- Sunshine runs as the user unit `app-dev.lizardbyte.app.Sunshine.service`,
  `WantedBy=graphical-session.target`, with KMS capture. Plain Hyprland on the
  desktop already reaches `graphical-session.target` (checked in the current
  session) and Sunshine was active there.
- The laptop's `~/.config/autostart` holds `dev.noctalia.Noctalia.desktop` and
  others; running XDG autostart there would start Noctalia twice.
- The desktop's `~/.config/autostart` holds syncfast, EasyEffects, Spotifast
  and Zapfast entries, which `autostart.lua` already starts.
- The desktop's KWallet holds, under `Secret Service`: the `gh` token, the
  Spotifast logins and keys, the Zapfast archive keys and Noctalia's storage
  key; under `Chromium Keys`: one Chromium or Electron app's Safe Storage key;
  under `xdg-desktop-portal`: the Secret portal entries of the Spotify and
  Bazaar flatpaks. On Hyprland `org.freedesktop.secrets` belongs to
  gnome-keyring (`hyprland-portals.conf` also routes the Secret portal to it),
  and `~/.local/share/keyrings` does not exist yet on the desktop.
- In Plasma, `ksecretd` claims the same bus name, so KWallet and gnome-keyring
  cannot both serve secrets at once.
- The desktop's disk is not encrypted and it already boots logged in.
- Suspend can only come from Noctalia's `lock-and-suspend` idle behavior
  (disabled by default), logind's `IdleAction` (no drop-in, default `ignore`)
  or PowerDevil, which runs only inside Plasma.

## Approaches

| Approach | Trade-off | Status |
|---|---|---|
| Two steps: default Hyprland now, uninstall Plasma in PR 2 | one extra small PR; Plasma stays on disk for a few days as a fallback | owner's pick |
| One PR that switches and uninstalls | faster, but a day-one break in Sunshine or a game leaves no session, only SSH from the laptop | rejected |
| Merge phases 0 and 1 first, then a new PR | cleaner history, but coexistence pieces get merged only to be removed | rejected |

Per-machine theme:

| Approach | Trade-off | Status |
|---|---|---|
| Flip Noctalia's files: shared base in `~/.config/noctalia/settings.toml`, a per-machine state file the interface writes to | interface changes land in the right machine's file; a change meant for both machines has to be moved to the base by hand | my call |
| Keep the shared state file, add a per-machine file in `~/.config/noctalia/` | the shared state file overrides the machine file, and the interface keeps writing the theme into the shared file | rejected |

Desktop autostart:

| Approach | Trade-off | Status |
|---|---|---|
| `hl.exec_cmd` lines in `home/hypr/machine.lua` `setup()`, like Teams on the laptop | the same convention as today; the XDG entries stay for Plasma until PR 2 | my call |
| `systemctl --user start xdg-desktop-autostart.target` on the desktop | honors `~/.config/autostart`, but starts syncfast, EasyEffects, Spotifast and Zapfast a second time | rejected |

Secrets:

| Approach | Trade-off | Status |
|---|---|---|
| Migrate KWallet to gnome-keyring | matches the laptop, Seahorse sees them, PR 2 can drop KWallet; a one-time script and an app-by-app check | owner's pick |
| Keep KWallet serving secrets on Hyprland | nothing to migrate; differs from the laptop and KWallet outlives Plasma | rejected |
| `login` keyring with an empty password | opens by itself after the autologin; secrets unencrypted on disk | owner's pick |
| `login` keyring with a password | locked until typed once per boot, also through Moonlight | rejected |

## Design

### Login (desktop)

- New `home/greetd/config.toml`: `vt = 1`; `[default_session]` runs
  `/usr/bin/noctalia-greeter-session` as `greetd`; `[initial_session]` runs
  `start-hyprland` as `raphael`. greetd runs `initial_session` once per boot,
  which is the autologin.
- The home block of the post_deploy hook installs `greetd` and
  `noctalia-greeter-git` (lionheartp), copies the config to
  `/etc/greetd/config.toml`, disables `plasmalogin.service` and enables
  `greetd.service`. Fedora's PAM file stays.
- `home/plasmalogin/autologin.conf` and its copy line stay until PR 2. Going
  back is `sudo systemctl disable greetd && sudo systemctl enable plasmalogin`
  and a reboot; the next deploy switches back to greetd. `docs/remote-desktop.md`
  documents both, and changes "Plasma Login Manager autologin" to greetd.

### Noctalia per machine

- `hyprland/noctalia/settings.toml` links to `~/.config/noctalia/settings.toml`
  (the shared base) instead of the state file.
- New `laptop/noctalia/settings.toml` and `home/noctalia/settings.toml` link to
  `~/.local/state/noctalia/settings.toml` in the `laptop` and `home` packages.
- Moved out of the base into the machine files:
  - `[theme]` without `[theme.templates]` (templates stay shared),
  - `[wallpaper]`,
  - `[idle]`,
  - `[hooks]` (the lock-mute hook names the laptop's speaker sink).
- The laptop file gets today's values unchanged. The desktop file gets:
  - a different theme, my call: `source = "builtin"`, `builtin = "Gruvbox"`,
    `mode = "dark"`;
  - `forest-4.jpg` as the wallpaper until the owner picks one;
  - `[idle.behavior.lock] enabled = true`,
    `[idle.behavior.screen-off] enabled = false`;
  - no `[hooks]`.
- `hyprland/hypr/hyprtoolkit.conf` leaves git and goes in `.gitignore`: each
  machine keeps its own generated copy.
- `docs/machines.md` explains where a Noctalia change lands and how to promote
  one to both machines.
- No `lock-and-suspend` key on either machine: Noctalia's default (disabled)
  already keeps both awake, and nothing else suspends outside Plasma.

### Secrets (desktop, owner's picks)

- gnome-keyring's default collection is `login` with an empty password, so it
  opens with no prompt after the autologin. The owner chose this knowing the
  secrets then sit unencrypted on disk; the disk has no encryption and the
  machine boots logged in, so anyone at it already has the session open.
- One-time migration during the rollout, not kept in the repo: a single
  process starts `ksecretd`, reads every item (label, attributes, secret) from
  the three folders, stops it, starts gnome-keyring and writes each item into
  `login`. Secrets only live in that process's memory.
- After the migration each app is checked: `gh auth status`, Spotifast and
  Zapfast open logged in with their archives, Noctalia, and the app behind
  `Chromium Keys`. An app whose item format does not carry over (Chromium's
  KWallet folder or the portal entries) gets logged in again by hand, and the
  PR says which.
- KWallet's files stay until PR 2. In the Plasma fallback, apps see the old
  KWallet copies.

### GNOME apps (desktop)

- `hyprland/packages.fedora.txt` gains `nautilus`, `loupe`, `papers`,
  `showtime`, `gnome-text-editor`, `gnome-calculator`, `gnome-disk-utility`,
  `seahorse` and `pavucontrol`, plus whatever Fedora splits out that the laptop
  gets from those packages (`gvfs-mtp`, `gvfs-smb` are already there).
- The Fedora hyprland block installs Mission Center with
  `flatpak install --user -y --noninteractive flathub io.missioncenter.MissionCenter`
  when it is missing.
- The home block sets the defaults with `xdg-mime default`: Nautilus for
  `inode/directory`; Loupe for common image types; Papers for
  `application/pdf`; Showtime for common video types; Text Editor for
  `text/plain`.

### Autostart (desktop)

`home/hypr/machine.lua` gains a `setup()` whose `hyprland.start` handler runs
`discord --start-minimized`, `steam -silent`, `openrgb --startminimized`,
`qbittorrent --no-splash` and
`flatpak run com.dec05eba.gpu_screen_recorder gsr-ui`.

### Tests

`tests/machines.sh`: `greetd` moves from `laptop_only_in_hook` to the shared
list; the fedora checks cover `home/greetd/config.toml` (user `greetd`,
`initial_session`), the Noctalia machine file being linked to the state path on
both machines, and `hyprtoolkit.conf` being untracked.

## Verification

- `bash tests/machines.sh arch`, `bash tests/machines.sh fedora`,
  `bash tests/adopt.sh`, `lua tests/remote_state.lua`.
- Desktop: reboot, nobody touches the keyboard, Moonlight from the laptop shows
  Hyprland with Noctalia; Sunshine is active.
- Desktop: logout shows noctalia-greeter with Hyprland and Plasma listed.
- Each machine: `noctalia config export` shows its own theme; changing the
  theme in the interface changes only that machine's file.
- `git status` clean on both machines after a theme apply.
- Desktop: after the reboot no keyring prompt appears, `gh auth status` passes
  and Spotifast and Zapfast start logged in.
- Desktop: Discord, Steam, OpenRGB, qBittorrent, gpu-screen-recorder start once
  each; `xdg-mime query default inode/directory` is Nautilus.

## Left to the builder

- Exact MIME type lists for images and video.
- Whether any shared Noctalia key besides the four tables above is machine
  specific (monitor-scoped entries such as `HEADLESS-3` can stay shared).
- How the laptop's existing state-file link moves to the new source during
  deploy, and confirming Noctalia deep-merges `[theme]` from the base and the
  machine file.
- Qt apps under Hyprland: `QT_QPA_PLATFORMTHEME=gtk3` is set and Fedora ships
  `libqgtk3.so` in `qt6-qtbase-gui`; check OpenRGB and qBittorrent look right.

## Revision after the first boot (owner)

Hyprland logged in unattended on the first try, so the owner pulled the
Plasma removal into this PR and asked that the repo keep no volatile state.

- **No state in the repo.** `~/.local/state/noctalia/settings.toml` is no
  longer linked; it is each machine's own file, written by Noctalia's
  interface (theme, wallpaper, bar layout). The repo keeps defaults only:
  the shared base gains `[theme]` (builtin Gruvbox, dark) and
  `wallpaper.default` (forest-4). Per-machine behavior that is config, not
  taste, goes to `~/.config/noctalia/machine.toml`, linked from
  `laptop/noctalia/machine.toml` (hooks, idle) or `home/noctalia/machine.toml`
  (idle). Noctalia merges every `*.toml` in its config dir (`config_service.cpp`,
  `sortedConfigTomlFiles`), then the state file on top.
- **Migration.** Before deploying, each machine replaces the state link with a
  copy of its target, so nothing changes on screen and dotter skips a target
  that is no longer its link.
- **Plasma removal (desktop).** `home/remove.fedora.txt` lists Plasma, KWin,
  Plasma Login Manager, KWallet and the KDE apps; `remove_packages home` drops
  them with `clean_requirements_on_remove` off, so tuned and fonts stay.
  `fedora-release-identity-kde-desktop` protects `plasma-desktop`; the hook
  rebuilds the protected list from `/etc/dnf/protected.d` without it (swapping
  the identity would downgrade `fedora-release-common`). The Haruna flatpak goes
  too. KDE libraries left behind stay: `dnf autoremove` would take tuned.
- **Repo cleanup.** `home/kwin`, `home/plasmalogin`, the kded, powerdevil,
  roundcorners and kwinrc lines leave the home hook; greetd is enabled with
  `systemctl enable --force` (it takes over `display-manager.service` without
  naming the old manager).
