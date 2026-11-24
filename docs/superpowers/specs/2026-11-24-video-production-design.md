# Video production skill and local voice

## Intent

The owner wants to make explainer videos without ever appearing in them: no own
voice, no face, no camera, no recordings of any kind. The first use is lessons on
his university subjects (Sistemas Operacionais, Estrutura de Dados II, Análise de
Requisitos II, Engenharia de Software), built from his own course material; later,
experimental YouTube videos on whatever he wants to try. The look is graphics and
animation, and the voice is synthetic, in pt-BR or English per video.

He does not want to spend an afternoon per video. The agent does the work and stops
at three points for his approval; he opens an app window (the `open_window` tool from
the ArtCraft design) only when he feels like editing along.

## Goals

- A skill, `video`, that takes a video from a topic plus the owner's material to a
  finished 16:9 `.mp4` and a thumbnail, stopping for approval at:
  1. **Script**: written from the material the owner points at (slides, notes, a
     course PDF), each part citing its source.
  2. **Storyboard**: the list of scenes, each with what is seen, what the voice says,
     and which engine makes it.
  3. **Final cut**: the assembled video.
- Each video is pt-BR or English, chosen at the start; narration, on-screen text and
  thumbnail follow it.
- Narration from a free local voice (Kokoro 82M, Apache 2.0), reachable through omp's
  `tts` tool.
