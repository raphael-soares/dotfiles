# Homelab names on the home network

## Why

The desktop is turning into the home server besides the gaming PC. The owner
wants the services people use from other devices to have standard, readable
names: `jellyfin.homelab.local` from the laptop instead of
`fedora.local:8096`.

## Goals

- `http://jellyfin.homelab.local` and `http://seerr.homelab.local` open
  Jellyfin and Seerr from any device on the home network.
- The admin tools (Sonarr, Radarr, Prowlarr, Bazarr, Whisper) stay reachable
  only from this PC, at `<app>.localhost`.
- `fedora.local:8096` and `fedora.local:5055` keep working.

## Non-goals

- Renaming the machine (it stays `fedora`).
- Access from outside the house; router DNS; a self-hosted DNS server.
- Renaming the `media/` module.

## Anti-goals

- Any device on the Wi-Fi reaching an admin tool, which has no password.

## Constraints

- Rootless podman hides the client address: loopback and LAN connections both
  reach the container from `10.89.42.24` (tested). Caddy cannot tell them
  apart by source, only by which published port they came in on.
- The firewalld zone `FedoraWorkstation` only opens 1025-65535 to the LAN.
- This PC uses `192.168.1.250` as a static address set in NetworkManager on the "Adriana 2.4G" connection; the router panel is unreachable (unknown password).
- `.local` names come from Avahi, already running.

## Approaches

- **One Caddy, two entries (picked).** Loopback `:80` keeps serving every
  name; `192.168.1.250:80` maps to a second container port that only knows
  the two LAN names.
- Two Caddy containers: same result, two pieces to keep.
- Caddy outside `media.network` with source-preserving networking: loses
  container name resolution.

## Design

- `caddy.container` adds `PublishPort=192.168.1.250:80:8080`. The Caddyfile
  serves `jellyfin.homelab.local` and `seerr.homelab.local` on `:8080` only;
  every `*.localhost` site stays on `:80`.
- The LAN IP lives only in that `PublishPort` line; everything else reads it
  from there.
- A user service publishes both names with Avahi, pointing at that IP, and
  restarts if Avahi does.
- `media-deploy` opens TCP 80 in the active firewalld zone, with sudo, when
  closed.
- `docs/media.md` lists the LAN names and the router reservation.

## Left to the builder

- Whether a second-level `.local` name resolves on the phone and the TV is
  checked after deploy; if it fails, the fallback is `jellyfin.local` and
  `seerr.local`, decided with the owner.
- Seerr's Application URL stays `http://fedora.local:5055` until the new
  names are confirmed on every device.
