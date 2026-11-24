# Arr Pick: the Stremio plugin as its own project

## Intent

`media/stremio/manual-pick.plugin.js` was built around the owner's own flow:
clicking a row downloads instead of playing, a profile called Manual, an Anime
folder and tag, Portuguese text in the rows. The owner wants a plugin anyone
with Radarr and Sonarr can use without learning his flow, simple in the way
Apple's App Store download button is simple: one control that explains itself
and almost nothing to configure. It lives in its own private repository until
it is mature enough to open.

## Goals

- Stremio behaves as before: a stream row still plays.
- One download control per torrent row, plus a menu item, with three looks:
  download arrow, progress ring with a stop square, check mark.
- Settings are only the Radarr and Sonarr address and API key.
- Everything else is decided from what Radarr and Sonarr already know.
- Works with any addon whose streams carry a torrent info hash.
- Text follows Stremio's interface language (English and Portuguese).
- Its own repository with tests in CI and versioned releases; the dotfiles
  install it from the latest release.

## Non-goals

- Submitting it to the Stremio Enhanced registry (maybe later, once public).
- Sending anime to a separate folder or tagging it. The plugin only sets the
  Sonarr series type to anime by genre, which Sonarr needs to read absolute
  episode numbers; it is not a category.
- Interactive search as a fallback (minutes per season; ruled out before).
- Servers behind an auth proxy that blocks API-key requests or CORS.
- Changing `mediactl`: it keeps the owner's rules in bash.

## Anti-goals

- Settings or text that only make sense in the owner's setup.
- Changing or removing what the user already had in Radarr or Sonarr.
- A downloaded title that Radarr or Sonarr later replaces on its own from an
  indexer because the plugin chose a profile that wants an upgrade.
- Popups for routine actions.

## Constraints

- Stremio Enhanced plugins are one `.plugin.js` file with a metadata block,
  run inside the page with a scoped `StremioEnhancedAPI` (`registerSettings`,
  `getSetting`, `saveSetting`, `showAlert`, `logger`). Settings are `input`,
  `select` and `toggle`. Unregistered keys can be saved and read back.
- Stremio's interface language is `core.getState("ctx").profile.settings.interfaceLanguage`
  (ISO 639-2, e.g. `eng`, `por`); checked on the test instance.
- Radarr's and Sonarr's `GET /api/v3/parse?title=` returns the release's
  quality (`parsedMovieInfo.quality.quality` / `parsedEpisodeInfo.quality.quality`);
  checked on fedora.
