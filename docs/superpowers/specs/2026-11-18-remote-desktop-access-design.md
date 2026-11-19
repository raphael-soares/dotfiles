# Remote access from the laptop to the home desktop

## Intent

The owner wants to keep working on the home desktop from the laptop while
sitting in the living room (watching a movie, say). Two kinds of access, both
inside the home network:

- terminal: herdr's remote machines over SSH, so a space started on the desktop
  continues from the laptop;
- graphics: see and drive the desktop screen (an app running, anything not in a
  terminal).

| Machine (hostname) | System | Role here |
|---|---|---|
| laptop (`arch`) | Arch + Hyprland | client |
| home desktop (`fedora`) | Fedora + KDE Plasma (Wayland) | host, on Wi-Fi |

## Goals

- `meta + grave` on the laptop toggles a dedicated workspace that shows the
  desktop screen; pressing it again goes back to the laptop workspace the owner
  came from.
- While on that workspace, every key goes to the desktop (both machines use the
  same keybinds); only `meta + grave` stays with the laptop, like VirtualBox's
  host key.
- The desktop shows up as a machine in herdr on the laptop.
- When the desktop is unreachable, the owner is told so instead of getting a
  blank window.

## Non-goals

- Access from outside the house (Tailscale): later, only if needed.
- Waking the desktop remotely: it is on Wi-Fi, so Wake-on-LAN does not apply.
  The owner turns it on by hand.
