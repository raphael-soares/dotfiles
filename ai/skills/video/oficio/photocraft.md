# PhotoCraft

Imagem raster: texturas, fundo, tratamento de foto, composição para miniatura.

## Usos

- Textura do estilo (papel, grão, poeira), 1920x1080, a partir de
  `~/Creative/Library/textures/`; salva no estilo (`~/Creative/Styles/<nome>/`)
  ou na peça.
- Foto ou captura tratada para entrar numa cena (recorte, cor, contraste).
- Fundo ou elemento raster da miniatura.

## Jeito de trabalhar

Pelo MCP: `doc_new` ou `doc_open`, `command_list` para achar o comando,
`command_run`/`command_batch`, olhar com `render_preview`, `doc_save` (`.pcraft`
nativo; PNG, JPG e outros por extensão).

## Armadilhas

- Só aceita caminho dentro de `~/Creative`: arquivo de trabalho fica na peça, nunca
  em `/tmp`.
- Textura forte rouba a leitura: o FilmCraft sobrepõe em Sobreposição com
  opacidade baixa (perto de 35% para papel, 8% para grão).
