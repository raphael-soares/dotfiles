# Pick the release by hand, from Stremio

Superseded by `2026-11-24-arr-pick-design.md`: the plugin moved to its own repo, and series and anime share one Shows folder.

## Why

Today a film is requested in Seerr and Radarr picks the release. The owner does
not want that layer. He used to open the film in Stremio, look at the list of
releases (seeds, size, quality), copy the magnet of the one he chose and add it
to qBittorrent. He wants that again, while keeping what the stack does after
the download: the name Jellyfin understands, Bazarr subtitles in pt-BR and
English, original audio only, the 14-day cleanup after watching, and the TV
playing it in Jellyfin.

## Goals

- In Stremio, every Torrentio release of a film or episode has a "Baixar no PC"
  button. One click starts that exact release on fedora.
- From there the download follows today's path: Radarr or Sonarr imports it,
  Jellyfin shows it, Bazarr gets subtitles, the cleanup removes it after
  watching.
- Works from both machines on the home network.

## Non-goals

- Nothing downloads on its own anymore, films or episodes: no request app, no
  Letterboxd monitor, no search on add, no RSS grabs, no quality upgrades.
- No new library app or player. Jellyfin stays the player on the TV; Stremio
  is only where the choice is made.
- Moving the stack from Podman to Docker is a separate project, after this one.

## Anti-goals

- A button that puts the file in the library under the torrent's name, so
  Jellyfin misnames it and Bazarr never sees it. Sending the magnet straight to
  qBittorrent without Radarr or Sonarr knowing the title is exactly that.
- A plugin that breaks on every Stremio update because it scrapes the page for
  data it could get from an API.

## Approaches

- **Radarr and Sonarr's own Interactive Search** as the picking screen, with
  automation off. Uses only what runs today, but it is the technical Radarr
  page and takes two steps (add, then search).
- **Search Prowlarr and send to qBittorrent**, no Radarr. Closest to the old
  habit, but loses naming and subtitles (the anti-goal).
- **Our own Stremio-like web app** on top of Radarr and Sonarr. Best fit, but
  a poster grid and detail page to build and maintain.
- **Chosen by the owner: a plugin for Stremio Enhanced.** Stremio already is
  the poster grid and the release list the owner likes; the plugin only adds
  the button and talks to Radarr and Sonarr. It is the third approach without
  building the UI.

## Verified before writing

- Radarr answers cross-origin requests (`Access-Control-Allow-Origin: *`,
  preflight allows `x-api-key`), so a script inside Stremio Enhanced can call it.
- Radarr already imports a finished download in its qBittorrent category that it
  did not grab, when the film exists in Radarr (`docs/media.md`, qBittorrent).
- Stremio Enhanced (REVENGE977/stremio-enhanced) ships a Linux AppImage, v1.2.1
  of 2026-11-17. Plugins are `.plugin.js` files injected into the page, with
  DOM access and a settings API (`StremioEnhancedAPI.registerSettings`,
  `getSetting`), no Node access.

## Design

### The click

1. The plugin knows the open title's IMDb id (and season and episode) and the
   release's info hash and name, from the Torrentio response for that title
   (the plugin calls Torrentio itself with the URL of the Torrentio addon the
   user installed, so filters and order match the list on screen).
2. Film: look the film up in Radarr by IMDb id; if missing, add it with the
   root folder and quality profile the stack uses, `searchForMovie: false`.
   The film is monitored (my call): with RSS, upgrades and every searching
   script off, monitoring grabs nothing, and `media-cleanup` and
   `media-unstick` keep treating it like today.
3. Series: same in Sonarr, no search; only the picked episodes (or the season
   of a pack) end up monitored. Series lookup by IMDb id; if Sonarr cannot
   resolve it, the plugin says so instead of guessing (my call). Anime (my
   call: Sonarr's lookup lists the `Anime` genre) goes to `~/Media/Anime` with
   the anime series type and the `anime` tag, as Seerr did
   (`media/seerr/sonarr.json`). Every title uses the single `Manual` profile.
4. Hand the release to Radarr or Sonarr so it sends it to qBittorrent in its own
   category and records it as its grab in history. The preferred route is the
   release push API (`POST /api/v3/release/push` with the magnet). The plan
   starts with a spike that proves three things: a low-ranked release is still
   accepted, the grab shows up in history, and a pack imports into a series.
   The owner already chose the release, so the profile must not overrule him:
   if push rejects on score, the spike finds the narrowest setting that lets it
   through without changing how configarr ranks. A name that does not parse to
   the title is shown as Radarr's or Sonarr's error, never forced (my call).
   Sending the bare magnet to qBittorrent is not a fallback (anti-goal).
5. Torrentio rows and the "Play" item of their right-click menu become the
   download action (download icon, "Baixar no PC"); the row then shows
   "Baixando", or the error from Radarr or Sonarr in plain words ("servidor
   fora de alcance" when fedora does not answer).

### Nothing swaps a release on its own

The owner's answer: a stalled or too-slow download is removed and he is told;
he picks another release in Stremio.

- `media-torrents` keeps detecting stalls and slow 4K, but removes the download
  instead of blocklisting and searching again, and tells the owner which title
  needs a new pick (desktop notification on fedora plus the log, my call).
- `media-dub-search` and its timer go away.
- `mediactl` loses `research` and `grab`; agents search, add and report.

### What goes away

- Seerr: container, desktop entry, the Seerr part of `media-deploy`,
  `media-lib.sh` and `media-watchdog`, `media/seerr/`, the Jellyfin Enhanced
  Seerr integration (`media/jellyfin/enhanced.json`).
- `media-letterboxd` and its timer.
- Automatic grabbing in Radarr and Sonarr: RSS sync off, upgrades off, no search
  on add. Prowlarr stays (Bazarr and manual searches in Radarr still use it), as
  do configarr, Bazarr, whisper, cleanup and the other scripts.
- `mediactl` keeps search and add for agents, against Radarr and Sonarr
  directly, with the same "add, do not search" rule.
- The Stremio flatpak (`com.stremio.Stremio`, `home/flatpaks.txt`) is replaced
  by Stremio Enhanced on both machines. Stremio keeps addons and library in the
  account, so signing in brings them back.

### Reach

Radarr and Sonarr listen only on 127.0.0.1 today. To be reached from arch they
publish on the LAN like Jellyfin (`0.0.0.0`); the API needs the keys, and the
web UI has no login on the LAN (the owner's choice). The
stack is LAN-only by design and the deploy opens their ports in firewalld if it
is active (my call). The plugin keeps the fedora address and both keys in its
settings, entered once per machine; keys never go into the repo.

### Install

- Stremio Enhanced is not on Flathub: the deploy installs the AppImage on both
  machines and updates it when a newer release exists, with a desktop entry. It
  must run on Arch and Fedora alike (FUSE or extraction is the builder's call).
- The plugin lives in this repo and is linked into Stremio Enhanced's plugins
  folder by dotter on both machines (copied instead, if the app does not follow
  links).

## Left to the builder

- Where the plugin finds the Torrentio addon URL and the open title (Stremio's
  stored addons, the route, or the page), as long as the release data comes
  from Torrentio's API and not from parsing the list.
- How the button attaches to each release row; keep the page contact to that.
- Which module carries Stremio Enhanced and the plugin (both machines need them).
- Tests: the plugin's mapping from a Torrentio stream to the Radarr or Sonarr
  calls, and the deploy checks in `tests/machines.sh`.
- Docs: rewrite the top of `docs/media.md` for the new flow.