- Scenes come from two engines (owner's pick, see Approaches):
  - **Manim** for algorithms, data structures, diagrams and formulas.
  - **EffectCraft** for the opening, titles, transitions and finish.
- **FilmCraft** assembles scenes and narration and exports; **SoundCraft** mixes the
  audio when there is more than narration (music bed, levels); **VectorCraft** makes
  the thumbnail.
- A deploy on `fedora` installs what this needs (Manim and its system libraries, the
  voice server setup, omp's speech role).

## Non-goals

- Uploading to YouTube, titles/descriptions/SEO, channel management.
- Any recorded input from the owner: voice, face, screen.
- AniCraft and DeckCraft. AniCraft (2D animation) is 0.2.1, early alpha, and exports
  MP4 only through an external ffmpeg; DeckCraft exports no video. Revisit when they
  mature.
- Voice cloning, and models that forbid commercial use (XTTS v2, F5-TTS, Fish Audio).
- The `arch` machine and Claude Code.

## Anti-goals

- A lesson that says something the material does not, or skips what it stresses: the
  script must stay traceable to the source.
- Narration and picture out of step: every scene's length comes from its narration.
- A pipeline that only works end to end: each stage's output is a file the owner can
  read or open, so a rejected storyboard does not mean starting over.
- Loud or robotic output passed off as done: the agent watches/listens to its own
  result (rendered frames, audio length and levels) before calling a checkpoint.

## Constraints

- Home PC `fedora` (AMD RX 6600, no CUDA): everything runs on CPU.
- The ArtCraft apps are driven through `craft-mcp` (branch `feat/craft-mcp`, PR #72),
  windowless by default. This work builds on that branch.
- omp v19 `tts`: backends are local Phonon (English only), xAI, and
  `openai-speech`, which calls `<baseUrl>/audio/speech` of a model with
  `kind: tts`, sends `voice` only when the caller passes `voice_id`, and is chosen
  through `modelRoles.speech`. `language` is ignored for `openai-speech`, so the
  language is picked by the voice.
- Kokoro picks the language from the voice id prefix: `pf_`/`pm_` are pt-BR
  (`pf_dora`, `pm_alex`, `pm_santa`), `af_`/`am_` American English, `bf_`/`bm_`
  British.
- Home layout (AGENTS.md): design work lives in `~/Design`, one folder per project.
- Owner rules: questions through `ask`, no em/en dashes, pt-BR to the owner, code
  comments default to zero.

## Approaches

Where scenes are animated was the open choice; assembly in FilmCraft, audio in
SoundCraft and the thumbnail in VectorCraft are common to all.

1. **Suite only (EffectCraft).** Every scene editable in a window with shared undo.
   Weak at step-by-step algorithm animation, which is most of the owner's subjects.
2. **Manim only.** Mature (the 3Blue1Brown engine), strong at exactly that content,
   one path. Code only, no hand editing, plainer titles and finish.
3. **Hybrid (picked by the owner).** Manim for algorithm, diagram and formula scenes;
   EffectCraft for opening, titles and finish; the storyboard names the engine per
   scene. Costs two paths to keep working and a per-scene decision.

## Design

### The video folder

`~/Design/Videos/<slug>/`, one per video:

| Path | What |
|---|---|
| `video.md` | language, voice, identity, music, target length, source paths, current checkpoint |
| `roteiro.md` | the script, with a source citation per section |
| `storyboard.md` | scenes in order: id, narration text, what is seen, engine, notes |
| `cenas/manim/<id>.py` | one Manim scene per storyboard scene that uses it |
| `cenas/effectcraft/<id>.ecproj` | EffectCraft scenes |
| `cenas/render/<id>.mp4` | each scene rendered at its narration length |
| `audio/<id>.wav` | narration per scene |
| `montagem.fcproj` | the FilmCraft project |
| `final.mp4` | the export |
| `miniatura.vectorcraft`, `miniatura.png` | thumbnail, 1280x720 |

### Visual identities (owner's decision)

The owner keeps a library of his own identities and the agent can create new ones.
`~/Design/Identidades/<nome>/` holds, per identity:

- `identidade.md`: palette, fonts, title and caption style, and how transitions look;
- `tema.py`: the same values as a Manim module the scenes import;
- `abertura.ecproj`: an EffectCraft opening and title-card template;
- `miniatura.vectorcraft`: a thumbnail template.

At the start of a video the agent offers the existing identities (and "create a new
one"). A new identity is shown to the owner as a sample frame and a sample thumbnail
and saved to the library only after he approves it.

### Music (owner's decision)

`~/Design/Videos/Musicas/` is the owner's music folder. At the start of planning:

- with files in it, the agent asks whether this video has music, and if so which track
  (or lets the agent pick one that fits);
- empty, the agent asks whether the video will have music; if yes, the owner adds the
  file.

With music, SoundCraft mixes it under the narration (ducked while the voice speaks)
before assembly.

### Formulas in Typst (owner's decision)

The owner already writes Typst. Formulas are written in Typst, compiled to SVG
(`typst compile --format svg`) and loaded into Manim as SVG objects, so they look like
his notes and need no LaTeX. Typst comes in through the deploy.

### Flow

1. **Start.** The owner names the topic and the material. The agent asks (one `ask`
   per question) for language, target length, identity and music when not given, and
   writes `video.md`.
2. **Script.** Read the material, write `roteiro.md` in the video's language at a
   spoken pace (about 140 words a minute in pt-BR, 150 in English), each section citing
   file and page/slide. Checkpoint 1.
3. **Storyboard.** Split into scenes of roughly 5 to 30 seconds; each gets its exact
   narration text, a visual description and an engine (Manim for algorithms,
   structures, diagrams, formulas; EffectCraft for opening, titles, section cards,
   closing). Agent's call: a step-by-step algorithm becomes one short scene per step,
   so the voice talks about the step being shown. Agent's call: narration text spells
   English terms inside pt-BR the way they are said, when the voice gets them wrong.
   Checkpoint 2.
4. **Narration.** One `tts` call per scene with the video's voice into
   `audio/<id>.wav`; measure each duration. Narration is made before animation so
   scenes are timed to it.
5. **Scenes.** Manim scenes are written and rendered at 1920x1080, 30 fps, sized to the
   narration length (the last frame is held if the animation ends early); EffectCraft
   scenes are built through its MCP tools and rendered to `.mp4` with its render queue
   (`renderQueue.add` h264, then `renderQueue.render`). Agent's call: while working,
   scenes render as low-resolution drafts; the final pass is 1080p. The agent checks
   sampled frames of each scene before moving on.
6. **Assembly.** FilmCraft project with scenes on the video track and narration on the
   audio track (or the SoundCraft mix), in storyboard order, with simple transitions.
   Export `final.mp4` through its export queue.
7. **Thumbnail.** VectorCraft, 1280x720, the video's language, exported to PNG.
8. **Final cut.** Checkpoint 3: the agent reports length, the file paths, and what it
   checked. Requested changes go back to the stage they belong to; only the affected
   scenes are redone.

At any point the owner can ask to see a scene in its app; the agent saves and calls
that app's `open_window` (EffectCraft, FilmCraft, SoundCraft, VectorCraft).

### Local voice

- Kokoro-FastAPI (OpenAI-compatible, CPU image) runs as a podman container bound to
  127.0.0.1, started on demand by a small command before narration and left running
  until the owner stops it or the machine restarts.
- omp gets a custom model with `api: openai-speech`, `kind: tts`, base URL of that
  server, and `modelRoles.speech` pointing at it, so `tts` with `voice_id` reaches
  Kokoro. The speech fallback chain is empty: falling back to Phonon (English only)
  would silently narrate a pt-BR lesson in the wrong language, so a stopped server
  fails loudly instead.
- The skill always passes `voice_id`; defaults: `pf_dora` for pt-BR, `af_heart` for
  English, overridable per video in `video.md`.

### Packaging in the dotfiles

- `ai/skills/video/SKILL.md` (pt-BR, like `artcraft`), referencing `artcraft` for
  app/format rules.
- Manim and its system libraries, Typst, the voice command and its container setup,
  and the omp speech configuration come in through the `fedora` deploy, in the
  `design` module.

## Left to the builder

- Exact omp config for the custom speech model (`models.yml` or `config.yml`, key
  names), verified against omp v19 with a real `tts` call.
- Kokoro-FastAPI image tag and port; whether the on-demand command is a script or a
  quadlet with socket activation.
- How Manim is installed (uv tool or pipx) and which Fedora packages it needs.
- Reading the material: `pdfcraft` text extraction for PDFs, the right tool for
  slides; whether any material needs OCR.
- Which scenes to redo after a change at the final cut (by comparing narration text
  and scene code with what was rendered, or case by case).
- FilmCraft and EffectCraft command ids for import, timeline placement, transitions
  and render, from their MCP tool lists.
- How the skill is tested (micro-tests like the `artcraft` skill), and a real
  end-to-end run on a short lesson from `~/Udesc` with the owner approving the three
  checkpoints.
