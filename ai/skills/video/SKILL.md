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
gráfico e animação, com voz Kokoro local, em pt-BR ou inglês. O agente escreve
tudo sozinho, passa cada etapa por dois revisores cegos e para em quatro pontos
para o dono aprovar: briefing, animatic, rascunho animado e corte final. Regras
dos apps (formato nativo, `open_window`, lotes): skill `artcraft`. Ferramentas e
serviço: `docs/design.md` do dotfiles, seção Video. Manim: `manim.md` ao lado
deste arquivo.

## A imagem explica, a voz acompanha

O vídeo não é slide narrado. Quem ensina é a imagem em movimento; a voz comenta o
que está acontecendo na tela. Regras:

- Cada conceito vira uma metáfora visual ou um mecanismo que se mexe (a CPU
  batendo na porta do dispositivo, um contador subindo, dados andando por um
  fio), nunca uma caixa com o nome do conceito.
- Teste do mudo: sem som, o vídeo ainda tem que dar a ideia. Se só a voz
  explica, o plano está errado.
- Texto na tela só para o termo-chave ou um número. Nunca escreva a frase que a
  voz está falando: texto e voz dizendo a mesma coisa atrapalham o aprendizado
  (princípio da redundância, Mayer).
- A imagem aparece quando a voz fala dela, não antes nem depois. Use cor e
  movimento para apontar onde olhar; o que não serve à ideia sai da tela.
- Algo muda na tela a cada 5 a 8 segundos (entra elemento, câmera aproxima,
  estado muda). Imagem parada com voz por cima perde a pessoa.

## Quem chega de paraquedas

Todo vídeo é escrito para quem caiu nele sem ter visto a aula, sem saber o
assunto e sem ninguém do lado para perguntar. O autor sabe demais e não enxerga
onde essa pessoa se perde; por isso o espectador cego revisa cada etapa.

- **Situe antes de nomear.** O vídeo começa no mundo que a pessoa já conhece (o
  "Já sabe" do briefing) e só depois entra no assunto.
- **Mostre, nomeie, use.** Um termo aparece primeiro como coisa na tela, ganha o
  nome enquanto está sendo mostrado e só então pode ser usado na fala ou num
  rótulo. Rótulo numa peça que ninguém explicou é termo antes da hora.
- **Cada bloco diz por que vem agora.** Os blocos se ligam com "mas" e "então"
  (o problema que o anterior deixou), não com "e depois".
- **A ideia errada vem primeiro.** Quando o briefing lista uma ideia errada
  comum, o vídeo a mostra e a desmonta na tela. Demonstração bonita que não
  confronta a ideia errada deixa a pessoa com ela.
- **Palpite antes da revelação.** Antes de mostrar o resultado, a voz pede um
  palpite ("o que você acha que acontece?") e a tela espera um respiro.
- **Um conceito novo a cada 30 a 45 segundos**, no máximo.

## Estrutura que prende

- **0 a 5 s:** imagem que intriga, sem logo nem saudação, feita de coisas que a
  pessoa já conhece (a CPU parada, esperando uma tecla que não vem).
- **5 a 15 s:** a promessa concreta, nas palavras de quem ainda não sabe o
  assunto ("como algo tão rápido conversa com algo tão lento"), sem a lista dos
  termos que o vídeo vai ensinar.
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
| `briefing.md` | quem assiste e o que já sabe, a ideia que fica, objetivos, quiz com gabarito, ideias erradas |
| `direcao.md` | metáfora central, mapa visual de cada conceito, mapa de termos, arco do vídeo |
| `roteiro.md` | roteiro em duas colunas, plano por plano, cada um com a fonte |
| `audio/planos/<id>-<n>.wav`, `audio/<id>.wav`, `audio/duracoes.json` | narração por plano, por cena e as durações |
| `storyboard/<id>-<n>.png`, `storyboard/inicio/<id>.png` | pose final de cada plano e a abertura de cada cena |
| `animatic.mp4` | os quadros do storyboard no tempo da narração, com a voz |
| `rascunho.mp4` | as cenas do rascunho animado montadas com a voz |
| `revisao/<etapa>-<k>/entrada/` | o que o revisor recebeu na rodada `k` |
| `revisao/<etapa>-<k>.md` | relatório do revisor e o que o autor fez com cada achado |
| `cenas/manim/<id>.py`, `cenas/manim/palco.py` | cenas Manim e os construtores compartilhados do vídeo |
| `cenas/effectcraft/<id>.ecproj` | cena EffectCraft |
| `cenas/render/<id>.mp4` | cena renderizada no tamanho da narração |
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
3. **Briefing** (`briefing.md`, formato abaixo). Quem assiste é a pessoa de
   paraquedas: o "Já sabe" lista só o que ela traz de fora do assunto. Três a
   cinco objetivos escritos como "depois do vídeo, a pessoa consegue...", um
   quiz de uma pergunta por objetivo, com gabarito, e as ideias erradas comuns
   sobre o tema. **Ponto 1: pare e mostre o briefing.**