- A virtual screen sized to the laptop: the stream uses the desktop's real
  monitor (owner's decision).
- A Noctalia widget with the desktop state: possible extra, not now.

## Anti-goals

- The owner stuck in passthrough with only one working key and no stream.
- A key meant for the desktop switching workspaces on the laptop, or the
  reverse.
- An error in the new Lua breaking the laptop's whole Hyprland config.
- The desktop trying to stream to itself because the dotfiles are shared.

## Approaches

| Option | Gain | Cost | Decision |
|---|---|---|---|
| A. All in Hyprland's Lua config | no extra process; the config already reacts to events (`monitors.lua` uses `hl.on`); stubs expose `workspace.active`, `define_submap`, `submap` | a Lua error can break the config | chosen by the owner |
| B. bash script + socket2 listener (`socat`) | works on any Hyprland | an extra service duplicating what the Lua config does | rejected |
| C. Noctalia plugin | status button on the bar | cannot own binds or submaps | rejected as the core; maybe later as an extra |

Graphics: Sunshine on the desktop, Moonlight on the laptop. Low latency on a
home network, works on Wayland, discovers peers by itself, one PIN pairing.
VNC (laggier) and xrdp (does not fit Wayland) were dropped in the discussion.

## Design

### Where things live

The per-machine split comes for free from dotter: laptop pieces go in the
`hyprland` module (only `arch.toml` enables it), desktop pieces in a new
module that only `fedora.toml` enables. That is the "do not stream to itself"
guard; no hostname check in code.

| Piece | Machine | Module |
|---|---|---|
| `hypr/remote.lua` (key, submap, rules, guards), required from `hyprland.lua` | laptop | `hyprland` |
| Moonlight (`moonlight-qt`) in `packages.arch.txt` | laptop | `hyprland` |
| `Host desktop` SSH entry | laptop | see "SSH entry" |
| sshd (key only), Avahi, Sunshine, SDDM autologin, herdr-core | desktop | new desktop-only module |

### Toggle (laptop)

`meta + grave` in the normal mode:

1. remember the current workspace (stored by `remote.lua`, not
   `workspace previous`, which drifts when windows open in between);
2. check the desktop answers (Sunshine's port on the desktop's mDNS name);
3. reachable: switch to the dedicated workspace, start Moonlight streaming the
   desktop fullscreen there, or just focus it when already running; enter the
   passthrough submap;
4. unreachable: notify and stay where the owner is (see "Unavailable").

`meta + grave` inside the passthrough submap: leave the submap and go back to
the remembered workspace. Moonlight keeps running in the background, so
returning does not reconnect.

The passthrough submap holds only that one bind; every other key reaches the
focused window (Moonlight), which forwards it to the desktop. Because the
laptop consumes `meta + grave` in both modes, the desktop never receives it.

### Guards

| Trap | Guard |
|---|---|
| Reaching the workspace without the key (mouse, `meta + number`, moving a window) | on `workspace.active`: entering the dedicated workspace enters passthrough, leaving it resets the submap. Passthrough always matches the active workspace |
| Desktop off or off the network | reachability check before opening; notify, do not move |
| Stream drops or Moonlight closes while inside | when the stream window closes: reset the submap, notify "connection lost", go back to the remembered workspace. Moonlight is started straight into the stream from its CLI, so there is no separate launcher window to confuse with it |
| Another window landing on the dedicated workspace | window rule: only Moonlight lives there; anything else is sent back to the remembered workspace |
| Returning to the wrong place | origin workspace stored on the way in; if nothing is stored (after a Hyprland restart or `hyprctl reload`), fall back to workspace 1 |
| Stream on the wrong screen | the dedicated workspace is not bound to a monitor; it opens on the focused monitor |
| Moonlight's own keyboard grab (Ctrl+Alt+Shift+Z) fighting the submap | turned off in Moonlight's settings; Hyprland alone decides binds |
| Desktop rebooted to the login screen | SDDM autologin (owner's decision), so a Plasma session always exists after boot |
| Desktop asleep while the owner is away from it | suspend and monitor sleep turned off on the desktop. The screen lock stays (owner's decision): when locked, the owner types the password through the stream |
| Keys not reaching the desktop through Moonlight on Wayland | spike before writing the Lua: an empty submap plus Moonlight streaming the real desktop, and `meta + 1` must switch the desktop's workspace. If it fails, stop and bring the finding back to the owner |
| A Lua error breaking the config | after each change, `hyprctl configerrors` empty and `hyprctl binds` still lists binds |

### Unavailable

The check probes `fedora.local` directly (it does not depend on the
`Host desktop` entry): Sunshine's TCP port, then port 22. The notification tells
the two cases apart:

- SSH answers but Sunshine does not: "desktop on, no graphical session";
- nothing answers: "desktop unavailable".

With autologin the first case should be rare, but it still happens while Plasma
is starting.

### Desktop (host)

- sshd enabled, public key only (`PasswordAuthentication no`), with the
  laptop's key authorized.
- Avahi, so the desktop answers as `fedora.local` (mDNS publishes the hostname;
  the SSH alias `desktop` points to it).
- Sunshine capturing the real monitor in the Plasma Wayland session, started
  with the session. KMS capture needs `cap_sys_admin` on the binary.
- SDDM autologin into the Plasma Wayland session for the owner's user.
- Suspend and monitor sleep off; screen lock kept.
- herdr-core (`hc`): already installed by `herdr-setup`, which the `terminal`
  module (enabled on `fedora`) clones and installs.
- Firewall: SSH, mDNS and Sunshine's ports reachable from the home network.

Sunshine's `cap_sys_admin` is lost when a package update replaces the binary,
so the desktop module's post-deploy step re-applies it. Sunshine's first-run
admin credentials and the Moonlight PIN pairing are manual, done once, and go
in the walkthrough.

### Laptop (client)

- Moonlight from the Arch package (`moonlight-qt`), not Flatpak. Its window
  identity for rules is checked on the laptop when building.
- Stream settings (resolution matching the laptop screen, bitrate) are set in
  Moonlight's own UI: its config is app state and stays out of the repo.
- `fedora.local` already resolves on the laptop (`nss-mdns` installed, Avahi
  active, `mdns_minimal` in `nsswitch.conf`), but none of it is versioned:
  `nss-mdns` and `avahi` go into `packages.arch.txt`, and `nsswitch.conf` is
  checked in the walkthrough.

### SSH entry

The laptop's `~/.ssh/config` is not in the repo (it holds work servers). The
owner needs a `Host desktop` entry (`HostName fedora.local`, the laptop's
key) because herdr's "Add machine" lists named ssh-config hosts.

### herdr

Once SSH with a key works and `hc` is on the desktop, the owner adds the
machine through herdr's Settings > Machines. Nothing in this repo configures
herdr: its setup lives in the `herdr-setup` repo.

## Acceptance

- From the living room, on the laptop, `meta + grave` shows the desktop screen;
  pressing it again returns to the exact laptop workspace.
- On the stream workspace, `meta + 1` changes the desktop's workspace and not
  the laptop's; on any other workspace the laptop binds work as before.
- Reaching the stream workspace by mouse or `meta + number` also forwards keys;
  leaving it restores the laptop binds.
- Closing Moonlight or losing the connection never leaves the laptop in
  passthrough: the owner is back on the laptop with a notification.
- With the desktop off, `meta + grave` notifies "desktop unavailable" and the
  laptop does not move.
- After a desktop reboot, without touching it, the stream works.
- `ssh desktop` logs in without a password, and herdr on the laptop lists the
  desktop as a machine and opens a space there.
- `dotter deploy` on the desktop installs none of the laptop pieces, and on the
  laptop none of the desktop pieces.
- `hyprctl configerrors` is empty on the laptop after deploy.

## For the builder to decide

- Name of the new desktop-only module and of the dedicated workspace (named or
  special).
- Sunshine install source on Fedora (COPR or Flatpak), as long as KMS capture
  works on Plasma Wayland.
- The reachability check command and its timeout (short enough that the key
  feels instant when the desktop is off).
- How the laptop's `Host desktop` entry gets there: a versioned snippet pulled
  in with `Include`, or documented as a manual step.
- How autologin is configured on SDDM (drop-in under `/etc/sddm.conf.d/`,
  copied as root as the dotfiles design does for `/etc` files).
- Validation on the desktop: the owner runs it there; the builder delivers the
  walkthrough.
