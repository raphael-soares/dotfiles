# Remote access between `arch` and `fedora`

On either machine, `SUPER + grave` shows the other machine's screen over the
current one, on the special workspace `special:<peer>` (`special:fedora` on
`arch`, `special:arch` on `fedora`), and forwards every key there. The same
key hides it again; the workspace underneath is untouched. herdr reaches each
machine from the other over SSH for terminals.

Both machines run Sunshine from boot, before anyone logs in, so the stream
can show the other machine's login screen: type the password through the
stream. Neither machine logs in by itself.

The `hyprland` module (both machines) carries all of it: Sunshine, Moonlight,
`hyprland/hypr/remote.lua`, the greetd config and the bar indicator. Each
`machine.lua` names the other machine in `M.peer`. The `sshd` module sets up
key-only SSH, Avahi and the firewall. Design:
[`superpowers/specs/2026-11-23-mutual-remote-access-design.md`](superpowers/specs/2026-11-23-mutual-remote-access-design.md).

## Sun and moon

The bar shows a sun, just left of the clock, while the other machine is
watching this one, and a moon while this machine shows the other.
Both read files in `$XDG_RUNTIME_DIR/remote/`: `serving`, kept by
`remote-serving.service` from Sunshine's log, and `viewing`, kept by
`remote.lua` while Moonlight is open.

Clicking the sun or moon opens a small panel: show or hide the other screen,
swap the direction, or end the stream. It runs `remote-control show|stop|swap`
(`hyprland/bin`), which reaches the other machine over SSH when the action is
on that side, so ending or swapping works from either end.

The two never stream each other. When the other machine connects, this
machine's Moonlight closes and a notification says why.

## Once, on each machine

1. Authorize the `personal` key (it comes with the private `~/.ssh` repo):

   ```bash
   cat ~/.ssh/keys/personal.pub >>~/.ssh/authorized_keys
   ```

2. `dotter deploy`, then run what it prints under "Still to do by hand"
   (`.dotter/missing.sh` prints it again): Sunshine (LizardByte COPR on
   Fedora, `sunshine-bin` from the AUR on Arch) and `moonlight-qt`,
   `cap_sys_admin` for KMS capture, linger, `sunshine-prelogin.service` and
   `remote-serving.service` as system units, the firewall ports, the shared
   greetd config and sshd with keys only. The deploy itself disables
   Sunshine's user unit and sets `capture = kms`.
3. Open <https://localhost:47990> on that machine and create Sunshine's admin
   user. From the other machine the browser usually cannot resolve `.local`,
   and an IP address needs `csrf_allowed_origins` in `sunshine.conf`.
4. Check `/etc/nsswitch.conf` has `mdns_minimal [NOTFOUND=return]` on the
   `hosts:` line, before `resolve`.
5. The other machine's host comes from `~/.ssh/config.d/personal.conf`
   (`Host fedora` / `Host arch`, `HostName <name>.local`); herdr:
   `hc machine add <peer>`.

## Pairing, once per direction

On the machine that will watch, run `moonlight pair <peer>.local --pin 1234`
(any four digits), then type that PIN in the PIN tab of the peer's Sunshine
web UI. Moonlight uses Sunshine's default `Desktop` app.

If Sunshine restarted between the first Moonlight contact and the PIN, the
pairing stalls with "Found unexpected PC": remove the `[hosts]` section of
`~/.config/Moonlight Game Streaming Project/Moonlight.conf` and pair again.

In Moonlight's settings: bitrate around 10 Mbit/s (`fedora` is on Wi-Fi, and
more fills the link), "Capture system keyboard shortcuts" always on (or the
Super key never reaches the other side; `SUPER + grave` still works because
Hyprland binds it with `dont_inhibit`), and "Optimize mouse for remote desktop
instead of games" on.

## Check

- `ssh <peer> true` returns without asking for a password.
- `SUPER + grave` shows the other machine; `SUPER + 1` switches its workspace,
  not this one's; `SUPER + grave` again hides it.
- With the stream open, `SUPER + grave` shows it at once, without the checking
  notification.
- With the other machine off, `SUPER + grave` says it is checking, then
  "<peer> is off or not on the network".
- After a reboot of the other machine, the stream shows its login screen.
- Sun on the watched machine, moon on the watching one.

## Notes

- `arch` streams the screen Sunshine finds: the LG when it is on `arch`'s
  input, the built-in screen otherwise (`arch` turns the LG off while it shows
  `fedora`, see `docs/machines.md`). With the monitor on the other input
  `fedora`'s DisplayPort must stay connected
  (`cat /sys/class/drm/card*-DP-1/status`), or its Sunshine has no screen;
  the EDID override in the `home` module keeps it so.
- With the lid closed and no monitor or dock, `arch` suspends 10 s later
  unless it is on the charger (`laptop/hypr/lid.lua`). Suspended, it answers
  neither SSH nor Moonlight.
