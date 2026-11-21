# Media stack: local Netflix on the home PC

## Why

Picking a film today means finding a magnet in Stremio, downloading it in the
qBittorrent flatpak and watching it in Haruna on a Full HD monitor. The living
room TV is 4K, but streaming torrents to it only works for well-seeded titles;
niche films have to be watched at the desk. The owner wants to pick a title
from the couch, have it found, downloaded, organized and subtitled on its own,
and watch it on the TV, with the whole thing declared in this repo so a fresh
install brings it back.

## Goals

- Pick a film or series in a catalog (from the phone, on the LAN) and find it in
  the Jellyfin app on the TV once it is downloaded, with pt-BR subtitles, with
  no manual step in between.
- 4K titles play on the Samsung TV over Wi-Fi without stalling; the downloaded
  file is played whole, so seed count only affects how long the download takes.
- Everything that can be configuration lives in the dotfiles `media` module and
  comes back with `dotter deploy` on a reinstalled machine. What cannot be
  (first-run wizards) is listed in the module doc as one-time steps.
- The qBittorrent container replaces the flatpak for every category (films,
  series, games, books, mangas), and clicking a magnet link (from Stremio or a
  browser) still adds it to qBittorrent, letting the owner pick the category.
- The 24 torrents the flatpak is seeding today keep seeding from the container,
  and the 12 GB already in `~/Media/Movies` show up in Jellyfin.

Non-goals: access from outside the home network, VPN, other users' accounts,
music, the Stremio-to-Jellyfin bridge (Jellio), Haruna changes. Haruna keeps
opening files from `~/Media` as today.

Anti-goals: a stack that only works after clicking through each app's UI on
every reinstall; files in `~/Media` owned by a subuid or root; 4K files the TV
cannot play directly being the norm (that means constant transcoding over a
weak link); torrent automation UIs reachable from the LAN without need.

## Constraints

- Machine: `fedora` (home PC), Fedora 44, Podman 5.8 rootless, no Docker.
  Linger is already enabled for `raphael`. i5-12400F (no iGPU) and Radeon RX
  6600 (`/dev/dri/renderD128`, owner in `render` and `video`).
- Network: the PC is on 2.4 GHz Wi-Fi (about 58 Mbit/s nominal TX, measured
  `iw dev wlp7s0 link`); 5 GHz is worse where the PC sits and a cable is not
  possible. The TV is on 5 GHz. 4K remux (50 to 100 Mbit/s) does not fit; 4K
  WEB-DL (15 to 30 Mbit/s) does.
- TV: Samsung (Tizen), year unknown. Official Jellyfin app is in the Samsung
  store for 2021+ models, sideload (Apps2Samsung) for 2018 to 2020. No Dolby
  Vision; HDR10/HDR10+ and HEVC play natively; image subtitles (PGS) and some
  audio codecs (DTS on several models) force conversion.
- Firewall zone is `FedoraWorkstation`, which already accepts TCP/UDP on ports
  1025 to 65535 from the LAN. Any port published on `0.0.0.0` is reachable from
  the LAN without a firewall rule.
- The repo is public. Secrets (API keys, passwords, subtitle provider login)
  stay out of git, following the existing `.env.example` pattern.
- Home layout rules (`ai/AGENTS.md`): `~/Media/<Type>` per media type, no hidden
  folders, `.torrent` files go to `~/Personal/Torrents`, games to `~/Games`.
- Current qBittorrent (flatpak, `~/.var/app/org.qbittorrent.qBittorrent`):
  listen port 9386 with UPnP on (no `PortForwardingEnabled` override), torrent
  export to `~/Personal/Torrents`, categories `Movies`, `Series`, `Books`,
  `Mangas` under `~/Media`, `Games`, `Games/PC`, `Games/Switch`
  (`~/Games/Switch/Library`), `Games/PSP`, `Games/PSX`. It is the
  `x-scheme-handler/magnet` default and has an autostart entry.
- Its 24 torrents: 20 under `~/Games`, and 4 films seeding from
  `~/Media/Movies` itself (28 Days Later, Harakiri, Possession, Requiem for a
  Dream). `Saving Private Ryan (1998)` in the same folder is not a torrent.
