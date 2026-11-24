# Arr Pick: the Stremio plugin as its own project

## Intent

`media/stremio/manual-pick.plugin.js` works only for the owner's setup. The
owner wants a plugin anyone with Radarr and Sonarr can use, kept in its own
private repository until it is mature enough to open. His own setup becomes
one configuration of it.

What it does stays the same: in Stremio Enhanced, clicking a torrent stream
row (or its right-click menu item) adds the title to Radarr or Sonarr without
searching and hands that exact release over; the row shows progress, an X
cancels, and the release whose file is in the library is marked.

## Goals

- Nothing in the plugin names the owner's machine, paths, profile, tag or
  language.
- Works with any Radarr v5 and Sonarr v4 reachable from the PC running
  Stremio Enhanced, with sensible defaults for a fresh install.
- Works with any addon whose streams carry a torrent info hash.
- English and Portuguese.
- Its own repository with tests in CI and versioned releases.
- The dotfiles install it from that repository's latest release.

## Non-goals

- Submitting it to the Stremio Enhanced registry (the owner chose a repository
  only; maybe later, once public).
- Forcing a release the profile rejects. Radarr's and Sonarr's push only grabs
  what the profile accepts; the plugin explains the rejection.
- Interactive search as a fallback (minutes per season; ruled out before).
- Servers behind an auth proxy that blocks API-key requests or CORS.
- Changing `mediactl`: it keeps the owner's rules (Manual profile, Anime
  folder, anime tag) in bash.

## Anti-goals

- A plugin that only works after reading the owner's docs.
- Silent fallbacks that pick another profile, folder or release.
- Changing or removing what the user already had in Radarr or Sonarr.
- Keys or addresses in the repository.

## Constraints

- Stremio Enhanced plugins are one `.plugin.js` file with a metadata block,
  run inside the page with a scoped `StremioEnhancedAPI`
  (`registerSettings`, `getSetting`, `saveSetting`, `onSettingsSaved`,
  `showAlert`, `logger`). Settings are `input`, `select` (fixed options) and
  `toggle`.
- `@updateUrl` must be a public raw URL. While the repository is private it is
  `none`; when it opens it points at the file on the default branch.
