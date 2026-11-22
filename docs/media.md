# Media stack

Pick a film or series in Seerr; Radarr or Sonarr finds a release, qBittorrent
downloads it, the file is hardlinked into `~/Media/Movies` or `~/Media/Series`,
Bazarr fetches pt-BR and English subtitles (never the hearing-impaired kind),
and the Samsung TV plays it in the Jellyfin app.

The `media` module (only on `fedora`) runs the services as rootless Podman
quadlets on the `media` network. qBittorrent is the desktop app (Fedora RPM)
and Jellyfin Desktop (flatpak) plays on this PC. Design:
[`superpowers/specs/2026-11-21-media-stack-design.md`](superpowers/specs/2026-11-21-media-stack-design.md).

## What runs

| Service | Address | Reachable from |
|---|---|---|
| Jellyfin | <http://fedora.local:8096> | LAN |
| Seerr | <http://fedora.local:5055> | LAN |
| qBittorrent WebUI (used by Radarr and Sonarr) | `host.containers.internal:8080` | containers, password in `media.env` |
| Radarr | <http://127.0.0.1:7878> | this PC |
| Sonarr | <http://127.0.0.1:8989> | this PC |
| Prowlarr | <http://127.0.0.1:9696> | this PC |
| Bazarr | <http://127.0.0.1:6767> | this PC |
| FlareSolverr | `flaresolverr:8191` | containers only |

qBittorrent listens for peers on 9386 (TCP and UDP). The router has no UPnP
gateway, so incoming peers only reach it if 9386 is forwarded by hand on the
router.

Inside the network, services reach each other by container name
(`http://radarr:7878`). `podman-auto-update.timer` pulls new images daily;
`configarr.timer` reapplies the YAML daily.

## Where things live

| What | Path |
|---|---|
| Quadlets | `media/containers` → `~/.config/containers/systemd/media` |
| Secrets (API keys, OpenSubtitles login) | `~/.config/media/media.env`, mode 600, generated on first deploy |
| App state and databases | `~/.local/share/media/<service>` |
| Caches (Jellyfin transcodes, TRaSH repos) | `~/.cache/media` |
| Downloads | `~/Media/Downloads/{Movies,Series}` |
| Library | `~/Media/Movies`, `~/Media/Series` |
| `.torrent` copies | `~/Personal/Torrents` |

`dotter deploy` runs `media/bin/media-deploy`, which:

- fills empty `*APIKEY` and `*WEBUI_PASSWORD` values in `media.env`, adding
  keys that are new in `media.env.example`;
- starts the units, restarting the ones whose quadlet changed;
- seeds `~/.config/qBittorrent/qBittorrent.conf` when it does not exist
  (WebUI on, starts hidden in the tray, monochrome tray icon), starts
  qBittorrent if needed and applies `media/qbittorrent/preferences.json` and
  `categories.json` (categories not in the file are removed);
- renders Bazarr's config from `media/bazarr/config.yaml.tmpl` and applies the
  pt-BR and English language profile;
- runs Configarr (`media/configarr/config.yml`): quality profiles, sizes,
  naming, root folders, the qBittorrent client, Prowlarr indexers and apps;
- makes qBittorrent the magnet link handler and installs Jellyfin Desktop.

`media/autostart` starts qBittorrent hidden at login.

Prowlarr searches 1337x, The Pirate Bay, YTS, EZTV, LimeTorrents, Knaben and
Torrentio, the same addon Stremio uses. Torrentio has no stock
Prowlarr definition: `media/prowlarr/definitions/torrentio.yml` is mounted as
a custom one and only searches by IMDb id.

## Once, after the first deploy

1. Subtitles: create a free account at <https://www.opensubtitles.com>, put
   it in `media.env` (`OPENSUBTITLESCOM_USERNAME`, `OPENSUBTITLESCOM_PASSWORD`)
   and `dotter deploy` again.
2. Jellyfin, at <http://127.0.0.1:8096> (or Jellyfin Desktop): run the wizard, add the libraries
   `Movies` (`/home/raphael/Media/Movies`) and `Series`
   (`/home/raphael/Media/Series`), preferred subtitle language Portuguese
   (Brazil), subtitle mode Always. In Dashboard → Playback → Transcoding pick VAAPI with
   `/dev/dri/renderD128`.
3. Seerr, at <http://127.0.0.1:5055>: sign in with the Jellyfin account
   (server `http://jellyfin:8096`), then add Radarr (`radarr`, port 7878,
   profile `4K (1080p fallback)`, root `/home/raphael/Media/Movies`) and Sonarr
   (`sonarr`, port 8989, profile `1080p (4K when available)`, root
   `/home/raphael/Media/Series`). The API keys are in `media.env`.
4. TV: on Samsung models from 2021 on, install Jellyfin from the app store.
   On 2018 to 2020 models, sideload it with Apps2Samsung. Point it at
   `http://fedora.local:8096` (or `http://192.168.1.211:8096`).

## Quality

Films use `4K (1080p fallback)`: 2160p WEB or Bluray encode first, 1080p when
there is none, no Remux, at most 190 MB per minute (about 23 GB for two hours).
Series use `1080p (4K when available)`: WEB 2160p above WEB 1080p, same cap.
Dolby Vision without an HDR fallback is rejected, since the TV would show it
with wrong colors.

To check the TV plays without transcoding, start something and open
Dashboard → Activity in Jellyfin: the session should say "Direct Playing".
"Transcoding" with a reason means the container, audio or subtitle format
forced the PC to convert it.

## qBittorrent

Radarr and Sonarr reach the desktop app's WebUI at
`host.containers.internal:8080` with user `media` and the password in
`media.env`. The WebUI listens on every interface (containers reach the host
through its LAN address), so the password is what keeps the LAN out.
Closing the window keeps it in the tray.

Radarr and Sonarr download into the qBittorrent categories `Movies` and
`Series` (`~/Media/Downloads/{Movies,Series}`) and hardlink the finished file
into `~/Media/Movies` or `~/Media/Series`, renamed. A torrent added by hand
with one of those categories is imported the same way when its film or series
is already in Radarr or Sonarr (request it in Seerr first); otherwise it waits
in that app's Activity queue for a manual import.

To add a category, add a `"Name": "/absolute/path"` line to
`media/qbittorrent/categories.json` and `dotter deploy`. Subcategories use a
slash (`Games/Switch`).
