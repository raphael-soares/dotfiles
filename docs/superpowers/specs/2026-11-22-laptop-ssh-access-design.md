# SSH from the home desktop to the laptop

## Intent

The laptop already reaches the desktop (`docs/remote-desktop.md`). The owner
wants the reverse for terminals only: from the desktop, `ssh laptop` and the
laptop listed as a machine in herdr. Seeing the laptop's screen is not needed
for now, so no Sunshine or Moonlight on this side.

## Goals

- `ssh laptop true` on the desktop returns without a password.
- herdr on the desktop adds `laptop` as a machine and opens a space there.
- The laptop stays reachable when it sits closed on the desk on the charger.

## Non-goals

- The laptop's screen from the desktop (Sunshine on Hyprland, a KWin toggle).
- Access from outside the house.

## Anti-goals

- A closed laptop in the backpack, on battery, kept awake.
- The laptop's sshd taking passwords on a network outside the house.
- Two copies of the sshd setup, one per module.

## Approaches

| Option | Trade-off | Decision |
|---|---|---|
| Lid: do not suspend while on AC | closed on the desk stays reachable; on battery it suspends as today | owner's pick |
| Lid: leave as is | no change, but a closed laptop on the desk drops off the network | rejected |
| Lid: never suspend | always reachable, but heats and drains in the backpack | rejected |
| sshd setup in a new `sshd` module on both machines | one place for key-only sshd, mDNS and firewall; `home` keeps only what is about the stream | my call |
| Copy the `home` sshd lines into `hyprland` | fastest, two copies drift | rejected |

## Design

- New dotter module `sshd`, enabled in `arch.toml` and `fedora.toml`:
  `packages.<distro>.txt` with the SSH server, Avahi and nss-mdns (moved out of
  `home` and `hyprland`), `50-key-only.conf` (moved from `home/ssh`), and the
  post-deploy block now in `home`: with `authorized_keys` non-empty, copy the
  key-only drop-in and start `sshd`; without it, leave `sshd` off (it would
  take passwords on any network). Always enable `avahi-daemon`; open ssh and
  mdns in firewalld when it exists (Fedora).
- `hyprland/hypr/monitors.lua`: the lid timer does not suspend while a
  `Mains` power supply reports `online`. Unplugging with the lid closed
  suspends 10 s later, as today.
- SSH entry `Host personal-laptop laptop` (`HostName arch.local`, key
  `~/.ssh/keys/personal`) in the private `~/.ssh` repo, next to `desktop`.
- `docs/remote-desktop.md` gets the reverse walkthrough; the README lists the
  module; `tests/machines.sh` expects the sshd lines in both hooks.

## Left to the builder

- Checking on the laptop that Arch's `sshd_config` includes
  `sshd_config.d/*.conf`, so the drop-in applies (`sudo sshd -T`).
