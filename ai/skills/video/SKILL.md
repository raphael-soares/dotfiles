---
name: video
description: >
  Use para fazer vídeo explicativo no PC fedora: aula a partir do material do
  dono em ~/Documents/Udesc, vídeo de YouTube, animação de algoritmo ou estrutura de
  dados, narração com voz sintética, miniatura; também para retomar ou mudar um
  vídeo em ~/Creative/Projetos.
---

# Vídeo explicativo

O dono encomenda e aprova; você produz, como um produtor faria. Cada etapa
termina num esboço que o dono vê, e a seguinte só começa com o OK dele. Nada
aqui é fórmula: a direção de cada vídeo escolhe, no repertório, o que serve
àquele vídeo e diz por quê.

O dono não aparece no vídeo (nem voz, nem rosto). O vídeo é gráfico e animação
com voz OmniVoice local, em pt-BR ou inglês.

| Onde | O quê |
|---|---|
| `repertorio/README.md` | técnicas consolidadas, por situação, com quando usar e quando evitar |
| `oficio/<app>.md` | como trabalhar em cada ferramenta: Manim, EffectCraft, FilmCraft, SoundCraft, VectorCraft, PhotoCraft, voz |
| skill `artcraft` | regras dos apps (formato nativo, `open_window`, lotes) |
| `docs/creative.md` do dotfiles, seção Video | serviços e ferramentas instalados |

## Etapas

1. **Conversa inicial.** Tema, material, objetivo, público, duração, idioma,
   estilo, se tem música. O que o dono não disse, um `ask` por pergunta.
   Escreva `video.md`.
2. **Briefing** (`briefing.md`). Quem assiste e o que já sabe, a ideia que
   fica, objetivos, ideias erradas comuns; quiz com gabarito só se a direção
   for de aula. O vídeo diz o que o material diz: leia com `read` (PDF traz
   `<!-- Page N -->` para a citação); o que vier de fora entra marcado e só com
   o OK do dono. Material sem texto legível: avise e leia as páginas como
   imagem. *Esboço: o briefing.*
3. **Direção** (`direcao.md`, seção abaixo). *Esboço: `direcao.md` e uma folha
   de referência do estilo (`oficio/vectorcraft.md`) antes de animar.*
4. **Roteiro** (`roteiro.md`). Plano por plano, de 3 a 10 segundos, colunas
   Tela, Fala, Tom, Tempo, Fonte. Escreva a Tela inteira primeiro; a Fala vem
   depois, como comentário dela, escrita para o ouvido (`repertorio/fala.md`).
   A voz fala perto de 170 palavras por minuto. Rodada do espectador. Narre
   duas ou três cenas (`oficio/voz.md`). *Esboço: o roteiro e a amostra
   narrada.* O OK trava o texto: daqui em diante a fala só muda por achado do
   dono ou do espectador, e cada mudança se narra de novo antes de animar.
5. **Narração, storyboard e animatic.** Narre tudo e rode o `ouvir.py`
   (`oficio/voz.md#conferir`); os planos que sobrarem vão para o dono ouvir.
   Storyboard: o quadro do fim de cada plano em `storyboard/<id>-<n>.png`
   e o começo de cada cena em `storyboard/inicio/<id>.png`, feitos no motor que
   a direção escolheu; `margem.py` até `margem ok`. Rodada do crítico.
   `animatic.py <pasta>` monta `animatic.mp4` no tempo da voz; rodada do
   espectador. *Esboço: o animatic.* O OK trava a lista de planos e o tempo:
   nada se anima antes dele, e cada plano se anima uma vez, já na duração da
   sua fala.
6. **Rascunho animado.** O movimento de pose a pose, em baixa resolução (no
   Manim, `PLANOS=0`, `oficio/manim.md`); `rascunho.py <pasta>` junta cada cena
   com a sua fala. Rodadas do crítico e do espectador. *Esboço:
   `rascunho.mp4`.*
7. **Primeiro corte.** Passada final por plano: `planos.py` no Manim (zero
   `estourou`, `fonte pequena` e `CURTO`), o mesmo formato nos outros motores;
   `conferir.py` para as folhas. Som no SoundCraft e edição no FilmCraft,
   feitos à mão pelo MCP, cada escolha vinda da direção
   (`oficio/soundcraft.md`, `oficio/filmcraft.md`); o motivo de cada efeito
   sonoro em `som.md` da peça. Rodada do espectador no corte. *Esboço:
   `corte-1.mp4`; ofereça abrir o FilmCraft no projeto (`open_window`).*
8. **Corte final e miniatura.** Ajustes do dono, `final.mp4` e `final.srt`,
   miniatura (`oficio/vectorcraft.md`). Informe duração, caminhos e o que você
   conferiu. Aprovado, apague o que se regenera: `cenas/.manim*`, os
   `__pycache__`, versões de comparação e cópias `*.conflictN` do syncfast que
   forem versões antigas suas.

Atualize a etapa atual em `video.md` a cada passo: é por ela que um vídeo
parado se retoma.

