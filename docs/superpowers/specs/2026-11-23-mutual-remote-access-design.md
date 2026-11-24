# Mutual remote access between `arch` and `fedora`

## Intent

Today only `arch` (the laptop) sees `fedora` (the desktop): Moonlight on
`arch`, Sunshine on `fedora`, `SUPER + grave` toggling a named workspace
`desktop`. The owner wants the same in both directions, with the same key, so
the remote part stops being laptop-only and moves to the shared `hyprland`
module. Three things come with it:

- No mirror loop. The real case: the owner is on `arch` watching `fedora`,
  walks to `fedora` and opens `arch` there. `arch`'s screen still shows
  `fedora`, so `fedora` would watch itself. Opening one direction closes the
  other on its own.
- Knowing where you are. Inside a fullscreen stream the other machine's bar
  looks the same as yours. A sun shows on the machine being streamed
  (Sunshine), a moon on the machine that has a stream open (Moonlight).
- Manual login on both machines. `fedora` loses its greetd autologin; the
  stream reaches the login screen, and the owner types the password through
  it.

Machines are named by hostname only: `arch` and `fedora` (SSH hosts and herdr
machines were already renamed; aliases `desktop`, `laptop`, `personal-*` are
gone).

## Goals

- `SUPER + grave` on either machine opens the other's screen on a special
  workspace named after it (`special:fedora` on `arch`, `special:arch` on
  `fedora`) and closes it again, returning to exactly what was on screen.
- A machine that starts serving a stream closes its own Moonlight first, so
  the two directions never run at once.
- Sun in the bar while the machine is being streamed; moon while it has a
  Moonlight stream open.
- After boot, both machines sit at the greetd login screen and the other one
  can stream that screen and log in.

## Non-goals

- Wake-on-LAN or waking a suspended laptop. With the lid closed, on battery
  and without a dock, `arch` still suspends (`laptop/hypr/lid.lua`).
- Access from outside the home network.
- Choosing a different key: the owner kept `SUPER + grave`; the `magic`
  scratchpad on `SUPER + S` stays.

## Anti-goals

- Autologin on either machine.
- A stream of a machine showing a stream of the first machine.
- Two copies of the remote code, one per machine.

## Approaches

How the other direction gets closed:

| Approach | Trade-off | Decision |
|---|---|---|
| A. The streamed machine closes its own Moonlight from Sunshine's connect hook (`global_prep_cmd`) | Works whoever connects (shortcut, Moonlight app, phone), no SSH round trip | chosen by the owner |
| B. The requesting machine tells the other over SSH to close its Moonlight before launching | Only covers connections made through the shortcut; adds an SSH round trip before every open | rejected |

How the login screen becomes reachable without autologin:

| Approach | Trade-off | Decision |
|---|---|---|
| Sunshine starts at boot as a system unit running as the owner, KMS capture | Not Sunshine's official setup; audio must be up before it; the stream may drop once when greetd hands over to Hyprland | chosen by the owner |
| No remote access before the first physical login | Simplest; `fedora` is unreachable after a power cut | rejected |