4. **Direção** (`direcao.md`), antes de qualquer fala:
   - a pergunta que o vídeo responde e a promessa dos primeiros 15 segundos;
   - a abertura que situa a pessoa antes de nomear qualquer coisa;
   - a metáfora central, que atravessa o vídeo inteiro (uma só, reaproveitada);
   - para cada conceito: como ele aparece e se mexe na tela, e que contraste
     com o conceito anterior a imagem mostra;
   - a ideia errada que o vídeo confronta e onde;
   - os momentos de palpite antes da revelação;
   - o arco: gancho, promessa, pergunta em aberto, blocos ligados por "mas" e
     "então", resposta, resumo visual;
   - as cores: um sentido por cor no vídeo inteiro. Se a fala vai nomear uma
     cor ("a parte laranja"), a direção fixa qual cor e o que ela quer dizer,
     porque trocar depois é regravar a narração. Medidor e gráfico têm título
     neutro ("tempo da CPU") e legenda com amostra de cada cor;
   - os objetos que voltam (aparelho, ícone, personagem): o mesmo desenho e o
     mesmo tamanho em todas as cenas, e o que sai de uma cena sai à vista no
     começo da seguinte;
   - o mapa de termos (formato abaixo).
5. **Roteiro** (`roteiro.md`) em duas colunas, plano por plano, de 3 a 10
   segundos. Escreva primeiro a coluna da tela inteira; a fala vem depois, como
   comentário dela. Cada plano tem:

   | Campo | O quê |
   |---|---|
   | Tela | o que aparece e como se mexe: entrada, câmera, cor que chama o olho |
   | Fala | o texto exato, já com a pronúncia adaptada (veja Voz) |
   | Tom | curioso, firme, pausa antes do termo, ênfase numa palavra; "pausa" pede respiro no fim do plano |
   | Tempo | duração alvo, em segundos |
   | Fonte | arquivo e página ou slide |

   Ritmo da fala: o Kokoro fala perto de 170 palavras por minuto. Motor de
   cada plano: Manim para mecanismo, diagrama, algoritmo e fórmula (sempre em
   Typst, nunca LaTeX nem `MathTex`); EffectCraft para título, cartão e
   tipografia animada. Algoritmo passo a passo vira um plano por passo.

   Confira o roteiro contra o mapa de termos, plano por plano, e corrija os dois
   até baterem. Palavra técnica do dia a dia de quem faz o vídeo também é termo:
   "chip", "tempo real", "KB", "sistema operacional" entram no mapa, a não ser
   que estejam no "Já sabe". Plano de pergunta mostra a pergunta na tela (um "?"
   âmbar onde está a dúvida) e, se o vídeo apresentou dois cenários, diz em qual
   a pergunta vale. Todo termo nomeado ganha um uso na tela (duas instruções
   apresentadas, duas setas). Quantidade desenhada bate com o número dito: 64 KB
   em pedaços de 4 KB são 16 blocos contra 1, não 16 contra 4. Quando o vídeo
   mostra dois jeitos e segue com um, a fala diz qual ("daqui em diante..."),
   nunca "tanto faz". Palavra que não é assunto da aula sai pela do "Já sabe"
   ("programa", não "software"). Depois, **rodada do espectador no roteiro**
   (veja Revisores).
6. **Narração** por plano (veja Voz). Ela vem antes do storyboard porque o
   animatic e as cenas têm o tamanho da fala.
7. **Storyboard.** Escreva cada cena em `cenas/manim/<id>.py` chegando na pose
   final de cada plano, com movimento simples, e renderize com `-s`: sai um
   quadro por plano em `storyboard/` e o quadro de abertura da cena em
   `storyboard/inicio/` (veja `manim.md`, Tempo e poses). Cena EffectCraft:
   exporte o quadro do fim de cada plano com o mesmo nome e o do começo em
   `storyboard/inicio/<id>.png`. Rode `python3
   ~/.omp/agent/skills/video/margem.py <pasta>`, que lista cada quadro a menos
   de 10% da borda e o lado; corrija até ele dizer `margem ok`. O quadro do fim
   do plano é o que os revisores veem: a ideia do plano, sobretudo o que a fala
   diz por último, fica na tela até o plano acabar, nunca some antes dele (o
   dado perdido ganha o estouro e a legenda; a espera pelo barramento fica
   desenhada). Olhe os quadros e depois faça a **rodada do crítico no
   storyboard**.
