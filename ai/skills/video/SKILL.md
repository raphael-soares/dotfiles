---
name: video
description: >
  Use para fazer vídeo explicativo no PC fedora: aula a partir do material do
  dono em ~/Udesc, vídeo de YouTube, animação de algoritmo ou estrutura de
  dados, narração com voz sintética, miniatura; também para retomar ou mudar um
  vídeo em ~/Design/Videos.
---

# Vídeo explicativo

O dono não aparece no vídeo: nada de voz, rosto ou gravação dele. O vídeo é
gráfico e animação, com voz Kokoro local, em pt-BR ou inglês. O agente faz o
trabalho e para em três pontos para o dono aprovar: roteiro, storyboard e corte
final. Regras dos apps (formato nativo, `open_window`, lotes): skill `artcraft`.
Ferramentas e serviço: `docs/design.md` do dotfiles, seção Video.

## Pasta do vídeo

`~/Design/Videos/<slug>/`:

| Caminho | O quê |
|---|---|
| `video.md` | idioma, voz, identidade, música, duração alvo, fontes, etapa atual |
| `roteiro.md` | roteiro, cada seção com a fonte (arquivo e página ou slide) |
| `storyboard.md` | cenas em ordem: id, narração exata, o que se vê, motor, notas |
| `cenas/manim/<id>.py` | cena Manim |
| `cenas/effectcraft/<id>.ecproj` | cena EffectCraft |
| `cenas/render/<id>.mp4` | cena renderizada no tamanho da narração |
| `audio/<id>.wav` | narração da cena |
| `montagem.fcproj` | projeto do FilmCraft |
| `final.mp4` | exportação |
| `miniatura.vectorcraft`, `miniatura.png` | miniatura 1280x720 |

Atualize a etapa atual em `video.md` a cada passo: é por ela que um vídeo
parado se retoma.

## Fluxo

1. **Início.** Antes de ler ou escrever qualquer coisa, pergunte o que o dono
   não disse, um `ask` por pergunta: idioma; duração alvo; identidade visual
   (liste `~/Design/Identidades/` e ofereça criar uma nova); música (veja
   abaixo). Escreva `video.md`.
2. **Roteiro.** Leia o material com `read` (PDF vem com `<!-- Page N -->`, que
   dá a página da citação). Escreva no idioma do vídeo, em ritmo falado: 140
   palavras por minuto em pt-BR, 150 em inglês. Cada seção cita a fonte. O
   roteiro diz o que o material diz e dá peso ao que ele enfatiza; o que vier
   de fora do material entra marcado como tal e só com o OK do dono. Se o
   material não tem texto legível (PDF escaneado), diga ao dono e leia as
   páginas como imagem ou use outra fonte que ele indicar; nunca escreva do
   conhecimento geral como se viesse do material. **Ponto 1: pare e mostre o
   roteiro.**
3. **Storyboard.** Cenas de 5 a 30 segundos, cada uma com a narração exata, o
   que aparece e o motor:
   - **Manim:** algoritmo, estrutura de dados, diagrama, fórmula.
   - **EffectCraft:** abertura, título, cartão de seção, encerramento.
   - Algoritmo passo a passo vira uma cena curta por passo, para a voz falar
     do passo que está na tela.
   - Fórmula sempre em Typst, nunca LaTeX nem `MathTex`.
   - Termo em inglês dentro de narração em pt-BR vai escrito como se fala
     quando a voz erra (por exemplo, "ríp" para heap), e só na narração.

   **Ponto 2: pare e mostre o storyboard.** Nada de narrar ou renderizar antes
   do OK.
4. **Narração.** Uma chamada `tts` por cena, sempre com `voice_id` (`pf_dora`
   em pt-BR, `af_heart` em inglês, ou a voz de `video.md`), saída
   `audio/<id>.wav`. Meça a duração de cada uma com `ffprobe`. Narração vem
   antes da animação porque a cena tem o tamanho da fala.
5. **Cenas.** Rascunho primeiro, em baixa resolução; a passada final é 1920x1080
   a 30 fps. Cada cena dura o mesmo que a sua narração; se a animação acaba
   antes, segure o último quadro.
6. **Montagem** no FilmCraft e exportação de `final.mp4`.
7. **Miniatura** no VectorCraft, 1280x720, no idioma do vídeo, a partir do
   modelo da identidade, exportada para `miniatura.png`.
8. **Ponto 3: corte final.** Informe duração, caminhos e o que você conferiu.

## Mudança pedida pelo dono

Volte só à etapa onde a mudança mora e refaça só o que ela atinge. Mudou uma
cena do storyboard: reescreva essa cena, deixe roteiro e as outras como estão e
mostre o storyboard de novo. Mudou a narração de uma cena no corte final: nova
narração, nova renderização dessa cena e nova montagem; as outras cenas ficam.

## Voz

O Kokoro roda em `kokoro.service`, que não sobe sozinho. Antes de narrar:

```bash
systemctl --user start kokoro
timeout 600 bash -c 'until curl -sf 127.0.0.1:8880/v1/models >/dev/null; do sleep 3; done'
```