- `@updateUrl` must be a public raw URL: `none` while the repository is private.
- `gh` on fedora is logged in as `raphael-soares`; on arch as `soaresphael`,
  which gets no access (the owner's call), so arch skips the plugin with a
  message until that changes.
- Plain `http://` LAN addresses work from Stremio Enhanced; Radarr and Sonarr
  answer CORS with `*`.

## Approaches

1. **Automatic choices, four settings** (chosen). Profile, folder, series type
   and language come from Radarr, Sonarr and Stremio.
2. Settings with defaults for profile, folders, anime and language (the first
   version of this design). Works, but every field is a decision the user has
   to understand; the owner judged it still shaped by his flow.
3. Ask on first use. Needs a custom screen for a one-time step.

## Design

### Repository

`raphael-soares/stremio-arr-pick`, private, MIT license (my call). Contents:
`arr-pick.plugin.js`, `test/arr-pick.test.mjs`, a GitHub Actions workflow
running `node --test`, `README.md` in English, `CHANGELOG.md`. A release is a
tag `vX.Y.Z` with the plugin file attached; `@version` matches the tag. Local
clone at `~/Code/Personal/stremio-arr-pick`.

### Settings

`radarr_url`, `radarr_key`, `sonarr_url`, `sonarr_key`. A URL is a full base
URL (port, base path, HTTPS allowed; trailing slash ignored). A type whose URL
is empty gets no control, so someone with only Radarr sees nothing new on
series. A URL with an empty key shows the error state saying the key is
missing. Settings are read on every action and refresh.

### The control

- Rows keep playing. Each torrent row gets a round button at its right end;
  the row's right-click menu gets a "Download" item. Clicking the button never
  starts playback.
- Looks:
  - **download**: arrow in a circle. Click downloads.
  - **busy**: spinning ring while sending or stopping.
  - **progress**: ring filled to the download's percentage with a stop square;
    while importing, a full ring without the square. Click on the square stops
    without asking (App Store behavior) and deletes the partial download.
  - **done**: check mark; this release's file is in the library.
  - **error**: "!" in a circle; the tooltip says why; click retries.
- Tooltips carry the words ("Download", "Downloading 45%, click to stop",
  "Importing", "In library", the error). No text inside the row.

### Automatic choices

- **Existing title**: keeps its profile; the click only monitors it (and the
  episodes the release covers). If its profile rejects the release, the error
  names that profile.
- **New title, profile**: the release's quality comes from `/parse`. The
  plugin takes the first profile, by id, that allows that quality and will not
  upgrade past it (upgrades off, or the quality at or above the cutoff); if
  none, the first that allows it; if none, the error says no profile accepts
  that quality.
- **New title, folder**: the app's first root folder; none is an error.
- **Series type**: `anime` when Sonarr's lookup has the Anime genre, else
  standard. No tag.
- **Language**: Stremio's interface language, else the browser's, else English.

### Cleaning up after itself

The plugin remembers the titles it added (`saveSetting("added", JSON list of
"radarr:12")`). Such a title is removed, without files, when it is left with
no file and nothing queued: after a stop, and after a click whose push Radarr
or Sonarr answered with a rejection or error. After a network error or timeout
it is left alone, because the grab may still be going. A title the user had
before is never removed.

### Behavior kept

Release name from the stream's `description` first line, else `title`; magnet
from the info hash and trackers; series packs monitor the whole season;
progress polled every 5 s while the page is visible; queue records grouped by
info hash; library check from the latest import in history; 30 s request
timeout; DOM writes only on change; errors to the Stremio Enhanced logger.

### Dotfiles

- Remove `media/stremio/manual-pick.plugin.js`, `tests/stremio_plugin.test.mjs`,
  its CI step, its `global.toml` entry and the `machines.sh` link assertion.
- `post_deploy.sh`: download the latest release asset with
  `gh release download -R raphael-soares/stremio-arr-pick` into
  `~/.config/stremio-enhanced/plugins/arr-pick.plugin.js` when the tag changed;
  if `gh` cannot reach the repository, print one line and go on. Remove the
  old `manual-pick.plugin.*` files.
- `docs/media.md` and the `midia` skill: where the plugin lives, the four
  settings for the owner (`http://fedora.local:7878`, `http://fedora.local:8990`,
  keys from `media.env`). `mediactl`'s comment points at the repository.

### The owner's server: one Shows folder

The owner chose to drop his Series and Anime split in the same PR, so the
plugin's single-folder behavior matches his library:

- `~/Media/Series` and `~/Media/Anime` become `~/Media/Shows`; the qBittorrent
  categories `Series` and `Anime` become `Shows` (`~/Media/Downloads/Shows`).
- Sonarr has one root folder and one qBittorrent client (`tv_category: Shows`);
  the `qBittorrent Anime` client and the `anime` tag go away.
- `mediactl add` puts every show in `Shows`, anime type by genre, no tag.
- Jellyfin has one `Shows` library on `~/Media/Shows`; the `Anime` library goes.
- One-time migration on fedora moves JoJo's files with Sonarr and keeps its
  played episodes in Jellyfin.
- `docs/media.md`, `ai/AGENTS.md` and the `midia` skill follow.

## Left to the builder

- Exact SVG shapes and sizes, matched to Stremio's row icons.
- README wording and the addon compatibility notes.
