# Video pre-production and blind reviewers

## Intent

The owner approved the remade "Hardware e técnicas de entrada e saída" video
and asked for the next level. In his words, the video started talking about
"barramento" as if the viewer already knew what it was. His rule: write every
video for someone who landed on it cold, from a search, with nothing before it.
He also wants better animation and a far more planned, broken-down
pre-production, so the result is quality and not slop. He asked for research
before any change.

Evidence of the failure, from that video's `roteiro.md`: plano 4 of `01-gancho`
labels "barramento" on screen, and plano 1 of `03-controlador` says "o
dispositivo não se liga direto no barramento". "Barramento" is never shown or
defined. "Entrada e saída" and "controlador" are named before they appear. The
skill had no rule against this, and the author reviewing his own script cannot
see it (curse of knowledge).

## What the research says

- **Planning carries the result.** Code2Video (ICML 2026) dropped from 82 to
  40.5 on its learning metric without the planner, and by 21 points without the
  visual critic ([paper](https://arxiv.org/html/2510.01174)). LASEV (KDD 2026)
  went from 42% to 92% publishable when it added critics. The semantic critic
  gave the largest gain.
- **Measure learning, not looks.** Code2Video's TeachQuiz has a model that does
  not know the topic watch the video and answer a quiz. It catches gaps that
  aesthetic scores miss.
- **Pre-production gates.** Pixar cuts storyboards with scratch voices into a
  story reel and shows it to an in-house audience before animating. Ed Catmull
  calls that "a crucial moment" ([Wired](https://www.wired.com/story/how-toy-story-3-was-made)).
  Motion studios approve in order: style frames (look), storyboard (what
  happens), animatic (timing and flow), then animation (movement). Story and
  timing lock at the animatic
  ([35milimetre](https://www.35milimetre.com/blog/motion-design-storyboard-animatic)).
  Kurzgesagt treats writing as the bottleneck and storyboards every scene
  before illustrating.
- **Clarity is not learning.** In Derek Muller's thesis, the polished
  explanation left misconceptions in place. The version where a learner is
  wrong and gets corrected roughly doubled scores. A demonstration without a
  prediction first teaches almost nothing
  ([interview](https://topfluencers.co/blog/derek-muller-interview)).
- **Pre-training.** Teaching the names and parts before the process helps
  (Mayer, d = 0.46). Segmenting (d = 0.70) and modality (d = 0.72) are already
  in the skill.
- **Animation craft.** Progressive disclosure; transform, don't replace;
  colour carries meaning; staging, one change at a time, and object constancy
  (Heer & Robertson 2007); fast, fast, slow, with a pause after the key idea;
  camera push-in on the reveal. Grant Sanderson: when an animation is not
  visually compelling, the explanation needs restructuring.

## Goals

- A pre-production that fixes what the video teaches, to whom, in what order
  and with what pictures before any animation is made:
  1. **Briefing** (`briefing.md`): who watches and what they already know; the
     one idea they leave with; 3 to 5 objectives phrased as "after the video
     the viewer can explain or predict X"; a quiz with an answer key; common
     misconceptions about the topic.
  2. **Term map** in `direcao.md`: for each term, the plano where it appears as
     a thing on screen, the plano where it gets its name, and its first use.
     Using a term before it is shown and named fails the script.
  3. **Direction** (`direcao.md`): as today, plus an opening that places the
     viewer before naming anything; the misconception the video confronts;
     predict-then-reveal moments; the arc linked with "mas / então" (but /
     therefore) instead of "e depois".
  4. **Two-column script** (`roteiro.md`): as today.
  5. **Storyboard** (`storyboard/<cena>-<n>.png`): one still per plano, its
     end pose, rendered cheaply with Manim.
  6. **Animatic** (`animatic.mp4`): those stills, each held for its plano's
     narration, with the real Kokoro voice.
- Two blind reviewers as omp custom agents. Each starts with no context and
  never sees the source material:
  - **`video-espectador`** (the cold viewer). It gets only what a viewer would
    get at that stage and the quiz questions, never the answer key. It answers
    the quiz and reports every point where it got lost, with the plano id and
    the kind: term used before it was shown; "why are we talking about this
    now"; a picture that says nothing on mute; a jump.
  - **`video-critico`** (the visual critic). It reviews stills and frames
    against a fixed rubric: mute test, 10% safe margin, one focus at a time,
    continuity across cuts, colour with meaning, on-screen text that does not
    repeat the narration, legibility and clutter. It reports issues per plano.
- The author (the main agent) stays the only writer. It grades the viewer's
  answers against the key, fixes the script or pictures, and reruns the
  reviewer. At most 3 rounds per gate. Anything still failing goes to the owner
  at the checkpoint, listed as such.
- Four owner checkpoints:
  1. **Briefing.** What the video teaches and for whom.
  2. **Animatic.** Shown with `direcao.md` and `roteiro.md`, after the viewer
     has passed on the script and on the animatic and the critic on the
     storyboard. Approval locks story, order and timing.
  3. **Animated draft**, after the critic and the viewer pass on it.
  4. **Final cut.**
- Animation becomes pose to pose. The storyboard stills are the key poses, and
  each plano's animation transforms the previous pose into the next. Scene N
  starts on scene N-1's end pose.
- New skill sections:
  - **"Quem chega de paraquedas"**: the context rules. Place the viewer before
    naming anything. Show, then name, then use. Each block says why it comes
    now. Confront the misconception first when there is one. Ask for a
    prediction before a reveal. At most one new concept per 30 to 45 seconds.
  - **"Movimento"**: the animation rules, translated into Manim. `Transform` /
    `ReplacementTransform` instead of fade out and fade in for the same thing;
    `LaggedStart` for groups; dim what is not the focus (opacity about 0.25);
    `self.camera.frame` push-in on the reveal and pull-out to reset; one change
    at a time; a silent beat after the key idea (the plano audio is padded,
    marked "pausa" in the Tom column); yellow reserved for "look here now".

## Non-goals

- Several author agents (scriptwriter, director and animator as separate
  agents). The owner picked one author plus blind reviewers. Splitting
  authorship costs about 26K tokens of context per agent and risks the single
  metaphor.
- A fully automatic loop. The owner still approves the four checkpoints.
- Thumbnails, YouTube packaging, engines, voice. Those are unchanged.
- Separate style frames. The identity already fixes the look, and a new
  identity already gets a sample frame. The storyboard covers the rest.

## Anti-goals

- A reviewer that has seen the material or the answer key. Its value is not
  knowing.
- Reviewer findings applied blindly. The author decides, and the owner sees
  what was left unresolved.
- A storyboard that costs as much as the animation. Stills must render in
  seconds per scene, or the gate stops being cheap.
- Changing story, order or timing after the animatic without going back to the
  animatic for the scenes it touches.

## Design

### Video folder additions

| Path | What |
|---|---|
| `briefing.md` | audience and prior knowledge, the one idea, objectives, quiz with key, misconceptions |
| `direcao.md` | gains the term map, the opening, the misconception and the predict moments |
| `storyboard/<cena>-<n>.png` | end pose of each plano |
| `animatic.mp4` | stills timed to the narration, with voice |
| `revisao/<etapa>-<n>.md` | each reviewer report and the author's grading, per round |

### Flow

1. Start (as today).
2. Material (as today).
3. Briefing. **Ponto 1.**
4. Direction with the term map.
5. Script. The author checks the term map against it. Viewer round on the
   script (it gets the Tela and Fala columns only).
6. Narration per plano (moves here from after Ponto 1: the animatic needs it).
7. Storyboard stills. Critic round on them.
8. Animatic. Viewer round on it (stills plus the narration text in order).
   **Ponto 2**, then the lock.
9. Animated draft, pose to pose. Critic and viewer rounds on its frames and
   contact sheet. **Ponto 3.**
10. Final pass, assembly, thumbnail. **Ponto 4.**

Changes after the lock: wording or motion changes stay where they are; a change
to what a scene shows, the order or the timing goes back to the storyboard and
animatic of the scenes it touches. What locks is the plano list and
`audio/duracoes.json` as measured for the animatic, pauses included: the "pausa"
padding is applied at the narration step, before the animatic. Rewording a
line, adding, removing or reordering a plano is a timing change. An animation
that runs short or long is not: the scene keeps the narration's length, as
today (`fechar()`).

### What each reviewer receives

The author stages the inputs for each round in
`revisao/<etapa>-<n>/entrada/` and passes only that folder. The prompt forbids
reading anything outside it. The video folder path is never given. The answer
key, `briefing.md`, `direcao.md`, `video.md` and the course material never go
in.

| Gate | Viewer gets | Critic gets |
|---|---|---|
| Script | Tela and Fala columns as text, quiz questions | |
| Storyboard | | stills, Tela column, rubric |
| Animatic | stills in order, then the Fala text per plano, quiz questions | |
| Draft | sampled frames per plano, Fala text per plano, quiz questions | frames, contact sheet, rubric |

On stills and frames the viewer reads the pictures first, without the Fala, and
notes what each one says on mute. Then it reads the Fala. Narration reaches the
reviewers as text, not audio.

### How the viewer finds what the author can't

A model already knows what a bus is, so role-playing ignorance alone is not
reliable. The viewer does two things:

- **Mechanical pass.** Walking the plano list in order, it lists every
  technical term at its first appearance, in the picture or in the speech. For
  each one it says whether, by that plano, the term was shown as a thing and
  named in what it was given. A "no" is a finding. This pass is reproducible,
  and it is independent of the author's term map: that map is the author's
  belief, and the remake would have left "barramento" out of it.
- **Persona pass.** The briefing's "already knows" list becomes the persona
  ("you know X and Y; nothing else about this topic"). It answers the quiz from
  what it was given, says "não sei" when the material does not support an
  answer, and reports where it got lost: "why are we talking about this now",
  a jump, or a picture that says nothing on mute.

### Grading and rounds

- The author grades the quiz against the key. It answers each finding with
  "fixed" (and where) or "rejected" (and why), in
  `revisao/<etapa>-<n>.md`. A rejected finding never disappears: the checkpoint
  lists every rejection with its reason.
- A gate passes with every quiz answer right and every finding fixed or
  rejected with a reason.
- After 3 failing rounds the flow stops at that gate. The author does not
  build the next stage on a script or storyboard that still fails. It shows
  the owner the open findings through `ask`, and the owner decides whether to
  go on, change course, or give guidance.

### Continuity between scenes

Each scene rebuilds its starting state in code, from a per-video module of
shared builders (the remake already had `cenas/manim/palco.py`). Scenes stay
independent: any one still renders alone. The critic checks continuity by
comparing the last frame of scene N with the first frame of scene N+1.

### Videos already in progress

Clean cutover. New videos follow the new flow. A video already past the old
Ponto 1 continues on the old stages, unless the owner asks to redo its
pre-production. `hardware-es` is finished and is not touched.

### Agents in the dotfiles

- `ai/.omp/agent/agents/video-espectador.md` and `video-critico.md`, user-level
  omp agents (frontmatter `name`, `description`, `tools: read`), deployed by a
  new `.dotter/global.toml` entry linking `ai/.omp/agent/agents` to
  `~/.omp/agent/agents`, like `skills` and `rules`.
- Prompts in pt-BR, like the skill.
- The skill calls them through `task` with `agent: video-espectador` or
  `agent: video-critico`, passing file paths and, for the viewer, the quiz
  questions inline.

### Branch

Stacked on PR #77 (`fix/video-plan-timing`), because both change
`ai/skills/video/SKILL.md`. New branch `feat/video-preproduction`. The PR
targets `main` once #77 merges, or `fix/video-plan-timing` until then.

## Acceptance

- The viewer agent, given the old `hardware-es` script and a quiz written for
  it, flags "barramento" used before it is shown. The agent works only if it
  catches the defect that started this.
- omp discovers both agents after deploy (a `task` spawn by name succeeds).
- A real run of the new pre-production on a topic the owner picks, through
  Ponto 2 (briefing, storyboard and animatic), with the owner judging whether
  it is better planned than the remake.

## Left to the builder

- How stills are rendered: a pose mode in the identity's `Cena` (each plano's
  animations applied instantly, one frame saved at each plano's end) or
  another cheap route. Identity `tema.py` files live in `~/Design/Identidades`
  and get updated there; the skill states the contract.
- Free-text reports or a structured `output` schema for the agents.
- The exact rubric wording, and how the staging step extracts the Tela and Fala
  columns.
- Keeping `SKILL.md` readable as it grows: move the Manim and movement detail
  to a reference file next to it if it passes about 350 lines.