- `~/Media` is not a SyncFast pair (`desktop/syncfast/config.toml`), so
  downloads and hardlinks there are never uploaded.

## Approaches

| Approach | Trade-off |
|---|---|
| One Podman quadlet per service on a shared Podman network (picked) | Each service starts, restarts and updates on its own under systemd; dotter links the files (quadlet follows symlinks, `podman-systemd.unit(5)`); about eight small files |
| One pod quadlet holding every container | Less network config, but restarting one restarts the group and all ports share one namespace |
| `compose.yaml` with podman-compose | Familiar format, but outside systemd: extra package, boot start becomes a workaround, less declarative |

## Design

### Services

| Service | Role | Reachable from |
|---|---|---|
| Jellyfin | library and player server; hardware transcoding on the RX 6600 (VAAPI) | LAN, 8096 |
| Seerr | catalog to request titles (replaced Jellyseerr/Overseerr in Feb 2026) | LAN, 5055 |
| Radarr, Sonarr | search, grab, rename and hardlink films and series | PC only |
| Prowlarr | indexer list, synced to Radarr and Sonarr | PC only |
| qBittorrent | the only torrent client, all categories; listen port 9386 kept | WebUI PC only; incoming peers keep working as today (UPnP) |
| Bazarr | pt-BR SRT subtitles for films and series | PC only |
| FlareSolverr | lets Prowlarr reach public trackers behind Cloudflare | PC only (internal) |
| Configarr | applies quality profiles, root folders, download clients and Prowlarr config from YAML | runs and exits |

