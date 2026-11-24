# Media stack

Pick a release in Stremio Enhanced by clicking a Torrentio row (its play
button is a download button now); Radarr or Sonarr takes that exact release, qBittorrent
downloads it, the file is hardlinked into `~/Media/Movies` or `~/Media/Series`,
Bazarr fetches pt-BR and English subtitles (never the hearing-impaired kind),
and the Samsung TV plays it in the Jellyfin app. Nothing is grabbed on its
own: no RSS sync, no automatic search, no upgrades.

The `media` module (only on `fedora`) runs the services as rootless Podman
quadlets on the `media` network. qBittorrent is the desktop app (Fedora RPM)
and Jellyfin Desktop (flatpak) plays on this PC. Design:
[`superpowers/specs/2026-11-21-media-stack-design.md`](superpowers/specs/2026-11-21-media-stack-design.md).

## What runs

| Service | Address | Reachable from |
|---|---|---|
| Jellyfin | <http://fedora.local:8096> | LAN |
| qBittorrent WebUI (used by Radarr and Sonarr) | `host.containers.internal:8080` | containers, password in `media.env` |
| Radarr | <http://fedora.local:7878> | LAN (the Stremio plugin on both PCs), no login |
| Sonarr | <http://fedora.local:8990> | LAN (the Stremio plugin on both PCs), no login; 8989 is Spotifast's login redirect |
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

- links every file in `media/bin`, `media/systemd` and `media/autostart` and
  the `media/containers`, `media/configarr`,
  `media/prowlarr/definitions` and `media/whisper` directories, and removes
  links whose file left the repo, so a new script or timer works without
  `dotter deploy` (which needs sudo): `media-deploy ~/.dotfiles` is enough;
- fills empty `*APIKEY` and `*WEBUI_PASSWORD` values in `media.env`, adding
  keys that are new in `media.env.example`;
- starts the units, restarting the ones whose quadlet changed, and stops a
  container or `media-*` unit whose file left the repo;
- seeds `~/.config/qBittorrent/qBittorrent.conf` when it does not exist
  (WebUI on, starts hidden in the tray, monochrome tray icon, Breeze style
  with system icons, no status bar, no "torrent added" notification), starts
  qBittorrent if needed and applies `media/qbittorrent/preferences.json`
  (`.torrent` copies to `~/Personal/Torrents`, category paths also in manual
  mode) and `categories.json` (categories not in the file are removed);
- renders Bazarr's config from `media/bazarr/config.yaml.tmpl` (subtitle
  timing fixed with subsync when the match score is low, Whisper as the last
  provider) and applies the pt-BR and English language profile;
- turns RSS sync off in Radarr and Sonarr and moves every film, series and
  Radarr collection to the `Manual` profile;
- runs Configarr (`media/configarr/config.yml`): the `Manual` profile (every
  quality, no upgrades, no custom formats; any other profile or custom format
  is deleted), naming, root folders, the qBittorrent client, Prowlarr indexers
  and apps;
- once `JELLYFIN_TOKEN` is set, applies `media/jellyfin` to Jellyfin: plugin
  repositories and plugins (Intro Skipper, Jellyfin Enhanced and its
  dependencies), the custom CSS on top of the default theme, the Jellyfin
  Enhanced settings that differ from its defaults (`enhanced.json`) with the
  Radarr and Sonarr keys filled in, every user's home sections and
  subtitle preferences (pt-BR, Always), and the Shows library cover when it
  has none. Backdrops in Jellyfin Desktop and on the phone are a per-device
  setting (Settings → Display → Backdrops);
- makes qBittorrent the magnet link handler and installs Jellyfin Desktop;
- enables every `media-*.timer` in `media/systemd` and
  `podman-auto-update.timer`: `media-original-audio` (every 15 minutes),
  `media-watchdog` (every 5 minutes), `media-cleanup`, `media-backup` and
  `media-drift` (daily), and `media-restore-test` (weekly).

`media-deploy ~/.dotfiles --check` changes nothing, prints one
`media: differs:` line for each link, timer, unit, qBittorrent, Bazarr, Radarr
or Jellyfin setting that is not what the repo says, and exits 1 when there is
any (Configarr is left out: its timer re-applies Radarr, Sonarr and Prowlarr
every hour). It also prints a `media: unhealthy:` line for each problem a
service reports (a Radarr, Sonarr or Prowlarr health warning, a paused Bazarr
subtitle site, qBittorrent offline, a failed unit) and exits 1 for those too.
`media-drift` runs it daily, so either lands in the media log.