8. **Animatic.** `python3 ~/.omp/agent/skills/video/animatic.py <pasta>` gera
   `animatic.mp4` (480p, cada quadro pelo tempo da fala do seu plano, com a voz).
   Assista; depois **rodada do espectador no animatic**. **Ponto 2: pare e
   mostre o animatic, com `direcao.md` e `roteiro.md`.** O OK trava a história,
   a ordem dos planos e o tempo (veja Mudança pedida pelo dono).
9. **Rascunho animado.** Agora o movimento: cada plano leva da pose anterior à
   próxima, seguindo `manim.md`, Movimento. As poses aprovadas não mudam. Todas
   as cenas em baixa resolução (`manim -ql`), em `cenas/render/`, uma por vez.
   `python3 ~/.omp/agent/skills/video/rascunho.py <pasta>` junta cada cena com
   a sua fala, segurando o último quadro até a fala acabar, e monta o
   `rascunho.mp4`. Não concatene vídeo e áudio em duas trilhas separadas: a 15
   fps cada cena sai até 65 ms mais curta que a fala, e a voz atrasa quase um
   segundo no fim. **Rodada do crítico e do espectador no rascunho.** **Ponto 3:
   pare e mostre o rascunho.**
10. **Passada final** em 1920x1080 a 30 fps, cada cena do tamanho da sua
    narração; se a animação acaba antes, segure o último quadro: `ffmpeg -i
    <render> -vf "tpad=stop_mode=clone:stop_duration=2,format=yuv420p"
    -frames:v <teto(duração do wav x 30)> -r 30 -c:v libx264 -crf 18
    cenas/render/<id>.mp4`. **Montagem** no
    FilmCraft e exportação de `final.mp4`. **Miniatura** no VectorCraft,
    1280x720, no idioma do vídeo, com o fundo e as cores da identidade e o
    estilo de miniatura do YouTube (referência do dono: Fireship): duas ou três
    palavras em peso Black, cada uma na cor do que significa, e uma imagem
    grande ao lado que quem nunca viu o vídeo entende: objetos conhecidos numa
    situação (o chip que pergunta ao disco "já terminou?"), nunca um gráfico ou
    medidor que só faz sentido depois de assistir. A imagem é grande e vaza um
    pouco pela borda (direita ou de baixo), o que dá profundidade; texto e
    balões ficam dentro dos 10%, conferidos pelos `bounds` do
    `inspect_document` (o `margem.py` acusaria o vazamento). Não repita o
    título, que o YouTube já mostra ao lado; nada de cartão de título com
    subtítulo. Confira reduzida a 168 px de largura (a lista lateral): o
    essencial ainda se lê. Exporte para `miniatura.png`.
    **Ponto 4: corte final.** Informe duração, caminhos e o que você conferiu.

### Formato do briefing

```markdown
# Briefing

## Quem assiste
<uma frase: quem é e de onde chega>
Já sabe:
- ...
Não sabe:
- ...

## A ideia que fica
<uma frase>

## Objetivos
1. Depois do vídeo, a pessoa consegue ...

## Quiz
1. <pergunta>
   Resposta: <gabarito, em linhas indentadas abaixo da pergunta>

## Ideias erradas
- ...
```

Os títulos das seções são lidos pelo `revisao.py`: mantenha-os. Cada pergunta
cabe numa linha só, começando por `1.`, `2.` na margem; só essa linha sai para
o revisor, e o que estiver indentado abaixo dela fica.

### Mapa de termos

Em `direcao.md`, um termo por linha, na ordem em que aparecem:

| Termo | Mostrado em | Nomeado em | Primeiro uso |
|---|---|---|---|
| barramento | 01-gancho#3 | 01-gancho#3 | 03-controlador#1 |

"Mostrado" é o plano em que ele aparece como coisa na tela; "nomeado", o plano
em que ganha o nome enquanto é mostrado; "primeiro uso", o primeiro plano em que
a fala ou um rótulo conta com ele. O primeiro uso nunca vem antes dos outros
dois. Termo do "Já sabe" do briefing não entra.

## Revisores

Dois agentes sem contexto revisam as etapas. Eles nunca veem o material, o
briefing inteiro, a direção nem o gabarito: o valor deles é não saber.

| Rodada | Agente | `etapa` |
|---|---|---|
| roteiro | `video-espectador` | `roteiro` |
| storyboard | `video-critico` | `storyboard` |
| animatic | `video-espectador` | `animatic` |
| rascunho | `video-critico` e `video-espectador` | `rascunho` |