"PC only" means the port is published on `127.0.0.1`. Services reach each other
by container name on the shared network. Rootless UPnP from a bridged container
maps the router to an address the router cannot reach, so qBittorrent may need
host networking to keep UPnP; then the others reach it through the host
(builder's call, the requirement is the incoming-peer behavior).

### Paths

Host paths are mounted at the same path inside every container
(`/home/raphael/Media` is `/home/raphael/Media` inside), so the flatpak's
categories and resume data carry over without rewriting, and no app needs a
remote path mapping.

- `~/Media` is one mount for qBittorrent, Radarr, Sonarr, Bazarr and Jellyfin,
  so hardlinks work (they fail across bind mounts even on the same filesystem).
- Downloads for the automated flow go to `~/Media/Downloads/<category>`;
  Radarr and Sonarr hardlink into `~/Media/Movies/<Title (Year)>/` and
  `~/Media/Series/<Title>/Season NN/`. The download keeps seeding; the library
  copy costs no extra space.
- qBittorrent also mounts `~/Games` and `~/Personal/Torrents` (export dir).
- App state (databases, caches) lives in `~/.local/share/media/<service>`, out
  of git and out of the synced areas. Jellyfin's transcode cache goes in
  `~/.cache`.
- Files written to `~/Media`, `~/Games` and `~/Personal/Torrents` end up owned
  by `raphael` on the host. How each image gets there (root-in-userns,
  `UserNS=keep-id`, PUID/PGID) is the builder's call per image; Seerr ignores
  PUID/PGID by design.

### Quality and language

- Original audio, pt-BR subtitles as separate SRT files (Bazarr). No dubbed
  preference.
- Films: prefer 4K WEB-DL, HEVC, HDR10 or HDR10+, under a size cap that keeps
  the bitrate near 25 Mbit/s (about 25 GB for two hours). Reject remux and
  Dolby Vision-only releases (DV with an HDR10 base layer is fine). Fall back to
  1080p when no 4K release exists, which is common for niche films.
- Series: 1080p WEB-DL by default, 4K under the same rules when available.
- Profiles come from TRaSH Guides through Configarr, with the overrides above.

### Declarative configuration

- Quadlets, the network, Configarr's YAML, qBittorrent's and Bazarr's config
  files live in a new dotter module `media`, enabled only in
  `.dotter/fedora.toml`.
- API keys for Radarr, Sonarr and Prowlarr are fixed through environment
  variables (`<APP>__AUTH__APIKEY`) read from `~/.env.local`, so Configarr and
  Prowlarr can wire the apps together on first boot without the UI.
  `.env.example` gains the keys with empty values, plus the OpenSubtitles.com
  login and API key for Bazarr.
- qBittorrent's WebUI has no password: auth is bypassed for localhost and the
  Podman network subnet, and the WebUI port is never published to the LAN.
  The repo owns `categories.json` and the settings this design names (paths,
  export dir, port, auth bypass); deploy writes those keys with qBittorrent
  stopped and leaves the rest of `qBittorrent.conf` to the app. A category
  added in the UI and not in the repo is dropped on the next deploy: new
  categories go through the repo (the skill says so).
- Bazarr: OpenSubtitles.com (free account, the widest pt-BR coverage) plus the
  keyless providers that carry pt-BR. Its config is rendered from the repo with
  the secrets from `~/.env.local`.
- Indexers: a fixed list of public general trackers (1337x, The Pirate Bay,
  YTS, EZTV, TorrentGalaxy class), declared in the repo through Configarr's
  Prowlarr support. Private trackers are out of scope; 1080p fallback covers
  the niche titles public trackers lack in 4K.
- Configarr 1.33 (Sep 2026) manages download clients, root folders and Prowlarr
  resources per its changelog. Whatever it turns out not to cover is done by a
  small idempotent API call block in `post_deploy.sh`, never by hand.
- Configarr runs as a oneshot unit on deploy and daily through a timer.
- Images update through `AutoUpdate=registry` and `podman-auto-update.timer`.
- `post_deploy.sh` (`{{#if dotter.packages.media}}`): create the state and
  download dirs, `systemctl --user daemon-reload`, start the units, enable the
  auto-update timer, run Configarr.
- One-time steps that stay manual, written in `docs/media.md`: create the
  OpenSubtitles.com account and fill `~/.env.local`, Jellyfin first-run wizard
  and libraries, Seerr setup (connect Jellyfin, Radarr, Sonarr), Jellyfin app on
  the TV (store for 2021+ Samsung, Apps2Samsung for 2018 to 2020).

### Migrating from the flatpak

- The 24 torrents in the flatpak session move to the container. The 20 game
  torrents keep seeding from their current paths with their categories.
- The 4 film torrents are moved by qBittorrent ("set location", which moves the
  data and keeps seeding) to `~/Media/Downloads/radarr` under the Radarr
  category, then Radarr imports them like any finished download: hardlinks
  into the library, originals keep seeding. Nothing renames a file a torrent
  still points at.
- `Saving Private Ryan (1998)` is imported in place through Radarr's library
  import.
- Categories move as they are, except `Movies` and `Series`, which give way to
  the Radarr and Sonarr categories under `~/Media/Downloads`.
- The flatpak's autostart entry and its magnet default go away; the flatpak
  itself is uninstalled once the container has the session.
- Clicking a magnet link opens a way to add it to the container's qBittorrent
  with a category choice before the download starts (mechanism is the
  builder's call: browser protocol handler on the WebUI, a desktop entry, or
  similar), declared in the repo.

### Docs and rules

- `docs/media.md`: what runs, ports, where state lives, one-time steps, how to
  check direct play in the Jellyfin dashboard.
- `README.md` module table gains `media`.
- `ai/AGENTS.md`: the qBittorrent paragraph changes from "the flatpak exports
  and maps categories" to the container, with Movies and Series going through
  Radarr and Sonarr.
- The `qbittorrent-categoria-para-pasta` skill is updated to the container
  (where categories live, how to add one).
- `tests/machines.sh` checks the `media` links on `fedora` and their absence on
  `arch`, and that the rendered hook carries the `media` block.

## Left to the builder

- Image choice per service (official vs linuxserver vs hotio), as long as each
  is maintained and supports `AutoUpdate=registry`.
- How each container maps ownership (see Paths).
- The magnet handler mechanism.
- Exact size caps and TRaSH profile names, within the quality rules above.
- Seeding and ratio limits: keep the flatpak's current behavior (no limits).
- How the flatpak session is exported and imported, as long as no torrent
  rechecks from zero or loses its category.
