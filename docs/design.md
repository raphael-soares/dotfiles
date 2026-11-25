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
`.mp4` and a thumbnail, in `~/Design/Projetos/<projeto>/<peça>/`. Besides the
apps above it uses these tools on the desktop:

| Tool | From | Used for |
| --- | --- | --- |
| Manim | `uv tool install manim`, printed by `missing.sh design` | algorithm, diagram and formula scenes |
| Typst | mise (`terminal/mise/config.toml`) | formulas, compiled to SVG and loaded into Manim |
| OmniVoice | audio.cpp in the Docker container `audiocpp` (`~/.config/audiocpp/compose.yaml`), `127.0.0.1:8880` | narration through `ai/skills/video/narrar.py` |
| Whisper | local ASR on `127.0.0.1:9000` | `ai/skills/video/ouvir.py` checks each narrated plano |

OmniVoice does not start with the session: the skill runs `docker compose -f
~/.config/audiocpp/compose.yaml up -d` and waits for `/v1/models` before
narrating. `narrar.py` posts each plano's fala to the OpenAI-style speech
endpoint with `speed` 0.9 (at the default speed the last sound of a sentence
gets cut) and never falls back to another engine. omp's `tts` tool is not
used: it failed with "No available speech model matches the speech role".

Voices: `professora` for pt-BR, `teacher` for English, cloned from a fixed
synthetic recording and read from the `- Voz:` line of the video's
`video.md`.

`~/Design` holds `Biblioteca/` (third-party assets, music included), `Estilos/<nome>/`
(own visual identities) and `Projetos/<projeto>/` with one folder per deliverable.

Every stage ends in a sketch the owner approves. The skill's `repertorio/`
holds consolidated techniques the per-video direction picks from, and
`oficio/` holds how to work in each app. Two blind reviewer agents,
`video-espectador` and `video-critico` (`ai/.omp/agent/agents/`, linked to
`~/.omp/agent/agents`), review the roteiro, storyboard, animatic, draft and
first cut. The skill stages what each may see with
`ai/skills/video/revisao.py`, narrates each plano with
`ai/skills/video/narrar.py`, cuts the animatic with
`ai/skills/video/animatic.py`, joins each rendered scene with its narration
into the draft with `ai/skills/video/rascunho.py`, checks the 10% margin of
frames with `ai/skills/video/margem.py` and renders one clip per plano with
`ai/skills/video/planos.py`; sound and edit are done by hand in SoundCraft and
FilmCraft. The scripts need only Python and ffmpeg (Manim for `planos.py`) and
are tested by `tests/video_tools.py`. Storyboard stills come from the style's
`Cena`, which saves one frame per plano and the scene's opening frame when
Manim runs with `-s`.