Para cada rodada:

1. Prepare a entrada: `python3 ~/.omp/agent/skills/video/revisao.py <pasta>
   <etapa>`. Ele monta só o que o revisor pode ver, guarda uma cópia em
   `revisao/<etapa>-<k>/entrada/` como registro e imprime o caminho de outra
   cópia, numa pasta temporária fora do vídeo (assim o revisor não chega no
   briefing nem no nome do vídeo). Arquivo faltando (quadro, render, briefing),
   render mais curto que a narração ou tabela torta param tudo e dizem o quê.
2. Chame o agente com `task`, `agent: video-espectador` ou `video-critico`, e
   na tarefa só `Pasta: <caminho impresso>`. Nada de resumo, contexto ou dica:
   qualquer coisa a mais acaba com a cegueira. No rascunho os dois agentes
   recebem a mesma pasta.
3. Escreva `revisao/<etapa>-<k>.md`: o relatório do revisor, a correção do quiz
   contra o gabarito (espectador) e os achados numa tabela `| Plano | Achado |
   Decisão |`, com a decisão começando por "corrigido" (onde) ou "rejeitado"
   (por quê). Achado não some: o que você rejeitar fica com o motivo. Escreva
   o motivo completo, sem "pelo motivo da rodada 1": o `revisao.py` passa ao
   crítico da rodada seguinte só as linhas rejeitadas (`rejeitados.md`), para
   ele não repetir o que já foi recusado.
4. A rodada passa quando o crítico não aponta nada grave, ou quando o
   espectador acerta o quiz inteiro e não marca "não" em "Mostrado antes?" nem
   em "Nomeado antes?". Achado leve se corrige ou se rejeita com motivo e não
   pede rodada nova. Não passou: corrija tudo e rode uma rodada nova, que
   confere as correções.
5. Três rodadas sem passar: pare nessa etapa, não construa a seguinte em cima
   dela. Mostre ao dono os achados em aberto num `ask` e siga o que ele decidir.

No espectador, um "não" em "Mostrado antes?" ou "Nomeado antes?" é termo antes
da hora: corrija o roteiro (mostre e nomeie antes) e o mapa de termos.

## Mudança pedida pelo dono

Volte só à etapa onde a mudança mora e refaça só o que ela atinge. Mudou uma
cena do roteiro: reescreva esse plano, deixe a direção e os outros como estão e
mostre o roteiro de novo.

Depois do Ponto 2 ficam travados a lista de planos e o `audio/duracoes.json`
medido para o animatic, pausas incluídas. Mudança de tempo é fala reescrita,
plano novo, plano tirado ou ordem trocada: volta ao storyboard e ao animatic das
cenas atingidas, com a rodada do espectador, e o dono vê o animatic delas de
novo. Animação que sobra ou falta não é mudança de tempo: a cena continua com o
tamanho da fala (`fechar()`). Mudar só o movimento ou o acabamento fica na etapa
em que está. Mudou a narração de uma cena no corte final: nova narração, nova
renderização dessa cena e nova montagem; as outras cenas ficam.

Vídeo que já tinha passado do antigo Ponto 1 (direção e roteiro) antes deste
fluxo termina no fluxo antigo, a não ser que o dono peça para refazer a
pré-produção.

## Voz

O Kokoro roda em `kokoro.service`, que não sobe sozinho. Antes de narrar:

```bash
systemctl --user start kokoro
timeout 600 bash -c 'until curl -sf 127.0.0.1:8880/v1/models >/dev/null; do sleep 3; done'
```

A primeira subida baixa a imagem e demora. Se o `narrar.py` disser que o Kokoro
não respondeu, suba o serviço e rode de novo. Nunca troque de voz, modelo ou
motor para contornar. Se continuar falhando, pare e conte ao dono o erro.

Narre com `python3 ~/.omp/agent/skills/video/narrar.py <pasta> [cena...]`. Ele
chama o Kokoro direto (`KOKORO_URL`, padrão `http://127.0.0.1:8880`) com a voz
da linha `- Voz:` do `video.md` (`pf_dora` em pt-BR, `af_heart` em inglês),
grava cada plano em `audio/planos/<id>-<n>.wav`, estica 0,8 s o plano com
"pausa" no Tom, junta a cena em `audio/<id>.wav` e regrava em
`audio/duracoes.json` a duração de cada cena (`<id>`) e de cada plano
(`<id>#planos`), que as cenas e o `animatic.py` leem. Avisa o plano cuja fala
passa 2,5 s do Tempo do roteiro: encurte a fala ou ajuste o Tempo. Sem cena,
narra tudo; com cenas, só elas, e as outras ficam como estão. O Kokoro dá o
mesmo áudio para o mesmo texto, então renarrar uma cena só muda os planos cuja
fala mudou. Não use a ferramenta `tts` do omp: ela depende de um modelo de fala
configurado no omp e já falhou com "No available speech model matches the
speech role". Respiro no fim da cena (o dono pode pedir): estique o `.wav` da
cena com `apad=whole_dur=<total>` e grave o total novo em `<id>`, sem mexer nos
planos. Depois do Ponto 2 isso é mudança de tempo.