A primeira subida baixa a imagem e demora. Se o `tts` falhar com conexão
recusada, suba o serviço e tente de novo com a mesma voz. Nunca troque de voz,
modelo ou motor para contornar: a alternativa do omp só fala inglês. Se continuar
falhando, pare e conte ao dono o erro.

Grave `audio/duracoes.json` com a duração de cada narração (as cenas leem dele).
O Kokoro fala perto de 170 palavras por minuto, mais rápido que a estimativa do
roteiro. Sigla e palavra estrangeira saem erradas com frequência: escreva por
extenso ou como se fala ("entrada e saída", "píksel") e confira passando o
áudio no Whisper local, se estiver no ar:
`curl -s "127.0.0.1:9000/asr?language=pt&output=txt" -F audio_file=@x.wav`.

## Manim

Cenas importam a identidade por variável de ambiente: rode com
`VIDEO_DIR=<pasta do vídeo> IDENTIDADE=<pasta da identidade>` e, na cena,
`sys.path.insert(0, os.environ["IDENTIDADE"])` e `from tema import *`. Rascunho
com `manim -ql`; final com `manim -r 1920,1080 --fps 30` (o `-qh` sai a 60 fps).
Renderize com `--media_dir cenas/.manim --disable_caching` e copie o `.mp4` para
`cenas/render/<id>.mp4`. Renderizar em paralelo corrompe o cache de texto
(`ParseError: no element found`): rode de novo a cena que falhou, sozinha.

Tempo da cena: o `tema.py` lê `$VIDEO_DIR/audio/duracoes.json`; a cena usa
`self.t(fração)` para os `run_time` e termina com `self.fechar()`, que espera o
que falta para a duração da narração.

Emoji não renderiza em `Text`: desenhe ícones com formas (polígono, arco).
Texto sobre bloco de destaque usa a cor de texto clara, não a do fundo.

Fórmula em Typst:

```typst
#set page(width: auto, height: auto, margin: 4pt, fill: none)
#set text(fill: white, size: 28pt)
$ "FB"(n) = h_"esq" - h_"dir" $
```

`typst compile --format svg f.typ f.svg`, depois `SVGMobject("f.svg")` na cena.
Use a cor do texto que a identidade manda.

## EffectCraft

Sem janela, pelo MCP: `open_project {new: true}`, ou o `abertura.ecproj` da
identidade; `comp.new {name, width: 1920, height: 1080, frameRate: 30,
duration: <narração>}`; camadas; `save_project {path}` (o render exige projeto
salvo); `renderQueue.add {comp, format: "h264", output:
"cenas/render/<id>.mp4", timeSpan: "comp"}`; `renderQueue.render {wait: true}`.
Apague o `<id>_RenderLog.txt` que ele deixa ao lado.

## Montagem

FilmCraft sem janela: `file.newProject {}`; `media_import {paths}` com as cenas
e as narrações; `file.newSequence {name, width: 1920, height: 1080, fps: 30}`
(sem `fps` ele cria 23,976); `timeline.place {items: [cenas em ordem], track:
"V1", seconds: 0}`; cada narração com `timeline.place {item, track: "A1",
seconds: <início da cena>}` (início = soma das durações reais dos `.mp4`
anteriores); `file.exportMedia {path: "final.mp4", format: "h264",
loudnessLufs: -16, wait: true}`; `file.saveAs {path: "montagem.fcproj"}`. Corte
seco entre cenas, a não ser que a identidade diga outra coisa.

## Música

`~/Design/Videos/Musicas/` é a pasta de trilhas do dono. Com arquivos, pergunte
se este vídeo tem música e qual (ou se você escolhe uma que combine). Vazia,
pergunte se o vídeo terá música; se sim, o dono põe o arquivo lá. Com música,
mixe no SoundCraft (trilha abaixada enquanto a voz fala), exporte um `.wav` e
use-o no lugar das narrações na montagem.

## Identidades

`~/Design/Identidades/<nome>/` tem `identidade.md` (paleta, fontes, títulos,
legendas, transições), `tema.py` (os mesmos valores para o Manim),
`abertura.ecproj` e `miniatura.vectorcraft`.

A identidade se decide com o dono antes de qualquer cena, nunca por conta
própria. Primeiro um `ask`: usar uma existente (liste as da biblioteca) ou criar
uma nova. Nova: proponha paleta, fonte e tom num `ask` (cores em hex, uma
recomendação marcada) e espere o aval antes de escrever o `tema.py`. Depois
mostre um quadro e uma miniatura de exemplo e só salve na biblioteca com
aprovação.

## Antes de cada ponto de aprovação

Confira o resultado em vez de supor: extraia quadros das cenas
(`ffmpeg -ss <t> -i cena.mp4 -frames:v 1 q.png`) e olhe com `read`; confira a
duração das cenas contra as narrações e o volume com
`ffmpeg -i final.mp4 -af volumedetect -f null -`. Texto cortado, elemento fora
da tela, fala sem som ou estourada voltam para a etapa antes de mostrar.

O dono pode pedir para ver uma cena no app a qualquer hora: salve e chame o
`open_window` do app (regras na skill `artcraft`).
