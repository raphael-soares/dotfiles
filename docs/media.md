# Media stack

Pick a release in Stremio Enhanced with the download button on a Torrentio
row (the Arr Pick plugin); Radarr or Sonarr takes that exact release, qBittorrent
downloads it, the file is hardlinked into `~/Media/Movies` or `~/Media/Shows`,
Bazarr fetches pt-BR and English subtitles (never the hearing-impaired kind),
and the Samsung TV plays it in the Jellyfin app. Nothing is grabbed on its
own: no RSS sync, no automatic search, no upgrades.

The `media` module (only on `fedora`) runs the services as Docker containers
from `media/compose.yaml` on the `media` network. qBittorrent is the desktop app (Fedora RPM)
and Jellyfin Desktop (flatpak) plays on this PC. Design:
[`superpowers/specs/2026-11-21-media-stack-design.md`](superpowers/specs/2026-11-21-media-stack-design.md).

## What runs

| Service | Address | Reachable from |
|---|---|---|
| Jellyfin | <http://fedora.local:8096> | LAN |
| qBittorrent WebUI (used by Radarr and Sonarr) | `host.docker.internal:8080` | containers, password in `media.env` |
| Radarr | <http://fedora.local:7878> | LAN (the browser on the laptop), no login |
| Sonarr | <http://fedora.local:8990> | LAN (the browser on the laptop), no login; 8989 is Spotifast's login redirect |
| Prowlarr | <http://127.0.0.1:9696> | this PC |
| Bazarr | <http://127.0.0.1:6767> | this PC |
| FlareSolverr | `flaresolverr:8191` | containers only |
| Whisper (speech to text for Bazarr) | <http://127.0.0.1:9000> | this PC |

qBittorrent listens for peers on 9386 (TCP and UDP). The router has no UPnP
gateway, so incoming peers only reach it if 9386 is forwarded by hand on the
router.

Inside the network, services reach each other by container name
(`http://radarr:7878`). `media-update.timer` pulls new images daily and
recreates the containers they changed (there is no rollback: a bad image is
logged and replaced by the next update); `configarr.timer` reapplies the YAML
daily.

`media-compose` is `docker compose` on this stack (`media-compose ps`,
`media-compose logs -f radarr`, `media-compose restart jellyfin`). It needs
the user in the `docker` group, which `missing.sh media` asks for.

## Where things live

| What | Path |
|---|---|
| Compose file | `media/compose.yaml` → `~/.config/media/compose.yaml` |
| Secrets (API keys, OpenSubtitles login) | `~/.config/media/media.env`, mode 600, decrypted from `secrets/media.env` by `media-deploy`, which also generates the missing keys |
| App state and databases | `~/.local/share/media/<service>` |
| Caches (Jellyfin transcodes, TRaSH repos) | `~/.cache/media` |
| Downloads | `~/Media/Downloads/{Movies,Shows}` |
| Library | `~/Media/Movies`, `~/Media/Shows` (series and anime) |
| `.torrent` copies | `~/Drive/Personal/Torrents` |

`dotter deploy` runs `media/bin/media-deploy`, which:

- links every file in `media/bin`, `media/systemd` and `media/autostart`,
  `media/compose.yaml` and the `media/configarr`,
  `media/prowlarr/definitions` and `media/whisper` directories, and removes
  links whose file left the repo, so a new script or timer works without a
  full `dotter deploy`: `media-deploy ~/.dotfiles` is enough;
- fills empty `*APIKEY` and `*WEBUI_PASSWORD` values in `media.env`, adding
  keys that are new in `media.env.example`;
- stops early if `docker` does not work for the user, then brings the stack
  up with `media-compose up -d --remove-orphans` (compose recreates a
  container whose definition changed), restarts `whisper` when
  `asr-shim.py` changed, and stops a `media-*` unit whose file left the repo;