### Pronúncia

O Kokoro lê pela grafia portuguesa e não aceita fonema escrito (a sintaxe
`[palavra](/fonemas/)` sai como lixo em pt-BR). A fala vai escrita do jeito que
um brasileiro diz, e só a fala: na tela o termo aparece com a grafia certa.

- Termo em inglês continua em inglês, abrasileirado como se fala numa aula
  daqui: polling vira "púlin" (com hífen, "pú-lin", saiu "Pool Lane"), buffer
  "bâfer", cache "quéche", driver "dráiver", heap "rípi". Não traduza o termo que
  a área usa em inglês.
- Sigla dita letra a letra vai soletrada em português: DMA vira "dê-éme-á",
  CPU "cê-pê-u", USB "u-ésse-bê". RAM não sai certo de jeito nenhum ("ram",
  "râm" e "rem" falharam): diga "memória principal".
- Cada vídeo tem uma tabela "Pronúncia" em `video.md` (termo, como escrever na
  fala, conferido sim ou não). Use a mesma grafia no vídeo todo.
- Confira cada termo novo antes de narrar o vídeo inteiro: gere uma frase curta,
  passe no Whisper local (se estiver no ar) e ouça; troque a grafia até soar
  certo. Whisper devolvendo a grafia original ("No DMA") é sinal de acerto.
  `curl -s "127.0.0.1:9000/asr?language=pt&output=txt" -F audio_file=@x.wav`

## EffectCraft

Sem janela, pelo MCP: `open_project {new: true}`, ou o `abertura.ecproj` da
identidade; `comp.new {name, width: 1920, height: 1080, frameRate: 30,
duration: <narração>}`; camadas; `save_project {path}` (o render exige projeto
salvo); `renderQueue.add {comp, format: "h264", output:
"cenas/render/<id>.mp4", timeSpan: "comp"}`; `renderQueue.render {wait: true}`.
Apague o `<id>_RenderLog.txt` que ele deixa ao lado. Quadro do storyboard:
`render_frame` no fim de cada plano, salvo como `storyboard/<id>-<n>.png`.

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
legendas, transições), `tema.py` (os mesmos valores para o Manim, com o `Cena`
que mede o tempo e grava as poses), `abertura-modelo.ecproj` e
`miniatura-modelo.vectorcraft` (fundo, cores e fontes da miniatura).

A identidade se decide com o dono antes de qualquer cena, nunca por conta
própria. Primeiro um `ask`: usar uma existente (liste as da biblioteca) ou criar
uma nova. Nova: proponha paleta, fonte e tom num `ask` (cores em hex, uma
recomendação marcada) e espere o aval antes de escrever o `tema.py`, copiando o
`Cena` de uma identidade existente. Depois mostre um quadro e uma miniatura de
exemplo e só salve na biblioteca com aprovação.

## Antes de cada ponto de aprovação

Confira o resultado em vez de supor: extraia quadros das cenas
(`ffmpeg -ss <t> -i cena.mp4 -frames:v 1 q.png`) e olhe com `read`. Para o vídeo
inteiro, uma folha de contato mostra tudo de uma vez: `ffmpeg -i rascunho.mp4
-vf "fps=1/3.5,scale=427:240,tile=4x5" folha%d.png`. Os quadros extraídos
passam pelo `margem.py` (aceita pastas e arquivos `.png`). Confira a
duração das cenas contra as narrações e o volume com
`ffmpeg -i final.mp4 -af volumedetect -f null -`. Texto cortado, elemento fora
da tela ou a menos de 10% da borda, fala sem som ou estourada voltam para a
etapa antes de mostrar.

Em todo ponto, mostre ao dono o resultado das rodadas desde o ponto anterior:
quantas rodadas cada revisor fez, o que foi corrigido e cada achado rejeitado
com o motivo.

O dono pode pedir para ver uma cena no app a qualquer hora: salve e chame o
`open_window` do app (regras na skill `artcraft`).
