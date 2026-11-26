# Home and Drive layout

Two machines share one convention: the notebook (work, code, startup, university)
and the home PC (games, design, music). Each home is local and follows XDG; nothing
in it syncs. What must exist on both machines or on the phone lives in `~/Drive`,
a full offline mirror of the Google Drive root (`Raphael:`) through one syncfast
pair. The path is the sync boundary: inside `~/Drive` syncs, outside does not.
Design: `docs/superpowers/specs/2026-11-26-drive-and-home-layout-design.md`.

Where to save: needed on the other machine or the phone? `~/Drive/<Area>`.
Otherwise, the local XDG folder.

## `~/Drive` (both machines)

|Folder|Holds|
|---|---|
|`Personal`|`Identity`, `Finance`, `Career` (CV), `Photos`, `Wallpaper`, `Torrents`, `Archive`|
|`Udesc`|one folder per course taken now (`SOP-sistemas-operacionais`), `University` (calendar, enrollment), `Archive/<year>-<semester>/<course>`; rules in `Udesc/README.md`|
|`Unimed`|`Projects/<project>`, `Admin` (badge), `Brand`, `Technical` (architecture, notes), `Archive`|
|`TEAjudo`|`Projects/<project>`, `Legal`, `Commercial`, `Brand`, `Archive`|
|`Documents`|`~/Documents` links here: documents with no area (manuals, templates, references)|
|`Inbox`|the door from the phone and the web; the daily triage empties it|
|`Backups`|cloud only, outside the pair: `media/` (`media-backup`, encrypted with age), `fedora/` (`creative-backup`, `~/Creative` and `~/Studio`, not encrypted because nothing in it is sensitive)|

- Inside an area: work that ends goes in `Projects/<project>`, named like the
  worktree or feature; ongoing reference goes in a category (2 or 3 per area); a
  finished project moves whole to `Archive/`. A finished course moves to
  `Udesc/Archive/<semester>/` when the new semester is set up.
- Structure folders are capitalized English (`Personal/Finance`); below them,
  lowercase English with hyphens. Proper names, systems, courses and works keep
  their original name (`auditoria-centralizada`, `SOP-sistemas-operacionais`). A
  single file stays loose; a folder only when it groups more than one.
- The Drive holds project documents, never code or git (syncfast's `git_repos`
  preset blocks repos). The project folder's README points to the repo in `~/Code`.
- Third-party personal data (patients, CPF) never enters the Drive: it stays in
  the repo's gitignored `attachments/`. Secrets never enter the Drive (see
  `docs/machines.md`, Secrets).
- A colleague's material is copied into the course, never linked.
- The pair excludes `*.mkv`, `*.iso`, `*.nsp`, `*.xci`, `*.nsz`, `/Backups`,
  `Personal/Wallpaper/wallz` (a third-party clone) and `forest-4.jpg`. That file
  is a link dotter makes from the repo (`hyprland/noctalia/`) into the wallpaper
  folder, which is itself a link into the Drive, so it exists on each machine
  and never travels.
- `.dotter/pre_deploy.sh` makes `~/Documents` and `~/Pictures/Wallpaper` those
  links before dotter links anything into them; a real folder holding files
  there stops it with a message to move them first.

## Local home

|Folder|Holds|Where|
|---|---|---|
|`~/Documents`|link to `~/Drive/Documents`|both|
|`~/Downloads`|the browser's inbox; the daily triage empties it|both|
|`~/Pictures`|`Screenshots`, `Icons`, `Wallpaper` (link to `~/Drive/Personal/Wallpaper`)|both|
|`~/Videos`|`Recordings` (screen recordings)|both|
|`~/Code/<Area>/[<system>/]<repo>`|every git repo; git is the sync. TEAjudo's monorepo is `~/Code/TEAjudo/teajudo`|both|
|`~/Creative`|`Projects/<Area>/<project>/` (video, audio, art and brand together), `Library/` (third-party assets), `Styles/` (own identities), `Archive/`|home PC|
|`~/Studio`|music production: samples, presets, projects|home PC|
|`~/Games`|what is downloaded by hand: `PC`, `Switch`, `ROMs/<console>`; Steam stays in `~/.local/share/Steam`|home PC|
|`~/Media`|consumption, one folder per type: `Movies`, `Shows` (series and anime), `Books`, `Downloads`; one tree so Radarr and Sonarr can hardlink|home PC|

- Worktrees only in `~/.workmux`. `~/.dotfiles` stays where it is (dotter's path).
- What is done in a local folder moves to its `Archive/`. Never a hidden folder.
- No other area at the top of the home: no `~/Notes`, no `~/University`.
- `.torrent` files go to `~/Drive/Personal/Torrents`, never next to the content.
  qBittorrent (home PC, `docs/media.md`) copies them there, and each category
  saves to the folder of the same name (`Books/Mangas` in `~/Media/Books/Mangas`,
  `Games/ROMs/PSP` in `~/Games/ROMs/PSP`). Movies and shows go through Radarr and
  Sonarr: downloaded to `~/Media/Downloads`, hardlinked into `~/Media/Movies` and
  `~/Media/Shows`.
- The daily triage at 8:00 (herdr automation `triagem-arquivos`, `terminal/bin/triage`)
  moves what has a certain place out of `~/Downloads`, `~/Drive/Inbox` and loose
  screenshots in `~/Pictures`, never deletes, logs to `~/.local/state/triage/` and
  notifies what is left. `triage undo <date>` reverts a day.
