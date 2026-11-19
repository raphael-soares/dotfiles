# Remote access to the home desktop

From the laptop, `SUPER + grave` shows the `fedora` desktop's screen on a
workspace of its own and forwards every key there; the same key brings you
back. herdr reaches the desktop over SSH for terminals.

The `home` module (only on `fedora`) installs and configures the desktop side;
the laptop side lives in `hyprland/hypr/remote.lua`. Design:
[`superpowers/specs/2026-11-18-remote-desktop-access-design.md`](superpowers/specs/2026-11-18-remote-desktop-access-design.md).

## Once, on the desktop

1. Authorize the laptop key before deploying, or SSH stays with passwords
   (the deploy skips the key-only drop-in and says so):

   ```bash
   # on the laptop
   ssh-copy-id -i ~/.ssh/id_ed25519.pub raphael@fedora.local
   ```

2. `dotter deploy`. It installs Sunshine (LizardByte COPR), enables sshd,
   Avahi and Sunshine, gives Sunshine `cap_sys_admin`, opens the firewall,
   sets SDDM autologin and turns off sleep and display off on AC. The screen
   lock stays.
3. Open <https://localhost:47990> and create Sunshine's admin user.
4. Reboot once and check Plasma comes up logged in.

## Once, on the laptop

1. `dotter deploy` installs `moonlight-qt`, `nss-mdns` and `avahi`. Check
   `/etc/nsswitch.conf` has `mdns_minimal [NOTFOUND=return]` on the `hosts:`
   line, before `resolve`.
2. Pair: run `moonlight pair fedora.local`, then type the PIN it shows in
   Sunshine's web UI (PIN tab).
3. In Moonlight's settings: resolution matching the laptop screen, and
   "Capture system keyboard shortcuts" off (Hyprland already forwards them).
4. Add to `~/.ssh/config` (it is not in the repo):

   ```
   Host desktop
       HostName fedora.local
       User raphael
       IdentityFile ~/.ssh/id_ed25519
       IdentitiesOnly yes
   ```

5. herdr: Settings > Machines > Add machine > `desktop`.

## Check

- `ssh desktop true` returns without asking for a password.
- With the desktop on, `SUPER + grave` shows Plasma; `SUPER + 1` switches the
  desktop's virtual desktop, not the laptop's; `SUPER + grave` again returns
  to where you were.
- With the desktop off, `SUPER + grave` notifies "Desktop unavailable".