Prior art for the first row: [bazsyi-sunshine](https://github.com/proxsyi/bazsyi-sunshine)
(one Sunshine process across Plasma's login and session, KMS, linger,
service-scoped `input`/`video`/`render` groups, waits for the PipeWire sink)
and [LizardByte's guide](https://app.lizardbyte.dev/2024-10-16-autostart-sunshine-on-boot-without-auto-login).

## Design

### Shared remote module

- `laptop/hypr/remote.lua` and `laptop/hypr/remote_state.lua` move to
  `hyprland/hypr/`. `tests/remote_state.lua` follows.
- Each `machine.lua` names the other machine: `M.peer = "fedora"` on `arch`,
  `M.peer = "arch"` on `fedora`. `remote.lua` reads it through `host.lua`,
  reaches it as `<peer>.local` (mDNS, already set up by `sshd`), and does
  nothing when a machine has no peer. Notification texts and the app name use
  the peer's hostname instead of "Desktop".
- `hyprland.lua` requires `remote` (today `laptop/hypr/machine.lua` does).

### Special workspace

- Moonlight's window rule sends it to `special:<peer>`, fullscreen.
- `SUPER + grave` keeps today's flow (probe Sunshine's port and SSH, notify,
  launch) but shows and hides the special workspace instead of jumping to a
  named one, so the "origin workspace" bookkeeping in `remote_state.lua`
  goes away.
- The `remote` submap (only `SUPER + grave` bound, every other key reaches
  Moonlight) is active exactly while `special:<peer>` is shown. Hyprland's
  Lua API has `workspace.special_active` for that.
- A window that is not Moonlight opening on `special:<peer>` moves to the
  monitor's regular workspace, as today.
- `SUPER + grave` inside a stream is always caught by the machine you sit at
  (`dont_inhibit` plus the submap), so the same key on both machines never
  reaches the other one.

### Closing the other direction

Sunshine's `global_prep_cmd` runs a shared script on stream start (`do`) and
end (`undo`). On start it closes the local Moonlight (`pkill -x moonlight`)
and marks the machine as serving; on end it clears the mark. It must work
before login (no Hyprland), so it uses no `hyprctl`.

### Sun and moon

- State lives in two files under `$XDG_RUNTIME_DIR/remote/`: `serving`
  (written by the Sunshine hook) and `viewing` (written by `remote.lua` when
  Moonlight's first window opens, removed when its last one closes; the
  splash and the stream share the class, as `window_close` already handles).
- A new Noctalia bar plugin in `hyprland/noctalia/plugins/`, linked like the
  other three, shows a sun while `serving` exists and a moon while `viewing`
  exists, nothing otherwise. It goes at the start of the base bar's `end`
  list, so both machines get it without touching the desktop's center
  override.

### Sunshine and Moonlight on both machines

- Sunshine setup moves out of the `home` block of `post_deploy.sh` into a
  shared place that runs on both machines: package (Fedora: LizardByte COPR,
  as today; Arch: the AUR package), `capture = kms`, `cap_sys_admin`, the
  `global_prep_cmd` line, the system tray off (one process has to survive the
  greeter to session switch), firewall ports when `firewall-cmd` exists.
- Moonlight: `moonlight-qt` on both (Fedora's own repo has it).
- Sunshine's own config file stays a real file it can rewrite; the deploy
  ensures its lines, as it already does for `capture = kms`.

### Sunshine before login

- A system unit runs Sunshine as the owner at boot, with linger on, the
  user's PipeWire, PipeWire-Pulse and WirePlumber started and Sunshine's sink
  awaited before launch, `XDG_RUNTIME_DIR` set, and `input`, `video`,
  `render` as service-scoped supplementary groups. The Sunshine user unit is
  disabled so only one process runs.
- The stream may drop once when greetd starts Hyprland; reconnecting with the
  shortcut is accepted.

### greetd

- One shared `/etc/greetd/config.toml` source with no `initial_session`. The
  greeter user differs by distro (`greetd` on Fedora, `greeter` on Arch); the
  deploy fills it in. PAM files stay per distro.
- `fedora` loses its autologin, which only existed so Sunshine had a session
  after an unattended boot.

### Docs and tests

- `docs/remote-desktop.md` describes both directions, pairing each Moonlight
  with the other's Sunshine, the login-screen behavior, and the sun and moon.
- `tests/remote_state.lua` covers the new state machine (no origin, special
  workspace, viewing mark). `tests/machines.sh`: Sunshine and Moonlight setup
  in both hooks, no autologin in either.

## Verification

- Reboot `fedora`; from `arch`, `SUPER + grave` shows `fedora`'s login screen;
  log in through the stream; reconnect if it dropped; `SUPER + 1` changes
  `fedora`'s workspace; sun on `fedora`'s bar, moon on `arch`'s once the stream
  is hidden.
- Same with the machines swapped.
- Loop: `arch` streaming `fedora`; on `fedora`, `SUPER + grave` opens `arch`;
  `arch`'s Moonlight closes on its own and `fedora` shows `arch`'s desktop.
- Neither machine logs in by itself after boot.

## Calls made while writing (owner to check)

- `arch` streams its external monitor when one is connected and its built-in
  screen otherwise; `fedora` streams `DP-1`. When the LG shows `fedora`,
  `arch`'s DP-1 reads disconnected, and `monitors.lua` already turns `eDP-1`
  on, even with the lid closed.
- `special:<peer>` opens on the monitor in focus, like any special workspace.
- The Sunshine unit clears `serving` when it starts, so a crash or a dropped
  `undo` leaves no sun lit past the next start.
- Both state files live in `/run/user/<uid>/remote/`, which exists before login
  because linger is on; the Sunshine hook and `remote.lua` share it.
- When the hook closes Moonlight, that machine shows a notification saying the
  stream closed because the other machine is now watching this one.
- Pairing each Moonlight with the other's Sunshine stays a documented manual
  step (PIN in Sunshine's web UI); Sunshine's default `Desktop` app is used.
- `fedora` already has linger on, so the media stack's user units keep running
  without a login after a power cut.

## Left to the builder

- Spike first: on `fedora`, log out and check that Sunshine streams the
  noctalia greeter and takes keyboard input there. If KMS capture or input
  fails at the greeter, stop and bring it back to the owner before building
  the rest.
- The Arch AUR package name for Sunshine and whether `yay` builds it unattended.
- Where the shared Sunshine block lives in `post_deploy.sh` and the unit's name.
- How Sunshine picks the output on `arch` (config line per machine or a prep
  step).
- How the plugin notices the files (poll or watch).
- Glyph names for sun and moon in Noctalia's icon set.
