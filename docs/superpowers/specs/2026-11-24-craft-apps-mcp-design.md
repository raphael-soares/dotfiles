# ArtCraft apps driven by the agent, with a window on request

## Why

The owner does design, video and audio work in the ArtCraft Crafting Apps (installed
as Flatpaks by the ArtCraft Launcher on the `fedora` machine). He wants the agent to
use them as tools, several in one task, without a pile of windows: by default the
agent works without a window. When he wants to watch or join in, he asks the agent to
open the window; from then on he sees each change land, makes his own by hand, and
the two keep working on the same document. The flow should be the same in every
session, not rebuilt each time.

## Goals

- Every installed Crafting App with an MCP server is registered in omp:
  EffectCraft, FilmCraft, GridCraft, LightCraft, PdfCraft, PhotoCraft, SoundCraft,
  VectorCraft, WordCraft.
- By default the agent works without a window, on files under `~/Design`.
- For the seven apps that can be driven live (all but PdfCraft and WordCraft), the agent can open
  the window on the owner's request and carry the work into it: from then on each
  change lands in the app's History, and Ctrl+Z undoes it like a manual step. If the
  app is already open, the agent joins that window instead of opening another.
- When the owner closes the window, the agent goes back to working without one, on
  the saved file.
- A skill gives the agent one way of working with the apps and the owner.
- A deploy on a new or reinstalled `fedora` sets all of this up again. An app the
  launcher has not installed yet is skipped, and adding a future app is one table
  line.

## Non-goals

- Installing the apps or keeping them updated: the ArtCraft Launcher does that.
- Claude Code. It starts every MCP server when a session opens, so each session would
  start nine engines; omp starts a server on the agent's first call.
- craft-mcp-hub (unofficial, 25 stars): it runs the apps without windows only and
  does not know omp.
- ArtCraft Studio (the generative app) and the laptop, which has no Crafting Apps.
- The agent closing a window. The owner closes it; the skill tells the agent to ask.

## Anti-goals

- A window opening without the owner asking for it.
- Work lost on the switch to the window. The engine without a window keeps the
  document in memory only, so the agent saves before switching, and the switch keeps
  the windowless engine alive until the window is connected.
- The agent editing a copy of the document instead of the one open in the window.
- A control token committed to the repo.

## Approaches

- **A, a small MCP proxy per app with an "open window" tool (chosen).** One server
  per app. It runs the windowless engine and adds one tool that opens the app on a
  saved file (or joins the open app) and switches to it; when the window closes it
  switches back. Costs a Python script of roughly 200 lines.
- **B, two servers per app, windowless and connected, no proxy.** Less code, but 17
  servers and a doubled tool list, and the connected server fails its listing while
  the app is closed. The owner chose A.
- **C, A plus joining a window the owner opened by himself without being asked.**
  Saves one request, but the agent could take over an app he opened for something
  else. The owner chose A.
- **D, live only** (the earlier draft): every app the agent touches opens a window,
  which stops working once a task uses several apps.

## Design

### Module

A new `design` module, only in `.dotter/fedora.toml`, with its own block in
`.dotter/post_deploy.sh`, a `bin` linked to `~/.local/bin` and a `docs/design.md`.
The README machine table gets its row.

### One table of apps

A single table in the repo, `design/apps`, lists each app: name, control port, the
CLI arguments for the windowless server and for a server connected to the running
app, and whether the app needs a token. The deploy and the proxy both read it. Ports
keep the apps' own defaults where they have one (VectorCraft 7979, LightCraft 7980)
and take the next free ones for the rest (7981 onward); GridCraft's default is also
7979, so one table of unique ports is required, not just tidy.

What each app's `--help` and control docs say (versions installed on 2026-11-24):

