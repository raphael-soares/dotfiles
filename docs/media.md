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
| Whisper (speech to text for Bazarr) | <http://127.0.0.1:9000> | this PC |

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
| Library | `~/Media/Movies`, `~/Media/Series`, `~/Media/Anime` |
| `.torrent` copies | `~/Personal/Torrents` |

`dotter deploy` runs `media/bin/media-deploy`, which:

- links every file in `media/bin`, `media/systemd`, `media/applications` and
  `media/autostart` and the `media/containers`, `media/configarr`,
  `media/prowlarr/definitions` and `media/whisper` directories, and removes
  links whose file left the repo, so a new script or timer works without
  `dotter deploy` (which needs sudo): `media-deploy ~/.dotfiles` is enough;
- fills empty `*APIKEY` and `*WEBUI_PASSWORD` values in `media.env`, adding
  keys that are new in `media.env.example`;
- starts the units, restarting the ones whose quadlet changed;
- seeds `~/.config/qBittorrent/qBittorrent.conf` when it does not exist
  (WebUI on, starts hidden in the tray, monochrome tray icon, Breeze style
  with system icons, no status bar, no "torrent added" notification), starts
  qBittorrent if needed and applies `media/qbittorrent/preferences.json`
  (`.torrent` copies to `~/Personal/Torrents`, category paths also in manual
  mode) and `categories.json` (categories not in the file are removed);
- renders Bazarr's config from `media/bazarr/config.yaml.tmpl` (subtitle
  timing fixed with subsync when the match score is low, Whisper as the last
  provider) and applies the pt-BR and English language profile;
- runs Configarr (`media/configarr/config.yml`): quality profiles, sizes,
  naming, root folders, the qBittorrent client, Prowlarr indexers and apps;
- once `JELLYFIN_TOKEN` is set, applies `media/jellyfin` to Jellyfin: plugin
  repositories and plugins (Intro Skipper, Jellyfin Enhanced and its
  dependencies), the custom CSS on top of the default theme, the Jellyfin
  Enhanced settings that differ from its defaults (`enhanced.json`) with the
  Seerr, Radarr and Sonarr keys filled in, every user's home sections and
  subtitle preferences (pt-BR, Always), and the Shows library cover when it
  has none. Backdrops in Jellyfin Desktop and on the phone are a per-device
  setting (Settings → Display → Backdrops);
- once Seerr is signed in, applies `media/seerr`: Application URL and the
  Radarr and Sonarr servers;
- makes qBittorrent the magnet link handler and installs Jellyfin Desktop;
- enables every `media-*.timer` in `media/systemd` and
  `podman-auto-update.timer`: `media-original-audio` (every 15 minutes),
  `media-watchdog` (every 5 minutes), `media-letterboxd` (every 6 hours),
  `media-cleanup`, `media-backup` and `media-drift` (daily), and
  `media-dub-search` and `media-restore-test` (weekly).

`media-deploy ~/.dotfiles --check` changes nothing, prints one
`media: differs:` line for each link, timer, unit, qBittorrent, Bazarr, Seerr
or Jellyfin setting that is not what the repo says, and exits 1 when there is
any (Configarr is left out: its timer re-applies Radarr, Sonarr and Prowlarr
every hour). It also prints a `media: unhealthy:` line for each problem a
service reports (a Radarr, Sonarr or Prowlarr health warning, a paused Bazarr
subtitle site, qBittorrent offline, a failed unit) and exits 1 for those too.
`media-drift` runs it daily, so either lands in the media log.

The media log, `~/.local/state/media/media.log`, is one timeline of what the
stack did and what broke: every change a script or the deploy made (a torrent
replaced or deleted, a film removed, a backup uploaded, a setting applied, a
service restarted) with its time and script, and every failed `media-*` or
Configarr run with the last lines it printed. It keeps about its last 5000
lines. `mediactl log` shows the end of it (`mediactl log 200`, or
`mediactl log -f` to follow); the same lines are also in the journal.

After changing Jellyfin in its dashboard, `media-jellyfin-export ~/.dotfiles`
writes the tracked settings back into `media/jellyfin`: the custom CSS, plugin
repositories, the Jellyfin Enhanced settings that differ from its defaults,
the admin's home sections and the playback keys already in `user.json` (a new
playback key has to be added to the file by hand to be tracked).