- The dotfiles deploy runs on both PCs. `gh` on fedora is logged in as
  `raphael-soares`; on arch as `soaresphael`, which will not get access (the
  owner's call), so arch skips the plugin with a message until that changes.
- Requests to plain `http://` LAN addresses work from Stremio Enhanced
  (verified on the owner's setup with `http://127.0.0.1` and
  `http://fedora.local`); Radarr and Sonarr answer CORS with `*`.

## Approaches

1. **Settings with defaults** (chosen). The settings panel holds the two URLs,
   two keys, one profile per app, root folders and optional anime folder and
   tag. Defaults work on a fresh Radarr or Sonarr; a wrong name fails with the
   list of valid ones.
2. Discover profiles and folders and ask on first use. The settings panel only
   takes fixed options, so this needs a custom screen. More code for a
   one-time step.
3. Fall back to interactive search when the profile rejects. Minutes for a
   season pack; already ruled out.

## Design

### Repository

`raphael-soares/stremio-arr-pick`, private, MIT license (my call: ready for
opening without a relicense). Contents: `arr-pick.plugin.js`, `test/` (the
current Node tests, moved and extended), a GitHub Actions workflow running
`node --test`, `README.md` in English (what it does, install, settings, the
profile limitation, compatible addons), `CHANGELOG.md`. A release is a tag
`vX.Y.Z` with the plugin file attached; `@version` matches the tag. Local
clone at `~/Code/Personal/stremio-arr-pick`.

### Settings

| Key | Label (en) | Default | Meaning |
|---|---|---|---|
| `radarr_url` | Radarr URL | empty | Full base URL, e.g. `http://192.168.1.10:7878` or `https://host/radarr`. Empty disables films. |
| `radarr_key` | Radarr API key | empty | |
| `sonarr_url` | Sonarr URL | empty | Same for series. |
| `sonarr_key` | Sonarr API key | empty | |
| `radarr_profile` | Radarr quality profile | `Any` | Used only when the plugin adds a film. |
| `sonarr_profile` | Sonarr quality profile | `Any` | Used only when the plugin adds a series. |
| `movie_root` | Movie root folder | empty | Empty: Radarr's first root folder. |
| `series_root` | Series root folder | empty | Empty: Sonarr's first root folder. |
| `anime_root` | Anime root folder | empty | Empty: the series root folder. |
| `anime_tag` | Anime tag | empty | Empty: no tag. A name that does not exist is an error, never created. |
| `language` | Language | Automatic | Automatic, English, Português. |

- Profile and tag names match case-insensitively (my call: names differ in
  spacing and case between installs, which is also why each app has its own
  profile setting).
- Settings are read on every click and every refresh, so a change applies
  without a reload. A trailing slash in a URL is ignored.
- Rows of a type whose URL is empty stay untouched (they keep playing), so
  someone with only Radarr keeps series streaming.
- A URL with an empty key counts as configured, and the click says the key is
  missing (my call: silence would hide a half-done setup).
- Errors name what is wrong and what exists: "profile Manual not found in
  Sonarr; available: Any, HD-1080p", "root folder /x not found in Radarr;
  available: /movies".

### Respecting what the user already has (my calls)

- A title already in Radarr or Sonarr keeps its own profile; the click only
  sets it monitored (and the episodes the release covers). If that profile
  rejects the release, the error says which profile refused it. Today's code
  moved the title to the configured profile, which on a generic install would
  silently change the user's choice.
- The plugin remembers which titles it added (app and id, kept with
  `saveSetting` on a hidden key). Only those are removed: after a cancel that
  leaves them with no file and nothing queued, and right away when the push
  for the click that added them is rejected. A title the user had before is
  never removed.

Anime detection stays as today: Sonarr's lookup lists the `Anime` genre; the
series type becomes `anime` regardless of the folder and tag settings.

### Streams

Any addon's `Ready` streams with an `infoHash` and a player deep link are
handled, not only Torrentio's. The release name sent to Radarr or Sonarr is
the first line of the stream's `description` (or `title` when there is no
description), which is the torrent name for Torrentio. Other addons format
this differently; the builder checks MediaFusion and Comet against a real
title and documents in the README which addons give names Radarr parses. A
name that does not parse shows Radarr's message.

### Language

English and Portuguese strings in one table. On Automatic, the language comes
from Stremio's interface language in the core state when it is Portuguese,
else the browser language, else English. Status texts: "Sending…",
"Downloading N%", "Importing", "Cancelling…", "In library"; menu: "Download",
"Cancel download", "Already in library"; and their Portuguese forms ("Na
biblioteca" replaces "No PC").

### Behavior kept from today

Progress from the queue matched by info hash every 5 seconds while the page is
visible; cancel with the native confirmation, removing from queue and client
without blocklist; the library marker from the latest import in history; the
30 s request timeout; DOM writes only on change; React-owned nodes hidden, ours
beside them; errors to the Stremio Enhanced logger.

### Dotfiles

- Remove `media/stremio/manual-pick.plugin.js`, `tests/stremio_plugin.test.mjs`,
  its CI step, its `global.toml` entry and the `machines.sh` link assertion.
- `post_deploy.sh`, in the Stremio Enhanced block: download the latest release
  asset with `gh release download -R raphael-soares/stremio-arr-pick` into
  `~/.config/stremio-enhanced/plugins/arr-pick.plugin.js` when the tag changed
  (state file like the Stremio Enhanced one); if `gh` cannot reach the
  repository, print one line and go on.
- `docs/media.md` and the `midia` skill: the plugin lives in its own
  repository; the owner's settings (URLs `http://fedora.local:7878` and
  `http://fedora.local:8990`, profile `Manual` in both, anime folder
  `/home/raphael/Media/Anime`, tag `anime`) are listed once, entered per PC.
  `mediactl`'s comment points at the new repository.

## Left to the builder

- Where Stremio Web keeps the interface language in the core state.
- Exact README wording and the addon compatibility notes.
- Whether tests reach the pure functions through `module.exports` only.