Cronometre cada etapa: anote em `video.md`, numa tabela "Tempos", o início e o
fim de cada uma (`date`), separando o tempo de máquina (voz, render), o seu e
a espera pelo dono. É assim que se sabe onde o tempo vai.

Em todo esboço, mostre o resultado das rodadas desde o anterior: quantas
rodadas cada revisor fez, o que foi corrigido e cada achado rejeitado com o
motivo.

## Direção

`direcao.md` é o plano do vídeo e responde, citando as entradas do repertório
(`repertorio/<arquivo>.md#<nome>`):

- formato e tom;
- estrutura e arco, com o gancho, os laços abertos e onde a atenção é
  retomada;
- para cada bloco: o que a tela faz, com que técnica e com que motor (Manim,
  EffectCraft, imagem, VectorCraft); Manim só com o motivo dito
  (`oficio/manim.md#Quando usar`), nunca por hábito;
- estilo visual: o estilo de `~/Creative/Estilos/` usado, adaptado ou novo;
  paleta e o sentido de cada cor; tipografia; objetos que voltam; textura;
- voz: tom, ritmo, onde entram pausas;
- som: ambiente, que momentos ganham efeito e por quê, música (só se o dono
  pediu) e onde ela abaixa;
- edição: ritmo de corte, transições, respiros, aproximações, legenda;
- miniatura e título.

O que a direção não tira do repertório, ela justifica. Na estrutura de aula,
ela leva também o mapa de termos (abaixo).

Estilo novo se decide com o dono: proponha paleta, fonte e tom num `ask` (cores
em hex, uma recomendação marcada), mostre um quadro e uma miniatura de exemplo
e só salve em `~/Creative/Estilos/<nome>/` com aprovação.

### Mapa de termos

Só quando a direção adota a estrutura de aula. Um termo por linha, na ordem em
que aparecem:

| Termo | Mostrado em | Nomeado em | Primeiro uso |
|---|---|---|---|
| barramento | 01-gancho#3 | 01-gancho#3 | 03-controlador#1 |

"Mostrado" é o plano em que ele aparece como coisa na tela; "nomeado", o plano
em que ganha o nome enquanto é mostrado; "primeiro uso", o primeiro plano em que
a fala ou um rótulo conta com ele. O primeiro uso nunca vem antes dos outros
dois. Termo do "Já sabe" do briefing não entra; palavra técnica do dia a dia
de quem faz o vídeo ("chip", "KB") entra.

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

O `revisao.py` lê esses títulos. `## Quiz` é opcional: sem ele, o espectador
não recebe quiz. Cada pergunta cabe numa linha começando por `1.`, `2.` na
margem; o indentado abaixo dela não sai para o revisor.

## Peça

Cada vídeo é uma peça em `~/Creative/Projetos/<projeto>/<peça>/`. O que é comum a
várias peças de um projeto (kit de cenas, `arte/`, contrato) fica em
`~/Creative/Projetos/<projeto>/kit/`. Estilos reaproveitáveis ficam em
`~/Creative/Estilos/<nome>/`; o que acabou vai para `~/Creative/0-Archive/`.

| Caminho | O quê |
|---|---|
| `video.md` | idioma, voz, estilo, música, duração alvo, fontes, pronúncia, etapa atual |
| `briefing.md`, `direcao.md`, `roteiro.md` | pré-produção |
| `audio/planos/<id>-<n>.wav`, `audio/<id>.wav`, `audio/duracoes.json` | narração por plano, por cena e as durações |
| `storyboard/`, `animatic.mp4`, `rascunho.mp4` | esboços das etapas 5 e 6 |
| `revisao/<etapa>-<k>/entrada/`, `revisao/<etapa>-<k>.md` | o que o revisor recebeu e o relatório com as decisões |
| `cenas/manim/`, `cenas/effectcraft/` | cenas por motor |
| `cenas/planos/<id>-<n>.mp4`, `cenas/planos/indice.json` | um clipe por plano (fala mais folga), formato comum a todos os motores |
| `cenas/planos/<id>.eventos.json` | quando cada animação acontece, apoio para achar momentos no som |
| `audio/som.scraft`, `audio/mix.wav`, `som.md` | sessão do SoundCraft, mixagem e o motivo de cada efeito |
| `corte.fcproj`, `corte-1.mp4` | projeto do FilmCraft e primeiro corte |
| `final.mp4`, `final.srt` | exportação e legenda à parte |
| `miniatura.vectorcraft`, `miniatura.png` | miniatura 1280x720 |

Scripts (em `~/.omp/agent/skills/video/`, todos com `<pasta> [cena...]`):
`narrar.py`, `ouvir.py`, `margem.py`, `animatic.py`, `rascunho.py`,
`planos.py`, `conferir.py`, `revisao.py`. O `planos.linha()` dá, para a
edição, cada plano com seu clipe, sua fala e o início na linha do tempo.

## Revisores

