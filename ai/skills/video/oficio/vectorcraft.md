# VectorCraft

Desenho: objetos que voltam no vídeo, personagens, folha de referência do
estilo, miniatura.

## Objetos que voltam

Objeto que aparece em várias cenas (aparelho, personagem, ícone) é desenhado
uma vez, com as cores do estilo, e salvo como `arte/<nome>.svg` na raiz do
projeto (comum a todas as peças) ou na peça. As cenas carregam o SVG
(`SVGMobject` no Manim, `file.import` no EffectCraft); nunca redesenhe em
código o que já está desenhado.

Pelo MCP: `draw_shape`, `draw_path`, `add_text`, `set_paint`, `transform`,
`pathfinder`; olhe com `render_preview`; `export {format: "svg"}`. Ilustração
de terceiros vem da Biblioteca (`ilustracoes/`, `icones/`), com a licença do
`FONTES.md`.

## Folha de referência

Esboço da etapa de direção: um quadro 1920x1080 com paleta, tipografia, dois ou
três objetos do vídeo e um quadro de exemplo. Salve como
`direcao/referencia.vectorcraft` e exporte PNG para o dono ver.

## Miniatura

1280x720, `miniatura.vectorcraft` e `miniatura.png` na peça. O estilo vem da
direção (`repertorio/miniatura-e-titulo.md`). Texto dentro dos 10%, conferido
pelos `bounds` do `inspect_document`; confira reduzida a 168 px de largura.

## Armadilhas

- Texto continua texto: não converta em contorno sem pedido.
- Salve no nativo; SVG e PNG são exportação ao lado.
