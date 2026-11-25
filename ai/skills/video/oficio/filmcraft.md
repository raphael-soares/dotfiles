# FilmCraft

Edição: corte, ritmo, acabamento, legenda e exportação. As escolhas de edição
vêm da direção (`repertorio/edicao.md`).

## Jeito de trabalhar

Pelo MCP do FilmCraft, olhando o resultado com `render_preview` nos pontos que
importam. O dono pode acompanhar com `open_window` (regras da skill
`artcraft`). Lote pelo CLI só para repetição sem escolha (pôr 200 clipes em
fila):

```bash
flatpak run --command=filmcraft-cli ai.storyteller.filmcraft --project corte.fcproj --save --compact run x.jsonl
```

Uma linha JSON por comando: `{"id": ..., "params": {...}}`. `--save-as` para
criar o projeto. Tempo em ticks (254016000000 por segundo) ou `{"frame": n}`,
`{"seconds": f}`.

## Montagem típica

1. `file.newProject`, `file.newSequence {name, fps: 30, width: 1920, height:
   1080, video: 3, audio: 1}`.
2. `file.import {paths}`: os ids dos itens saem em sequência, na ordem dos
   caminhos.
3. V1: clipe de cada plano (`cenas/planos/<id>-<n>.mp4`) com
   `timeline.place {item, track: "V1", frame, duration: {"frame": n}, audio:
   false}`. A duração é decisão de edição: a fala inteira mais o respiro que o
   momento pede (o clipe traz até `FOLGA` segundos sobrando).
4. Acabamento quando a direção pede: textura do estilo em V2 e grão em V3, com
   `effects.setParam {clip, effect: "opacity", param: "blend", value:
   "Overlay"}` e `param: "opacity"`.
5. A1: `mix.wav` do SoundCraft.
6. Transições só onde a direção pede: `sequence.applyVideoTransition {clip,
   effect: "cross_dissolve", frames}`.
7. Legenda: escreva o SRT com blocos alinhados ao quadro e importe com
   `captions.import {path, name, language}`; estilo com `captions.setStyle`.
8. `file.save`, depois `file.exportMedia {path, format: "h264", width: 1920,
   height: 1080, fps: 30, audioCodec: "aac", crf: 18, bitrateMode: "crf"}`.
9. Grave `corte-1.json` ao lado, `{"<cena>-<n>": fim do plano em segundos}`,
   tirado de `sequence_inspect` (início mais duração de cada clipe em V1): é
   dele que `revisao.py <pasta> corte` tira os quadros do espectador.

## Comandos que importam

`timeline.trim`, `timeline.razor`, `timeline.move`, `timeline.slip`,
`effects.apply`, `effects.setParam`, `effects.setKeyframe` (zoom e movimento de
câmera em `motion`), `sequence.applyAudioTransition`, `render_frame`.

## Armadilhas

- `captions.add` recusa legenda que encosta na anterior ("a caption already
  covers this time"): gere o SRT e use `captions.import`.
- Exportar 21 minutos leva perto de 35 minutos: rode em segundo plano.
- Confira a duração exportada contra a soma da linha do tempo (`ffprobe`).
