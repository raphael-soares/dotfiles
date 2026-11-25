# SoundCraft

Desenho de som e mixagem. O que soa em cada momento quem decide é a direção
(`repertorio/som.md`); aqui é como fazer.

## Jeito de trabalhar

Pelo MCP do SoundCraft, uma decisão por vez, ouvindo o resultado. Lote pelo CLI
só para o que é repetição sem escolha (pôr os 200 wavs de voz no lugar):

```bash
flatpak run --command=soundcraft-cli ai.storyteller.soundcraft script <arquivo.txt> \
  --save <abs>/audio/som.scraft --bounce <abs>/audio/mix.wav --end <segundos>
```

Uma linha por comando no arquivo: `<id> <json>`. Caminhos sempre absolutos (o
Flatpak não resolve relativos; `.resolve()` em Python). Arquivo de trabalho
fica dentro da pasta da peça, nunca em `/tmp`, que o Flatpak não enxerga.

## Sessão típica

1. `track.new {"rows": [{"name": "Voz", "format": "mono"}, {"name": "Efeitos",
   "format": "stereo"}, {"name": "Ambiente", "format": "stereo"}, {"name":
   "Saida", "kind": "master", "format": "stereo"}]}`; Música só se o dono pediu.
2. Voz: `file.import_audio {path, track: "Voz", at: {"seconds": t}, new_tracks:
   false}` com o `inicio` de cada plano vindo de `planos.linha()` (fala mais
   folga de cada plano anterior). Na trilha, `mix.insert` com `eq_1band`
   passa-alta em 80 Hz (`{"type": 3, "freq": 80}`) e `compressor`.
3. Efeitos: cada um posto à mão onde a direção pediu, com o motivo anotado em
   `som.md` da peça. `cenas/planos/<id>.eventos.json` lista quando cada animação
   acontece (plano e segundos dentro dele), para achar o momento; ele não diz
   que som pôr.
4. Ambiente: tom de sala da Biblioteca em loop (`clip.loop {fill: true}`), bem
   baixo (perto de -32 dB).
5. Música: `automation.write_range {track: "Musica", param: "volume", start,
   end, value}` abaixa nos trechos de fala (valor em dB).
6. Saída: `maximizer` na trilha master, teto -1,5 dB, para o pico não passar de
   -1 dBTP.
7. Medir: `ffmpeg -i mix.wav -af ebur128 -f null -` e acertar o ganho até -16
   LUFS integrado.

## Comandos que importam

`clip.gain {clips, db}`, `edit.fades_create {clip, side, length, shape}`,
`edit.trim_clip {clip, start, end}`, `mix.volume {tracks, db}`, `mix.pan`,
`mix.insert`/`mix.insert_params`, `mix.send` para um bus de reverb comum,
`markers.add` para marcar os momentos da direção, `file.bounce_mix {path,
format, bit_depth}`, `session.save`. Plugins internos úteis para voz e vídeo:
`eq_1band`, `eq_7band`, `compressor`, `de_esser`, `channel_strip`,
`maximizer`, `room_reverb`, `plate_reverb`, `mod_delay`, `saturator`, `lofi`,
`pitch_shifter`; a lista inteira em `engine.plugins`.

## Armadilhas

- Bounce sai em wav float: o Whisper não entende (converta para 16 kHz mono).
- Sem `maximizer` na saída, efeito empilhado sobre voz estoura o pico.
- Efeito em toda animação vira barulho: som é escolha, não carimbo.
