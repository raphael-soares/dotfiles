# Media admin proxy

## Why

Every admin tool of the media stack published its own host port on
`127.0.0.1` (Sonarr 8989, Radarr 7878, Prowlarr 9696, Bazarr 6767, Whisper
9000). Sonarr's 8989 collided with Spotifast's sign-in callback and blocked
the login. The owner wants the stack encapsulated: one entry point, readable
names, no host port per app.

## Goals

- The admin tools stop publishing host ports; they are reached through one
  reverse proxy as `http://<app>.localhost`.
- The `media-*` scripts and `docs/media.md` use the same names.
- Containers keep talking to each other by name on `media.network`.

## Non-goals

- Access from outside the house (Tailscale): decided against for now.
- Changing how the TV and phone reach Jellyfin and Seerr.

## Anti-goals

- Breaking the TV app or Seerr on the phone.
- A proxy that needs the podman socket or discovers containers by itself.

## Approaches

- **Caddy on port 80 (picked).** Static Caddyfile in the repo, clean
  addresses. Needs `net.ipv4.ip_unprivileged_port_start=80`, one root step.
- Caddy on a high port: no system change, but `:8000` in every address.
- Traefik with labels: auto discovery needs the podman socket; overkill for
  five fixed apps.

## Design

- New quadlet `media/containers/caddy.container` on `media.network`,
  publishing port 80 on loopback only, IPv4 and IPv6 (`*.localhost` resolves
  to `::1` on this machine).
- `media/caddy/Caddyfile`: plain HTTP, one site per app, `<app>.localhost`
  to `<container>:<port>`: sonarr, radarr, prowlarr, bazarr, whisper, plus
  jellyfin and seerr as convenience names on this PC.
- Sonarr, Radarr, Prowlarr, Bazarr and Whisper lose `PublishPort`.
- Jellyfin (`0.0.0.0:8096`) and Seerr (`0.0.0.0:5055`) keep their LAN ports
  unchanged for the TV and phone.
- `media-deploy` writes a sysctl drop-in
  (`/etc/sysctl.d/`, `ip_unprivileged_port_start=80`) with sudo when missing,
  and links the Caddyfile like the other config dirs.
- `media-lib.sh`, `media-watchdog`, the Bazarr call in `media-deploy` and
  `docs/media.md` switch to `http://<app>.localhost`. `run_configarr` waits on
  the proxied names.
- Today's uncommitted Sonarr move to 8990 is dropped by this change.

## Left to the builder

- Caddy image tag and whether `AutoUpdate=registry` applies, following the
  other quadlets.
- How the watchdog reports the proxy itself being down.