| App | Version | Port | App listens with | CLI connects with | Token |
|---|---|---|---|---|---|
| VectorCraft | 0.24.1 | 7979 | `VECTORCRAFT_CONTROL_PORT` | `mcp --connect 127.0.0.1:PORT` | no |
| LightCraft | 0.21.1 | 7980 | `LIGHTCRAFT_CONTROL_PORT` | `mcp --compact --connect 127.0.0.1:PORT` (409 tools without `--compact`, in both modes) | no |
| PhotoCraft | 0.23.1 | 7981 | `PHOTOCRAFT_CONTROL_PORT` | `mcp --bridge 127.0.0.1:PORT` | yes, `PHOTOCRAFT_CONTROL_TOKEN` (64 hex) |
| WordCraft | 0.18.1 | none | no live MCP | windowless only: the window's key file is named after its Flatpak instance, so a CLI in another instance cannot find it, and upstream refuses `--connect` for now (wordcraft#7124) | no |
| GridCraft | 0.19.1 | 7983 | `GRIDCRAFT_CONTROL_PORT` | `mcp --connect PORT` | yes, always; `GRIDCRAFT_CONTROL_TOKEN` |
| FilmCraft | 0.20.1 | 7984 | `FILMCRAFT_CONTROL_PORT` | `mcp --bridge 127.0.0.1:PORT` | yes, `FILMCRAFT_CONTROL_TOKEN` (64 hex, required) |
| EffectCraft | 0.25.1 | 7985 | `EFFECTCRAFT_CONTROL_PORT` | `mcp --bridge PORT` | no (the port has no auth) |
| SoundCraft | 0.20.1 | 7986 | `SOUNDCRAFT_CONTROL_PORT` | `mcp --connect PORT` | no |
| PdfCraft | 0.22.0 | none | no live MCP | windowless only, `mcp --compact` (200 tools otherwise) | no |

Every live app takes its port from a variable, so a menu launch listens too once the
override is in place.

The windowless servers need file access to `~/Design`. PhotoCraft's CLI refuses
absolute paths without automation roots, so its windowless arguments carry
`--automation-read-root` and `--automation-write-root` for `~/Design`. The others
saved under `~/Design` without roots in a test on 2026-11-24 and get none. This is to
make PhotoCraft work, not to confine.

### Flatpak overrides, applied by the deploy

For each installed app in the table, `flatpak override --user`:

- `--env=<APP>_CONTROL_PORT=<port>`, so the app listens however it is opened (menu,
  launcher, proxy). Today the menu entry does not listen because nothing sets it.
- `--env=<APP>_CONTROL_TOKEN=<64 hex>` for the apps that require a token (PhotoCraft,
  GridCraft, FilmCraft). The owner decided against tokens for apps that work without
  one: the control ports listen on loopback only and the PC is single-user. GridCraft
  writes its own token file when the variable is missing, but in its app's private
  runtime folder, which a second sandbox instance (the CLI) cannot see, so it gets
  the variable too. The token lives only in the override: the CLI child runs inside
  the same app id, so it inherits the value with no copy in the proxy or the repo. A
  deploy reads an existing value back and does not rotate it.
- `--filesystem=~/Design`. Today VectorCraft sees only `~/Pictures` and `~/.fonts`,
  PdfCraft and GridCraft only Documents and Downloads, SoundCraft only Music.

PhotoCraft's app also refuses all file access from its control channel without
roots ("none without it"), so it gets `PHOTOCRAFT_AUTOMATION_READ_ROOT` and
`PHOTOCRAFT_AUTOMATION_WRITE_ROOT` set to `~/Design`.

### Proxy

`craft-mcp <app>`, in Python 3, is the command omp runs for every Crafting App
server. It speaks MCP over stdio to omp and to one child CLI at a time, run inside
the app's own sandbox (`flatpak run --command=<app>-cli ai.storyteller.<app> mcp …`),
so the child sees the same files and token. Flatpak shares the host network, so
loopback should reach the app; the first build step proves it. The windowless child
runs with the port variable unset, so a CLI that honours it cannot connect on its
own; the connected child runs with the automation root variables unset, because
PhotoCraft's bridge refuses roots.

1. Unknown or uninstalled app: exit non-zero with a message naming the ArtCraft
   Launcher.