Dois agentes sem contexto revisam: `video-espectador` (assiste como quem chega
de paraquedas; aponta termo antes da hora, salto, imagem que não diz nada no
mudo e, depois que há voz, fala que soa lida) e `video-critico` (julga quadros
contra margem, foco, continuidade e cor). Eles nunca veem material, briefing
inteiro, direção nem gabarito. Briefing, direção e amostra de narração vão só
ao dono. Os dois rodam num modelo diferente do seu (o `model` do agente): um
revisor igual ao autor tende a não enxergar o que o autor não enxergou.

| Rodada | Agente | `etapa` |
|---|---|---|
| roteiro | `video-espectador` | `roteiro` |
| storyboard | `video-critico` | `storyboard` |
| animatic | `video-espectador` | `animatic` |
| rascunho | `video-critico` e `video-espectador` | `rascunho` |
| primeiro corte | `video-espectador` | `corte` (lê `corte-1.mp4` e `corte-1.json`) |

1. `python3 ~/.omp/agent/skills/video/revisao.py <pasta> <etapa>` monta só o
   que o revisor pode ver, guarda uma cópia em `revisao/<etapa>-<k>/entrada/`
   e imprime o caminho de outra, fora da peça.
2. `task` com `agent: video-espectador` ou `video-critico` e, na tarefa, só
   `Pasta: <caminho impresso>`. Qualquer contexto a mais acaba com a cegueira.
3. Escreva `revisao/<etapa>-<k>.md`: o relatório, a correção do quiz (se
   houver) e os achados numa tabela `| Plano | Achado | Decisão |`, com
   "corrigido" (onde) ou "rejeitado" (motivo completo; o `revisao.py` passa as
   rejeições ao revisor da rodada seguinte, que só repete com fato novo).
4. A rodada passa quando o crítico não aponta nada grave, ou quando o
   espectador acerta o quiz (se houver) e não marca termo antes da hora.
   Achado leve se corrige ou se rejeita com motivo. Não passou: corrija tudo e
   rode de novo.
5. Não há teto de rodadas; siga sem parar para pedir aval no meio. Rodada que
   passa no item 4 e não traz nenhum achado novo (só repete rejeitado) fecha a
   etapa. Quando uma rodada piora, a próxima parte da versão com menos achados.

Os revisores julgam contra a direção escolhida e os padrões de qualidade, não
contra uma fórmula: mapa de termos e quiz só contam na estrutura de aula.

## Padrões de qualidade

Valem em todo vídeo, qualquer que seja a direção:

- texto e desenho dentro das margens seguras (`margem.py`), nunca encostando na
  borda; `fonte pequena` zerado;
- a narração nunca corta o último som de uma frase (`ouvir.py` até `voz ok`);
- fala em grafia normal, nunca grafia fonética;
- a imagem passa no teste do mudo quando a direção é de explicação;
- mixagem em -16 LUFS integrado, pico até -1 dBTP (`ffmpeg -i final.mp4 -af
  ebur128 -f null -`);
- legenda em arquivo separado, nunca queimada;
- música só se o dono pedir;
- assets de terceiros só de `~/Creative/Biblioteca/` (leia o `README.md` e o
  `FONTES.md` do pacote); Humaaans leva "Humaaans, Pablo Stanley, CC BY 4.0"
  na descrição; pacote novo só com licença conferida e linha no `FONTES.md`.

Confira o resultado em vez de supor: quadro solto com `ffmpeg -ss <t> -i x.mp4
-frames:v 1 q.png` e `read`; duração exportada contra a linha do tempo.

## Mudança pedida pelo dono

Volte só à etapa onde a mudança mora e refaça só o que ela atinge. Depois do OK
do animatic, mudança de tempo (fala reescrita, plano novo, tirado ou trocado de
ordem) volta ao storyboard e ao animatic das cenas atingidas, com a rodada do
espectador. Movimento e acabamento ficam na etapa em que estão. Narração nova
no corte: se a fala cabe no clipe (fala antiga mais a folga), só a edição muda;
se não cabe, a cena volta ao `planos.py <pasta> <cena>`. Som, legenda, textura
e corte se ajustam no SoundCraft e no FilmCraft, sem renderizar cena.

O dono pode pedir para ver qualquer coisa no app a qualquer hora: salve e chame
o `open_window` do app (skill `artcraft`).

## Produção com subagentes

Série ou vídeo longo pode dividir o render entre agentes `task`:

- a voz de todas as peças vem antes, conferida pelo `ouvir.py`;
- no máximo quatro cenas por agente;
- o contrato vai num arquivo do kit (`kit/contrato.md`) e a tarefa só aponta
  para ele: área útil, `audio/duracoes.json` oficial, comando de render,
  quantos renders ao mesmo tempo, arquivos editáveis, edição só pela
  ferramenta `edit`;
- ajudante que dois agentes precisam vai para o kit antes de começarem;
- quem orquestra julga pelas folhas do `conferir.py` e confirma num quadro
  direto do mp4 antes de mandar refazer.
