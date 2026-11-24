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
trabalho e para em três pontos para o dono aprovar: direção e roteiro, rascunho
animado e corte final. Regras dos apps (formato nativo, `open_window`, lotes):
skill `artcraft`. Ferramentas e serviço: `docs/design.md` do dotfiles, seção
Video.

## A imagem explica, a voz acompanha

O vídeo não é slide narrado. Quem ensina é a imagem em movimento; a voz comenta o
que está acontecendo na tela. Regras:

- Cada conceito vira uma metáfora visual ou um mecanismo que se mexe (a CPU
  batendo na porta do dispositivo, um contador subindo, dados andando pelo
  barramento), nunca uma caixa com o nome do conceito.
- Teste do mudo: sem som, o vídeo ainda tem que dar a ideia. Se só a voz
  explica, o plano está errado.
- Texto na tela só para o termo-chave ou um número. Nunca escreva a frase que a
  voz está falando: texto e voz dizendo a mesma coisa atrapalham o aprendizado
  (princípio da redundância, Mayer).
- A imagem aparece quando a voz fala dela, não antes nem depois. Use cor e
  movimento para apontar onde olhar; o que não serve à ideia sai da tela.
- Algo muda na tela a cada 5 a 8 segundos (entra elemento, câmera aproxima,
  estado muda). Imagem parada com voz por cima perde a pessoa.

## Estrutura que prende

- **0 a 5 s:** imagem que intriga, sem logo nem saudação (a CPU parada,
  esperando uma tecla que não vem).
