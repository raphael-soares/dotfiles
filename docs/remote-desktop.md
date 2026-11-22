# Remote access between the laptop and the desktop

From the laptop, `SUPER + grave` shows the `fedora` desktop's screen on a
workspace of its own and forwards every key there; the same key brings you
back. herdr reaches the desktop over SSH for terminals. The other way round,
the desktop reaches the laptop over SSH only, for herdr (see
[From the desktop to the laptop](#from-the-desktop-to-the-laptop)).

The `sshd` module (both machines) sets up key-only SSH, Avahi and the
firewall. The `home` module (only on `fedora`) installs and configures the
stream on the desktop side; the laptop side lives in
`hyprland/hypr/remote.lua`. Design:
[`superpowers/specs/2026-11-18-remote-desktop-access-design.md`](superpowers/specs/2026-11-18-remote-desktop-access-design.md).

## Once, on the desktop

1. `dotter deploy`. It installs Sunshine (LizardByte COPR), enables Avahi and
   Sunshine, gives Sunshine `cap_sys_admin`, opens the firewall, sets Plasma
   Login Manager autologin and turns off sleep and display off on AC. The
   screen lock stays. sshd stays off: there is no authorized key yet.
2. Authorize the `personal` key, the same pair the laptop uses (it comes with
   the private `~/.ssh` repo):

   ```bash
   cat ~/.ssh/keys/personal.pub >>~/.ssh/authorized_keys
   ```

3. `dotter deploy` again: sshd starts, taking keys only.
4. Open <https://localhost:47990> and create Sunshine's admin user.
5. Reboot once and check Plasma comes up logged in. With the monitor on the
   laptop's input, the desktop's DisplayPort must stay connected
   (`cat /sys/class/drm/card*-DP-1/status`), or Sunshine has no screen.

The desktop is on Wi-Fi: keep Moonlight's bitrate around 10 Mbit/s, or the
stream fills the link and the delay climbs to hundreds of milliseconds.

## Once, on the laptop

1. `dotter deploy` installs `moonlight-qt`, `nss-mdns` and `avahi`. Check
   `/etc/nsswitch.conf` has `mdns_minimal [NOTFOUND=return]` on the `hosts:`
   line, before `resolve`.
2. Pair: run `moonlight pair fedora.local`, then type the PIN it shows in
   Sunshine's web UI (PIN tab).
3. In Moonlight's settings: resolution matching the laptop screen, bitrate
   10 Mbit/s, and "Capture system keyboard shortcuts" on, always. Without it
   Moonlight drops the Super key, so `SUPER + 1` never reaches Plasma;
   `SUPER + grave` still works because Hyprland binds it with `dont_inhibit`.
   Also turn on "Optimize mouse for remote desktop instead of games": the
   cursor then follows the laptop's own pointer instead of getting Plasma's
   acceleration on top of the touchpad's.
4. The `desktop` host comes from the private `~/.ssh` repo
   (`config.d/personal.conf`): `Host personal-desktop desktop`, user
   `raphael`, key `~/.ssh/keys/personal`.

5. herdr: Settings > Machines > Add machine > `desktop`.

## Check

- `ssh desktop true` returns without asking for a password.
- With the desktop on, `SUPER + grave` shows Plasma; `SUPER + 1` switches the
  desktop's virtual desktop, not the laptop's; `SUPER + grave` again returns
  to where you were.
- With the stream open, `SUPER + grave` switches at once, without the checking
  notification.
- With the desktop off, `SUPER + grave` says it is checking, then "Desktop is
  off or not on the network".

## From the desktop to the laptop

Terminals only: no stream of the laptop's screen. Design:
[`superpowers/specs/2026-11-22-laptop-ssh-access-design.md`](superpowers/specs/2026-11-22-laptop-ssh-access-design.md).

1. On the laptop, authorize the `personal` key, the same pair the desktop
   uses:

   ```bash
   cat ~/.ssh/keys/personal.pub >>~/.ssh/authorized_keys
   ```

2. On the laptop, `dotter deploy`. It installs `openssh`, enables Avahi and
   starts sshd with keys only (without step 1 it leaves sshd off).
3. Check the drop-in applied: `sudo sshd -T | grep -i passwordauthentication`
   prints `no`.
4. The `laptop` host comes from the private `~/.ssh` repo
   (`config.d/personal.conf`): `Host personal-laptop laptop`,
   `HostName arch.local`.
5. herdr on the desktop: Settings > Machines > Add machine > `laptop`.

With the lid closed and no monitor or dock, the laptop suspends 10 s later
unless it is on the charger (`hyprland/hypr/monitors.lua`). Suspended, it
does not answer SSH: open the lid or plug it in.

Check: `ssh laptop true` on the desktop returns without asking for a
password, also with the lid closed on the charger.
