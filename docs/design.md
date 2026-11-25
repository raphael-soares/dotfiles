# ArtCraft apps in omp

omp drives the ArtCraft Crafting Apps (Flatpaks installed with the ArtCraft
Launcher). By default the agent works without a window, on files in `~/Design`.
When the owner asks to see the work, the agent calls `open_window`: the app opens
on the saved file, and from then on the agent and the owner edit the same
document, with one History and one Ctrl+Z. When the owner closes the window, the
agent goes back to working without one and reopens the saved file.

The `design` module (only on `fedora`) has one table, `design/apps`, a proxy,
`craft-mcp`, and a deploy step, `design-deploy`. Design:
[`superpowers/specs/2026-11-24-craft-apps-mcp-design.md`](superpowers/specs/2026-11-24-craft-apps-mcp-design.md).

## The apps

| App | Port | Token | Notes |
|---|---|---|---|
| VectorCraft | 7979 | no | |
| LightCraft | 7980 | no | `--compact` (409 tools otherwise) |
| PhotoCraft | 7981 | yes | automation roots on `~/Design`, its CLI refuses absolute paths without them |
| WordCraft | none | no | windowless only: 0.18.1 keeps the window's key per Flatpak instance, so the server cannot find it, and upstream refuses `--connect` for now (wordcraft#7124) |
| GridCraft | 7983 | yes | |
| FilmCraft | 7984 | yes | |
| EffectCraft | 7985 | no | |
| SoundCraft | 7986 | no | |
| PdfCraft | none | no | windowless only, `--compact` |

The ports listen on 127.0.0.1 only. A token is a 64 hex value generated on the
first deploy and kept on every later one.

## How it works

omp starts `craft-mcp <app>` for each installed app. The proxy runs the app's own
MCP server (`<app>-cli mcp`) without a window and adds one tool, `open_window`.

`open_window {path}`:

- if the app is already open and listening, the proxy joins that window;
- if the app is open but not listening (opened before the deploy), it answers
  "close and reopen";
- otherwise it opens the app on `path` and waits up to 30 s for the port.

Then the proxy swaps the windowless server for one connected to the window, and
omp refreshes the tool list. Unsaved work in the windowless engine does not
travel, so the agent saves first and passes that path.

Before each request in connected mode the proxy checks the port. When it stops
answering (the owner closed the window), the proxy goes back to the windowless
server and fails that one call with "Open <path> to continue".

## Where things live

| What | Path |
|---|---|
| App table | `design/apps` |
| Proxy and deploy step | `design/bin` → `~/.local/bin` |
| Port, token, `~/Design` access | `flatpak override --user --show ai.storyteller.<app>` |
| omp server list | `~/.omp/agent/.mcp.json`, written by the deploy for installed apps |
| App output when the proxy opens a window | `~/.local/state/dotfiles/design/<app>.log` |
| Files the agent works on | `~/Design` |

## Add an app

Install it with the ArtCraft Launcher, add one line to `design/apps` (the fields
come from `<app>-cli mcp --help`), run `dotter deploy`, then `/mcp reload` in omp.
An app installed after the deploy only shows up in omp after the next deploy.

## Close and reopen

The app reads its port from the Flatpak override when it starts. A window opened
before the first deploy does not listen, and `open_window` says so. Closing and
reopening the app fixes it, from the menu or by asking the agent again.

## Video

The `video` skill turns a topic and the owner's material into a narrated 16:9
`.mp4` and a thumbnail, in `~/Design/Videos/<slug>/`. Besides the apps above it
uses these tools on the desktop:

| Tool | From | Used for |
| --- | --- | --- |
| Manim | `uv tool install manim`, printed by `missing.sh design` | algorithm, diagram and formula scenes |
| Typst | mise (`terminal/mise/config.toml`) | formulas, compiled to SVG and loaded into Manim |
| Kokoro | `kokoro.service`, a podman quadlet on `127.0.0.1:8880` | narration through `ai/skills/video/narrar.py` |

Kokoro does not start with the session: the skill runs `systemctl --user start
kokoro` before narrating (the first start downloads a 1.5 GB image).
`narrar.py` posts each plano's fala to Kokoro's OpenAI-style speech endpoint
and fails with that hint when the server is down; it never falls back to
another engine. omp's `tts` tool is not used: it resolves a speech model
through omp's roles and failed with "No available speech model matches the
speech role" even with Kokoro up. On the laptop there is no Kokoro.

Voices: `pf_dora` for pt-BR, `af_heart` for English, read from the `- Voz:`
line of the video's `video.md`. The prefix picks the language (`pf_`/`pm_` are
pt-BR).

Identities live in `~/Design/Identidades/<nome>/` and music in
`~/Design/Videos/Musicas/`.

Pre-production runs through two blind reviewer agents, `video-espectador` and
`video-critico` (`ai/.omp/agent/agents/`, linked to `~/.omp/agent/agents`). The
skill stages what each may see with `ai/skills/video/revisao.py`, narrates each
plano straight through Kokoro with `ai/skills/video/narrar.py`, cuts the
animatic with `ai/skills/video/animatic.py` and checks the 10% margin of
rendered frames with `ai/skills/video/margem.py`; all four need only Python
and ffmpeg and are tested by `tests/video_tools.py`. Storyboard stills come
from the identity's `Cena`, which saves one frame per plano and the scene's
opening frame when Manim runs with `-s`.