2. PdfCraft and WordCraft: no proxying, run their CLI windowless (PdfCraft with `--compact`).
3. Start the windowless child and forward everything to it. The tool list it returns
   gets one more tool, `open_window`, and the proxy declares `tools.listChanged`.
4. `open_window {path?}`, handled by the proxy:
   - If the window is already connected, say so.
   - If the app's port answers (the owner has it open), connect to it. The result
     tells the agent the window was already open, so it opens `path` there with the
     app's own command unless that document is the one shown.
   - If the app is running (a host process named exactly like the app's binary;
     `flatpak ps` would also list the proxy's own CLI children) but its port stays
     silent for 5 seconds, it was opened before the deploy: fail with "close and
     reopen <App>".
   - Else start the app detached on `path` (output to
     `<dotfiles state dir>/design/<app>.log`) and wait up to 30 seconds for its port.
   - Then start the connected child, replay the saved `initialize` and `initialized`
     to it, stop the windowless child, send `notifications/tools/list_changed` if the
     tool list differs (omp refreshes on it), and return.
   - Any failure leaves the windowless child running and its document untouched, and
     fails the call with a clear message.
   The tool's description tells the agent to save the document under `~/Design`
   first and pass that path, since the windowless engine's unsaved state does not
   travel.
5. The window counts as closed when, while connected, the app's port stops answering
   before a request is forwarded, or the connected child exits. A connected child
   does not exit on its own when the app closes (its calls just fail), so the port is
   probed on every request. Then the proxy stops the connected child, starts a
   windowless one again (replaying the handshake, `list_changed` if the tools
   differ), and that tool call fails once with "The <App> window was closed; working
   without a window again. Open <last path> to continue." so the agent reloads the
   saved file instead of working on an empty engine.

### omp registration

The servers go in a file only the `fedora` machine has, so the laptop's omp never
lists broken servers: the deploy writes `~/.omp/agent/.mcp.json`, which omp reads
beside `mcp.json` (documented in `omp://mcp-config.md`), from the table, one entry
per installed app: `"command": "craft-mcp"`, `"args": ["<app>"]`, `cwd` at `${HOME}`
so sessions in any folder share one server. Generating it keeps adding an app to one
table line.

### Skill

A new skill in `ai/skills/` that the agent reads when the owner works with a Crafting
App. It holds the working agreement:

- which app for what (vector and logos, photo editing, video, motion, audio and
  narration, photo library, documents, spreadsheets, PDFs);
- work without a window by default; open it only when the owner asks ("abre a
  janela", "quero ver"), never on its own initiative;
- every project lives in `~/Design/<project>/`, saved in the app's native format,
  exported on request; keep text live, never outlined, unless asked;
- before `open_window`, save the document and pass its path; after it, the owner may
  change the document by hand, so read its current state before each change;
- in the window, work on the open document, never on a copy; one request is one
  atomic batch with a readable label, so one Ctrl+Z undoes it;
- when a window was closed, reopen the saved file before going on; to close a
  window, ask the owner;
- render a preview and look at it before saying it is done;
- find commands with the app's own command list instead of remembered tool names
  (the apps are alpha and rename tools between releases);
- when a server reports it cannot reach its app, pass the message on (for example
  "close and reopen VectorCraft") instead of working around it.

## Verification

- `flatpak override --user --show <id>` shows the port, the token where required and
  `~/Design` for each installed app.
- With every app closed, a fresh omp discovery (`/mcp reload`) lists all nine
  servers' tools, `open_window` among them for the seven live apps, and opens no
  window.
- Per live app: a windowless call that writes a file under `~/Design`; then
  `open_window` with the app closed (one window opens on that file) and with it
  already open (no second window, the next call lands in that window).
- One real round on VectorCraft: the agent draws a shape without a window and saves;
  `open_window` shows it; the owner moves the shape by hand, the agent's next read
  sees the new position, Ctrl+Z removes the agent's next batch in one step; the
  owner closes the window and the agent's next call is told to reopen the file.

## Left to the builder

- The skill's name and wording, following the `writing-skills` skill and the other
  skills in `ai/skills/`.