- seeds `~/.config/qBittorrent/qBittorrent.conf` when it does not exist
  (WebUI on, starts hidden in the tray, monochrome tray icon, Breeze style
  with system icons, no status bar, no "torrent added" notification), starts
  qBittorrent if needed and applies `media/qbittorrent/preferences.json`
  (`.torrent` copies to `~/Drive/Personal/Torrents`, category paths also in manual
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
- makes qBittorrent the magnet link handler;
- enables every `media-*.timer` in `media/systemd`: `media-original-audio`
  (every 15 minutes), `media-watchdog` (every 5 minutes), `media-update`,
  `media-cleanup` and `media-drift` (daily).

`media-deploy ~/.dotfiles --check` changes nothing, prints one
`media: differs:` line for each link, timer, container (stopped, or running an
older `compose.yaml`), qBittorrent, Bazarr, Radarr
or Jellyfin setting that is not what the repo says, and exits 1 when there is
any (Configarr is left out: its timer re-applies Radarr, Sonarr and Prowlarr
every day). It also prints a `media: unhealthy:` line for each problem a
service reports (a Radarr, Sonarr or Prowlarr health warning, a paused Bazarr
subtitle site, qBittorrent offline, a stopped container or a failed unit) and exits 1 for those too.
`media-drift` runs it daily, so either lands in the media log.

The media log, `~/.local/state/media/media.log`, is one timeline of what the
stack did and what broke: every change a script or the deploy made (a torrent
dropped or deleted, a film removed, a setting applied, a
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
agents to use it: `search` and `add` (through Radarr and Sonarr, with the
same profile and folders as the Stremio plugin and no search), `info` (file, quality, audio and
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

`media-watchdog` restarts a service whose web page stopped answering for two
checks in a row (a crashed one is restarted by Docker's restart policy), reopens
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

Stremio is only on this PC: the `media` module carries it, so the laptop never
gets it. `missing.sh media` prints how to install Stremio Enhanced
(`media/install/stremio-enhanced` unpacks the latest AppImage in
`~/.local/opt/stremio-enhanced`, started by `stremio-enhanced`) and Arr Pick
(<https://github.com/raphael-soares/stremio-arr-pick>, a private repo) into
its plugins folder, with `gh release download`. Run the same commands to update
either one. How the plugin behaves is in its README.

Each torrent row keeps playing and gets a round download button next to the
play button, and its right-click menu a "Baixar" item. Arr Pick adds the title
to Radarr or Sonarr if it is not there, with no search. Here each app has one
profile (`Manual`, which allows every quality and never upgrades) and one root
folder, so films go to `~/Media/Movies` and every show, anime included, to
`~/Media/Shows`. The button then shows a ring with the download's progress
(click to stop and delete it) and a check once that release is in the library.
Errors show on hover and go to Stremio Enhanced's log, tagged `arr-pick`.

Once: open Stremio Enhanced, sign in, install Torrentio, enable Arr
Pick in Settings > Plugins and fill its four settings: Radarr URL
`http://127.0.0.1:7878`, Sonarr URL `http://127.0.0.1:8990`, and the API
keys from `media.env` (`RADARR__AUTH__APIKEY`, `SONARR__AUTH__APIKEY`).

## Once, after the first deploy

1. Subtitles: create a free account at <https://www.opensubtitles.com>, put
   its username (not the email) in `media.env` (`OPENSUBTITLESCOM_USERNAME`,
   `OPENSUBTITLESCOM_PASSWORD`) and `dotter deploy` again.
2. Jellyfin, at <http://127.0.0.1:8096> (or Jellyfin Desktop): run the wizard, add the libraries
   `Movies` (`~/Media/Movies`) and `Shows` (`~/Media/Shows`, series and anime
   together). In Dashboard → Playback → Transcoding pick VAAPI with
   `/dev/dri/renderD128`. In Dashboard → API Keys create a key and put it in
   `media.env` as `JELLYFIN_TOKEN` (`media-cleanup` reads watch history with
   it). Turn on "Automatically add to collection" in the Movies library. The
   rest of Jellyfin comes from `media/jellyfin` on the next `dotter deploy`.
3. Stremio Enhanced on each PC: see "Picking a release in Stremio".
4. TV (Samsung QN55Q80A, `192.168.1.78`): the store app doesn't show up on
   this set, so it is sideloaded. Turn on Developer Mode (Apps, then `12345`
   from the SmartThings remote) with host IP `192.168.1.250`, restart the TV
   and run `docker run --rm ghcr.io/georift/install-jellyfin-tizen 192.168.1.78`.
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
`host.docker.internal:8080` with user `media` and the password in
`media.env`. The WebUI listens on every interface (containers reach the host
through Docker's bridge gateway), so the password is what keeps the LAN out.
Closing the window keeps it in the tray.

Five downloads run at once; a slow one does not hold a slot. Every new torrent
also gets the public trackers from
<https://ngosang.github.io/trackerslist/trackers_best.txt>, which finds more
peers and unsticks metadata.

Torrents in `Movies` and `Shows` carry one tag, kept by
`media-torrents` from the watchdog: `library` (a library file is a hardlink of
it), `seeding-only` (it left the library and waits for the seeding rule) or
`stalled` (a download that moved nothing for 6 hours, `MEDIA_STALL_HOURS`).
A stalled download Radarr or Sonarr grabbed is dropped instead, the same way
as a slow 4K one, with a notification. Games are left alone.

Radarr and Sonarr download into the qBittorrent categories `Movies` and
`Shows` (`~/Media/Downloads/<category>`) and hardlink the finished file into
`~/Media/Movies` or `~/Media/Shows`, renamed. Series and anime share `Shows`:
Sonarr has one root folder and one qBittorrent client, and only types anime
series as anime so absolute episode numbers parse. A torrent added by hand
with one of those categories is imported the same way when its film or series
is already in Radarr or Sonarr (`mediactl add` it first); otherwise it waits
in that app's Activity queue for a manual import. After each import Radarr and
Sonarr ask Jellyfin to rescan (Connect > Jellyfin, using `JELLYFIN_TOKEN`), so
new files show up without waiting for the library's file watcher.

To add a category, add a `"Name": "~/path"` line to
`media/qbittorrent/categories.json` and `dotter deploy`. Subcategories use a
slash (`Games/Switch`).
