# EffectCraft

Motion graphics: tipografia animada, títulos, cartões, colagem, ilustração da
Library animada, composição com textura e luz.

## Quando usar

Quando o bloco pede movimento expressivo e não precisão: texto que entra com
personalidade, cena montada com ilustração ou foto, transição desenhada,
abertura. Mecanismo exato e diagrama ficam melhor no Manim (`oficio/manim.md`).

## Jeito de trabalhar

Pelo MCP, sem janela: `open_project {new: true}` ou o modelo do estilo;
`command_run comp.new {name, width: 1920, height: 1080, frameRate: 30,
duration}`; camadas com `layer.newText`, `layer.newShape`, `layer.newSolid`,
`file.import` (SVG e PNG da Library); `set_property` e `add_keyframe` para
animar; `add_effect` para efeitos; `render_preview` para olhar. O dono pode
acompanhar com `open_window`.

## Entregar no formato comum

Para storyboard, conferências e edição tratarem a cena como qualquer outra:

- uma comp por plano, com a duração da fala dele (de `audio/duracoes.json`,
  `<id>#planos`) mais a folga que a edição vai querer;
- `save_project {path: "cenas/effectcraft/<id>.ecproj"}` (o render exige
  projeto salvo);
- `renderQueue.add {comp, format: "h264", output:
  "cenas/planos/<id>-<n>.mp4"}`, depois `renderQueue.render {wait: true}`;
- `render_frame` no fim de cada plano salvo como `storyboard/<id>-<n>.png` e o
  começo da cena como `storyboard/inicio/<id>.png`;
- registre o clipe no `cenas/planos/indice.json` (`{"video": duração, "fala":
  fala}`), que o `planos.linha()` lê.

Apague o `<id>_RenderLog.txt` que o render deixa ao lado.

## Armadilhas

- Texto fora da área segura: confira os quadros com `margem.py`.
- Fonte só das instaladas ou da Library (`list_fonts`).