`mediactl` drives the stack from the terminal, and the `midia` skill teaches
agents to use it: search, request, releases and grab, `info` (file, quality,
audio and subtitles), `subs` (missing subtitles), `research` (search again),
`watched` (what each Jellyfin user played last), `delete` (unmonitor, then
delete the file), `queue`, `log` and `status` (disk, torrent tags, downloads,
health problems and the runs that failed in the last 7 days). It and the
other scripts share `media/bin/media-lib.sh` (`api <app> <method> <path>`,
`qbt`, `env_get`, `health`, `log`).

`media-original-audio` makes the film or series' original language the
default audio track of MKV files that have more than one, so a dual audio
release never starts dubbed. Anime is the exception: a Portuguese track wins
when there is one. It edits a copy and swaps it in, since the library file is
a hardlink of the torrent still seeding; until that torrent is deleted, the
file takes its space twice.

`media-cleanup` removes films and episodes everyone finished watching 14 days
ago (`MEDIA_CLEANUP_DAYS` in the unit) through Radarr and Sonarr, unmonitoring
the episodes so they are not fetched again. A torrent those apps grabbed is
deleted once no library file links to it and it has seeded to ratio 1, for
30 days, or its swarm has 50 seeders or more (`MEDIA_SEED_RATIO`,
`MEDIA_SEED_DAYS`, `MEDIA_SEED_SWARM`). `DRY_RUN=1 media-cleanup`
lists what it would remove; `tests/media_cleanup.sh` covers the rules.

Deleting a film or episode in Jellyfin deletes its library file. Radarr and
Sonarr unmonitor what lost its file and remove empty folders, so it is not
fetched again; the torrent keeps seeding and leaves through the rule above.