The media log, `~/.local/state/media/media.log`, is one timeline of what the
stack did and what broke: every change a script or the deploy made (a torrent
dropped or deleted, a film removed, a backup uploaded, a setting applied, a
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
agents to use it: `search` and `add` (through Radarr and Sonarr, with the same
rules as the Stremio plugin and no search), `info` (file, quality, audio and
subtitles), `subs` (missing subtitles), `watched` (what each Jellyfin user
played last), `delete` (unmonitor, then delete the file), `queue`, `log` and
`status` (disk, torrent tags, downloads, health problems and the runs that
failed in the last 7 days). It and the other scripts share
`media/bin/media-lib.sh` (`api <app> <method> <path>`, `qbt`, `env_get`,
`health`, `log`, `notify`).

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

## Picking a release in Stremio

The `hyprland` module installs Stremio Enhanced (the latest AppImage, unpacked
in `~/.local/opt/stremio-enhanced`, started by `stremio-enhanced`) on both PCs
and links `media/stremio/manual-pick.plugin.js` into its plugins folder.

Torrentio rows of a film or episode stop playing: the play icon becomes a
download icon, and clicking the row, or "Baixar no PC" (the old "Play") in its
right-click menu, adds the title to Radarr or Sonarr if it is not there
(`Manual` profile, no search; anime by genre goes to `~/Media/Anime` with the
`anime` tag), monitors that film or the episodes the release covers (a whole
season for a season pack), and pushes that release. The row then shows
"Baixando" with the percentage from Radarr's or Sonarr's queue (refreshed every
5 seconds, still there after reopening the title), or the reason it failed
("servidor fora de alcance", "o servidor demorou demais", "perfil Manual não
existe no Radarr", or the app's rejection). Errors also go to Stremio
Enhanced's log, tagged `manual-pick`.

A downloading row shows an X: clicking it, or "Cancelar download" in its menu,
asks for confirmation and removes the download from the queue and qBittorrent
(no blocklist). If the title is left with no file and nothing downloading, it
leaves Radarr or Sonarr too. The release whose file is in the library shows
"No PC" with a check, and clicking it does nothing.

Once per PC: open Stremio Enhanced, sign in, install Torrentio, enable
`manual-pick` in Settings > Plugins and fill its settings: server
`http://fedora.local`, and the Radarr and Sonarr API keys from `media.env`
(`RADARR__AUTH__APIKEY`, `SONARR__AUTH__APIKEY`).

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
   rest of Jellyfin comes from `media/jellyfin` on the next `dotter deploy`.
3. Stremio Enhanced on each PC: see "Picking a release in Stremio".
4. TV (Samsung QN55Q80A, `192.168.1.78`): the store app doesn't show up on
   this set, so it is sideloaded. Turn on Developer Mode (Apps, then `12345`
   from the SmartThings remote) with host IP `192.168.1.250`, restart the TV
   and run `podman run --rm ghcr.io/georift/install-jellyfin-tizen 192.168.1.78`.
   The sideloaded app never updates itself; run the same command again for a
   new version. Server address: `http://192.168.1.250:8096` (the TV can't
   resolve `.local` names).

## Quality

Radarr and Sonarr have one profile, `Manual`: every quality allowed, no
upgrades, no custom format scores. What gets downloaded is exactly what was
picked in Stremio, so the size, codec and audio choices are made there. The
2.4 GHz Wi-Fi to the TV carries about 27 Mbit/s on average, roughly a 24 GB
two hour 4K film.

Embedded image subtitles (PGS, VobSub) don't satisfy Bazarr: the Samsung app
can't draw them, so Jellyfin would burn them in and re-encode the film to SDR
H.264, which looks visibly worse. Bazarr downloads a text subtitle instead,
and with that the TV plays the file untouched.

A 4K film download that ran 30 minutes and still expects more than 12 hours
(`MEDIA_SLOW_4K_HOURS`) is dropped by `media-torrents`: it leaves the Radarr
queue and qBittorrent, nothing is blocklisted or searched, and a notification
(also in the media log) asks for another release in Stremio.

Dolby Vision without an HDR fallback shows wrong colors on the TV, and a dub
is rarely named in the release title: check those in the Torrentio row before
picking, and `mediactl audio` after the download. The `Manual` profile does
not upgrade, so to swap a file for another release, delete it first (in
Jellyfin or with `mediactl delete`) and then pick again.

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
A stalled download Radarr or Sonarr grabbed is dropped instead, the same way
as a slow 4K one, with a notification. Games are left alone.

Radarr and Sonarr download into the qBittorrent categories `Movies`, `Series`
and `Anime` (`~/Media/Downloads/<category>`) and hardlink the finished file
into `~/Media/Movies`, `~/Media/Series` or `~/Media/Anime`, renamed. Series
tagged `anime` in Sonarr go through the `qBittorrent Anime` client (priority 1,
category `Anime`); the Stremio plugin and `mediactl add` tag anime. The untagged client
(priority 2) takes everything else. A torrent added by hand
with one of those categories is imported the same way when its film or series
is already in Radarr or Sonarr (`mediactl add` it first); otherwise it waits
in that app's Activity queue for a manual import. After each import Radarr and
Sonarr ask Jellyfin to rescan (Connect > Jellyfin, using `JELLYFIN_TOKEN`), so
new files show up without waiting for the library's file watcher.

To add a category, add a `"Name": "~/path"` line to
`media/qbittorrent/categories.json` and `dotter deploy`. Subcategories use a
slash (`Games/Switch`).