- **5 a 15 s:** a promessa concreta do vídeo ("em 3 minutos, as três formas de
  a CPU falar com o hardware e quando cada uma vale a pena").
- **até 30 s:** uma pergunta em aberto que o vídeo só responde mais adiante.
- **Meio:** cada bloco abre com uma pergunta ou um problema visível e fecha com a
  resposta na tela. Compare o novo com o anterior lado a lado quando der.
- **Fim:** resumo visual (as ideias lado a lado, na mesma metáfora do vídeo),
  não uma lista de frases. Sem "deixe seu like" e sem despedida longa.

## Pasta do vídeo

`~/Design/Videos/<slug>/`:

| Caminho | O quê |
|---|---|
| `video.md` | idioma, voz, identidade, música, duração alvo, fontes, pronúncia, etapa atual |
| `direcao.md` | metáfora central, mapa visual de cada conceito, arco do vídeo |
| `roteiro.md` | roteiro em duas colunas, plano por plano, cada um com a fonte |
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
   (veja Identidades); música (veja abaixo). Escreva `video.md`.
2. **Material.** Leia com `read` (PDF vem com `<!-- Page N -->`, que dá a
   página da citação). O vídeo diz o que o material diz e dá peso ao que ele
   enfatiza; o que vier de fora entra marcado como tal e só com o OK do dono. Se
   o material não tem texto legível (PDF escaneado), diga ao dono e leia as
   páginas como imagem ou use outra fonte que ele indicar; nunca escreva do
   conhecimento geral como se viesse do material.
3. **Direção** (`direcao.md`), antes de qualquer fala:
   - a pergunta que o vídeo responde e a promessa dos primeiros 15 segundos;
   - a metáfora central, que atravessa o vídeo inteiro (uma só, reaproveitada);
   - para cada conceito: como ele aparece e se mexe na tela, e que contraste
     com o conceito anterior a imagem mostra;
   - o arco: gancho, promessa, pergunta em aberto, blocos, resposta, resumo
     visual.
4. **Roteiro** (`roteiro.md`) em duas colunas, plano por plano, de 3 a 10
   segundos. Escreva primeiro a coluna da tela inteira; a fala vem depois, como
   comentário dela. Cada plano tem:

   | Campo | O quê |
   |---|---|
   | Tela | o que aparece e como se mexe: entrada, câmera, cor que chama o olho |
   | Fala | o texto exato, já com a pronúncia adaptada (veja Voz) |
   | Tom | curioso, firme, pausa antes do termo, ênfase numa palavra |
   | Tempo | duração alvo, em segundos |
   | Fonte | arquivo e página ou slide |

   Ritmo da fala: o Kokoro fala perto de 170 palavras por minuto. Motor de
   cada plano: Manim para mecanismo, diagrama, algoritmo e fórmula (sempre em
   Typst, nunca LaTeX nem `MathTex`); EffectCraft para título, cartão e
   tipografia animada. Algoritmo passo a passo vira um plano por passo.

   **Ponto 1: pare e mostre a direção e o roteiro.** Nada de narrar antes do OK.
5. **Narração.** Uma chamada `tts` por cena, sempre com `voice_id` (`pf_dora`
   em pt-BR, `af_heart` em inglês, ou a voz de `video.md`), saída
   `audio/<id>.wav`. Confira a pronúncia (veja Voz) e meça a duração com
   `ffprobe`. Narração vem antes da animação porque a cena tem o tamanho da fala.
6. **Rascunho animado.** Todas as cenas em baixa resolução (`manim -ql`), já no
   tempo da narração, montadas com a voz num `rascunho.mp4`. Confira quadros e
   margens antes. **Ponto 2: pare e mostre o rascunho.**
7. **Passada final** em 1920x1080 a 30 fps, cada cena do tamanho da sua
   narração; se a animação acaba antes, segure o último quadro.
8. **Montagem** no FilmCraft e exportação de `final.mp4`.
9. **Miniatura** no VectorCraft, 1280x720, no idioma do vídeo, a partir do
   modelo da identidade, exportada para `miniatura.png`.
10. **Ponto 3: corte final.** Informe duração, caminhos e o que você conferiu.

## Mudança pedida pelo dono

Volte só à etapa onde a mudança mora e refaça só o que ela atinge. Mudou uma
cena do roteiro: reescreva esse plano, deixe a direção e os outros como estão e
mostre o roteiro de novo. Mudou a narração de uma cena no corte final: nova
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

### Pronúncia

O Kokoro lê pela grafia portuguesa e não aceita fonema escrito (a sintaxe
`[palavra](/fonemas/)` sai como lixo em pt-BR). A fala vai escrita do jeito que
um brasileiro diz, e só a fala: na tela o termo aparece com a grafia certa.

- Termo em inglês continua em inglês, abrasileirado como se fala numa aula
  daqui: polling vira "pú-lin", buffer "bâfer", cache "quéche", driver
  "dráiver", heap "rípi". Não traduza o termo que a área usa em inglês.
- Sigla dita letra a letra vai soletrada em português: DMA vira "dê-éme-á",
  CPU "cê-pê-u", USB "u-ésse-bê". RAM não sai certo de jeito nenhum ("ram",
  "râm" e "rem" falharam): diga "memória principal".
- Cada vídeo tem uma tabela "Pronúncia" em `video.md` (termo, como escrever na
  fala, conferido sim ou não). Use a mesma grafia no vídeo todo.
- Confira cada termo novo antes de narrar o vídeo inteiro: gere uma frase curta,
  passe no Whisper local (se estiver no ar) e ouça; troque a grafia até soar
  certo. Whisper devolvendo a grafia original ("No DMA") é sinal de acerto.
  `curl -s "127.0.0.1:9000/asr?language=pt&output=txt" -F audio_file=@x.wav`

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

Margem de segurança: nada a menos de 10% da borda (no Manim, conteúdo dentro de
`x` entre -6,4 e 6,4 e `y` entre -3,6 e 3,6). O `tema.py` da identidade define
essa área (`AREA_SEGURA`, `encaixar(grupo)`); a cena encaixa o grupo nela em vez de posicionar perto da borda.
Prefira mexer a câmera (`MovingCameraScene`) para aproximar um detalhe a
encolher tudo para caber.

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
da tela ou a menos de 10% da borda, fala sem som ou estourada voltam para a
etapa antes de mostrar. Faça também o teste do mudo: olhe os quadros sem ler a
fala e veja se a ideia de cada cena aparece.

O dono pode pedir para ver uma cena no app a qualquer hora: salve e chame o
`open_window` do app (regras na skill `artcraft`).