`media-backup` copies the databases (`sqlite3 .backup`, safe while the
services run), the rest of each service's settings, `media.env` and
qBittorrent's config and torrent state into one `media-YYYY-MM-DD.tar.zst` on
Google Drive (`Raphael:Backups/media`, through syncfast's rclone config) and
deletes archives older than 30 days. To restore on a fresh install: deploy,
stop the units, `rclone copy` the archive down, unpack it, put each
`.db`/`.sqlite3` back under `~/.local/share/media/<service>`, untar
`files.tar` there and `qbittorrent.tar` in `~`, copy `media.env` to
`~/.config/media/`, then start the units. `media-restore-test` (weekly)
downloads the newest archive, unpacks it and checks every database with
`PRAGMA integrity_check`, so a broken backup fails its unit.

`media-watchdog` restarts a service whose web page stopped answering for two
checks in a row (a crashed one is restarted by systemd itself), reopens
qBittorrent in the tray when it was closed, and runs `media-unstick` and
`media-torrents` (see qBittorrent). `media-unstick` imports a
finished download stuck waiting for a manual import when Radarr
or Sonarr grabbed it itself (its history names the film or series) and has no
objection to the files, so a release with an odd title no longer waits.

`media-dub-search` (weekly) asks Sonarr to search every anime episode whose
file has no Portuguese track; Sonarr only swaps the file when a dub turns up.

`media-letterboxd` (every 6 hours) requests in Seerr the films on the
Letterboxd list in `MEDIA_LETTERBOXD_LIST` (set in the unit, now
`prayplagues/list/jellyfin-library`; `<user>/watchlist` also works). Taking a
film off the list does not remove it.

`media/autostart` starts qBittorrent hidden at login.

Prowlarr searches 1337x, The Pirate Bay, YTS, EZTV, LimeTorrents, Knaben,
Nyaa and Anime Tosho (anime) and Torrentio, the same addon Stremio uses.
Torrentio has no
stock Prowlarr definition: `media/prowlarr/definitions/torrentio.yml` is
mounted as a custom one and only searches by IMDb id.

Bazarr looks for subtitles on OpenSubtitles, YIFY, Subf2m and Gestdown
(series only), and on the tracks inside the file.

Bazarr asks Whisper (whisper.cpp, `medium` model, on the GPU through Vulkan;
`media/whisper/asr-shim.py` keeps the API Bazarr speaks) only when no
subtitle site has the episode or film. Whisper writes the language spoken in
the audio or English, never a translation to Portuguese: a Japanese anime
without pt-BR subtitles on the sites gets English ones made by Whisper.

## Once, after the first deploy

1. Subtitles: create a free account at <https://www.opensubtitles.com>, put
   its username (not the email) in `media.env` (`OPENSUBTITLESCOM_USERNAME`,
   `OPENSUBTITLESCOM_PASSWORD`) and `dotter deploy` again.
2. Jellyfin, at <http://127.0.0.1:8096> (or Jellyfin Desktop): run the wizard, add the libraries
   `Movies` (`~/Media/Movies`), `Shows` (`~/Media/Series`) and `Anime`
   (`~/Media/Anime`, type Shows). In Dashboard → Playback → Transcoding pick VAAPI with
   `/dev/dri/renderD128`. In Dashboard → API Keys create a key and put it in
   `media.env` as `JELLYFIN_TOKEN` (`media-cleanup` reads watch history with
   it). Turn on "Automatically add to collection" in the Movies library. The
   rest of Jellyfin comes from `media/jellyfin` on the `dotter deploy` after
   step 3 (see below).
3. Seerr, at <http://127.0.0.1:5055>: sign in with the Jellyfin account
   (server `http://jellyfin:8096`, external URL `http://fedora.local:8096`),
   then `dotter deploy` again. The deploy sets the Application URL and adds
   Radarr and Sonarr from `media/seerr` (profiles and roots by name, keys from
   `media.env`), then applies the Jellyfin settings.
4. TV: on Samsung models from 2021 on, install Jellyfin from the app store.
   On 2018 to 2020 models, sideload it with Apps2Samsung. Point it at
   `http://fedora.local:8096` (or `http://192.168.1.211:8096`).

## Quality

Films use `4K (1080p fallback)`: 2160p WEB or Bluray encode first, 1080p when
there is none, no Remux, at most 120 MB per minute (about 14 GB for two hours).
Series use `1080p (4K when available)`: WEB 2160p above WEB 1080p; series and
anime have the same cap per minute of episode.
Dolby Vision without an HDR fallback is rejected, since the TV would show it
with wrong colors.

A 4K film download that ran 30 minutes and still expects more than 12 hours
(`MEDIA_SLOW_4K_HOURS`) is swapped by `media-torrents` for the best 1080p
release that is smaller than what is left and has more seeders (at least 5,
`MEDIA_MIN_SEEDS`); the 4K one is blocklisted and Radarr can still upgrade to
a faster 4K later. When no 1080p release is faster the 4K keeps going and is
not checked again (`~/.local/share/media/slow-4k-kept`); a slow 4K upgrade of
a film that already has a file is dropped.

Anime (Seerr sends a series there when TMDB tags it as anime) uses `Anime`,
the TRaSH anime profile: Bluray and WEB from the fansub and release groups
TRaSH ranks. On top of that, a release with a
Portuguese dub (`Dublado`, `PT-BR`, `Dual Audio PT`, or a Portuguese audio
track) scores 2000, so a dubbed version wins whenever one exists. A Netflix
`MULTi` release scores 1500: VARYG and ToonsHub put the pt-BR dub in it
without naming it (Tsundere-Raws' `MULTi` is French and does not count).

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

Five downloads run at once; a slow one does not hold a slot. Every new torrent
also gets the public trackers from
<https://ngosang.github.io/trackerslist/trackers_best.txt>, which finds more
peers and unsticks metadata.

Torrents in `Movies`, `Series` and `Anime` carry one tag, kept by
`media-torrents` from the watchdog: `library` (a library file is a hardlink of
it), `seeding-only` (it left the library and waits for the seeding rule) or
`stalled` (a download that moved nothing for 6 hours, `MEDIA_STALL_HOURS`).
A stalled download Radarr or Sonarr grabbed is removed and blocklisted
instead, and the app searches for another release. Games are left alone.

Radarr and Sonarr download into the qBittorrent categories `Movies`, `Series`
and `Anime` (`~/Media/Downloads/<category>`) and hardlink the finished file
into `~/Media/Movies`, `~/Media/Series` or `~/Media/Anime`, renamed. Series
tagged `anime` in Sonarr go through the `qBittorrent Anime` client (priority 1,
category `Anime`); Seerr adds that tag to anime requests. The untagged client
(priority 2) takes everything else. A torrent added by hand
with one of those categories is imported the same way when its film or series
is already in Radarr or Sonarr (request it in Seerr first); otherwise it waits
in that app's Activity queue for a manual import. After each import Radarr and
Sonarr ask Jellyfin to rescan (Connect > Jellyfin, using `JELLYFIN_TOKEN`), so
new files show up without waiting for the library's file watcher.

To add a category, add a `"Name": "~/path"` line to
`media/qbittorrent/categories.json` and `dotter deploy`. Subcategories use a
slash (`Games/Switch`).
