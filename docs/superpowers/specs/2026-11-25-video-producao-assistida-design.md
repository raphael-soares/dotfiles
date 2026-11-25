# Vídeo: produção assistida com repertório

## Intenção

O dono não quer uma esteira que recebe material e devolve vídeo pronto. Quer
trabalhar como trabalha quem encomenda um vídeo a um bom produtor de YouTube:
ele traz tema, material e objetivo, olha cada esboço e diz "tá bom", "muda
isso", "tira aquilo". O agente é o produtor: escreve o roteiro, dirige para
tudo ficar coerente, desenha, anima, edita e mixa com a mão na massa, nos
apps, decidindo cada coisa como uma pessoa decidiria.

Duas coisas puxam a mudança:

- **Vídeos diferentes pedem jeitos diferentes.** Não há regra escrita na
  pedra. O que se usa e como se faz é decidido no planejamento de cada vídeo.
  Para isso dar certo com qualidade, o agente precisa de uma prateleira bem
  organizada (repertório de técnicas, biblioteca de assets, ofício nos apps)
  de onde escolher, em vez de inventar tudo do zero a cada vez ou seguir uma
  receita fixa no código.
- **As quatro aulas de SO soam como texto lido.** A fala foi escrita para
  leitura (títulos, enumeração "1. Título: conteúdo"), e isso aparece na voz.
  O texto falado tem de ser escrito para ser falado.

O fluxo automático montado no plano anterior (`2026-11-24-video-montagem-por-plano-design.md`)
vai contra a primeira: o `som.py` sorteia 990 efeitos sonoros pelo tipo de
animação e o `montar.py` monta e exporta a edição num lote, sem ninguém olhar.

## Objetivos

- Repertório escrito e organizado de técnicas consolidadas no YouTube, que o
  agente consulta e combina: estruturas de vídeo, tons (aula, sério, com
  humor), ganchos e retenção, escrita para fala, técnicas de edição, desenho de
  som, estilos visuais, miniatura e título. Cada técnica diz quando serve,
  quando não serve e como se faz com as ferramentas daqui.
- Direção do vídeo completa: o documento de planejamento decide estilo, tom,
  estrutura, técnicas por momento, motor de animação, identidade, som, edição,
  legenda e miniatura, citando as entradas do repertório escolhidas.
- Fala escrita para ser falada, conferida ouvindo.
- Esboço em toda etapa e revisão do dono antes da etapa seguinte. Nunca
  direto para o produto final.
- Som e edição feitos à mão nos apps (SoundCraft, FilmCraft), com cada
  decisão tomada para aquele momento do vídeo.
- Animação escolhida por vídeo na direção: Manim quando o conteúdo é diagrama
  ou algoritmo, EffectCraft e FilmCraft para os outros estilos (decisão do
  dono).

## Não objetivos

- Pipeline que produz o vídeo inteiro sem revisão.
- Regras universais de estilo. O que hoje está como regra no `SKILL.md`
  (imagem explica e voz acompanha, quem chega de paraquedas, estrutura que
  prende) vira técnica do repertório, que a direção escolhe ou não.
- Refazer as aulas 1 a 3.

## Anti-objetivos

O trabalho falhou, mesmo funcionando, se:

- a voz ainda soa como texto lido (título falado, enumeração, frase de
  apostila);
- todo vídeo sai com a mesma cara porque o repertório virou receita;
- o dono recebe um vídeo pronto sem ter visto os esboços;
- o agente escolhe técnica "de cabeça" sem passar pelo repertório, ou o
  repertório é tão genérico que não ajuda a decidir.

## Restrições

- Ferramentas: Manim, apps ArtCraft (VectorCraft, PhotoCraft, EffectCraft,
  FilmCraft, SoundCraft) pelos MCPs, OmniVoice para a voz, Whisper local.
  O dono pode abrir a janela de qualquer app (`open_window`) para ver ou mexer.
- Assets só da `~/Design/Biblioteca/`, com a regra de licença e crédito do
  README dela.
- Preferências fixas do dono que continuam valendo em qualquer vídeo (padrões
  de qualidade, não estilo): texto com margem segura, narração nunca corta o
  último som, rodadas de revisão até o revisor aprovar sem teto de rodadas,
  partir da versão com menos achados quando uma rodada piora, música só se o
  dono pedir, legenda em arquivo à parte e nunca queimada, sem travessão.
- Código só onde é ferramenta: renderizar, narrar, medir, conferir. Script que
  toma decisão criativa sai.

## Abordagens consideradas

- **A. Reescrever a skill como guia de produção, com repertório e ofício em
  arquivos à parte.** Escolhida pelo dono, com o reforço de que nada é regra
  fixa: a skill é a prateleira e o planejamento de cada vídeo escolhe dali.
- B. Manter o fluxo automático e somar um "modo assistido". Descartada: dois
  jeitos de fazer a mesma coisa, que divergem.
- C. Quebrar em várias skills (roteiro, edição, som). Descartada: a coerência
  entre roteiro, imagem e som, que o agente tem de dirigir, fica espalhada.

## O que foi decidido

### Papéis e ritmo

O dono encomenda e aprova; o agente produz. Cada etapa termina num esboço que
o dono vê, e a seguinte só começa com o OK dele. As etapas:

1. **Conversa inicial.** Tema, material, objetivo, público, duração, se tem
   música; o que faltar, um `ask` por pergunta.
2. **Briefing.** Quem assiste, o que já sabe, a ideia que fica, objetivos.
   Esboço: o próprio briefing.
3. **Direção.** O plano do vídeo (seção abaixo). Esboço: `direcao.md` e, para
   o estilo visual, uma folha de referência (quadros de exemplo, paleta,
   objetos desenhados) mostrada antes de animar.
4. **Roteiro.** Plano por plano, Tela e Fala, com a fala escrita para fala.
   Esboço: o roteiro e uma amostra de narração (um trecho narrado) para o dono
   ouvir o tom.
5. **Narração e storyboard/animatic.** Esboço: o animatic com a voz.
6. **Rascunho animado.** Esboço: `rascunho.mp4`.
7. **Primeiro corte.** Edição e som montados à mão nos apps. Esboço:
   `corte-1.mp4` e, se o dono quiser, a janela do FilmCraft aberta no projeto.
8. **Corte final e miniatura.**

Revisores cegos (crítico e espectador) continuam antes de cada esboço que vai
ao dono a partir do roteiro. Decisão do agente sobre como julgam:

- pelo que a direção do vídeo escolheu, mais os padrões de qualidade; o mapa
  de termos e o quiz só são cobrados quando a direção adota a estrutura de
  aula (o `revisao.py` passa a aceitar briefing sem essas seções);
- briefing, direção e amostra de narração vão só ao dono;
- roteiro, animatic, rascunho e corte 1 passam pelo espectador; storyboard e
  rascunho também pelo crítico;
- o espectador passa a marcar o trecho que soa lido.

### Direção completa

`direcao.md` passa a responder, com referência às entradas do repertório:

- formato e tom (aula, explicação séria, com humor, lista, história);
- estrutura do vídeo e o arco, com os ganchos e pontos de retenção;
- para cada bloco: o que a tela faz, com que técnica e com que motor
  (Manim, EffectCraft, imagem, gravação de tela);
- estilo visual: identidade usada (ou nova), paleta, tipografia, objetos que
  voltam, textura;
- voz: tom geral, ritmo, onde entra pausa;
- som: ambiente, que momentos ganham efeito e de que tipo, música e onde
  abaixa;
- edição: ritmo de corte, transições, respiros, zooms, legenda;
- miniatura e título.

O que a direção não cita do repertório, ela justifica.

### Repertório

Pasta `repertorio/` na skill, um arquivo por assunto, com um `README.md` de
índice que liga situação a técnica ("quero prender nos 5 primeiros segundos",
"o conceito é abstrato", "o bloco está longo e cansa"). Assuntos iniciais:

- estruturas de vídeo (aula, explicação de um problema, lista, comparação,
  história, tutorial);
- tons e como cada um muda roteiro, voz, imagem e som;
- ganchos, promessa, retenção, fechamento;
- escrita para fala;
- técnicas de edição (cortes, ritmo, transições, zoom e câmera, respiro,
  ênfase, texto na tela, legenda);
- desenho de som e música;
- estilos visuais e animação (metáfora visual, diagrama que se mexe, motion
  graphics, colagem, quadro branco);
- miniatura e título.

Cada técnica é uma entrada curta com nome, o que é, quando usar, quando
evitar, como fazer aqui (app e passo) e de onde vem (canal, livro ou guia).
As regras atuais do `SKILL.md` que são de estilo viram entradas, marcadas como
o padrão das aulas da Udesc.

### Escrita para fala

Entrada própria no repertório e passo obrigatório do roteiro: frases curtas,
uma ideia por frase, ligação falada entre ideias ("e aí", "só que"), nada de
título falado nem enumeração com dois-pontos, número dito como se diz.
Conferência: narrar e ouvir trechos antes de narrar o vídeo inteiro, e o
espectador cego ouve o animatic e marca o trecho que soa lido.

### Biblioteca e identidades

`~/Design/Biblioteca/` continua o lugar dos assets, com o README como índice
por uso. As identidades (`~/Design/Identidades/<nome>/`) viram opções de
estilo que a direção escolhe ou adapta, não padrão obrigatório.

### Ofício nos apps

Pasta `oficio/` na skill: um arquivo por ferramenta (Manim, que já é o
`manim.md`, EffectCraft, FilmCraft, SoundCraft, VectorCraft, PhotoCraft) com o
jeito de trabalhar nela: fluxo, comandos que importam, armadilhas já
conhecidas (como o FilmCraft recusar legendas que se encostam, o maximizador
na saída master do SoundCraft, o Whisper que só entende wav 16 kHz mono).

### Scripts

- Ficam como ferramenta: `narrar.py`, `ouvir.py`, `margem.py`, `planos.py`
  (um clipe por plano para montar na mão), `conferir.py`, `revisao.py`,
  `animatic.py`, `rascunho.py`.
- Saem: `som.py`, `sons.json`, `montar.py`, e o trecho do `SKILL.md` que
  descreve a montagem automática.
- O comando do rascunho passa a usar `PLANOS=0` (sem isso imagem e voz saem
  dessincronizadas; achado grave da revisão de código).
- O `Cena` continua gravando `cenas/planos/<id>.eventos.json`, como lista de
  momentos de apoio para o som à mão, sem uso automático (decisão do agente).

### Motores fora do Manim

Decisão do agente: cena feita no EffectCraft, com imagem ou montada no
FilmCraft entrega o mesmo formato que o Manim (um clipe `cenas/planos/<id>-<n>.mp4`
por plano, com a fala e folga, e o quadro final de cada plano em
`storyboard/`), para que storyboard, conferências e edição tratem todas as
cenas igual. O `oficio/effectcraft.md` diz como exportar nesse formato.
Gravação de tela fica fora desta entrega: aparece no repertório como opção,
sem ferramenta nem ofício ainda.

### Manim como escolha, não padrão

Manim entra no repertório como uma técnica entre outras, com quando serve
(mecanismo, diagrama, algoritmo, fórmula) e quando não serve. A direção só o
usa com intenção declarada: diz por que aquele bloco pede Manim e não outro
meio. Hábito ("as aulas sempre foram em Manim") não é motivo (decisão do dono).

### Reorganização do `~/Design`

Hoje a raiz mistura assets (`Biblioteca/`, `Identidades/`) e projetos
(`Fesc/`, `Syncfast/`, `Videos/`), e o kit da série SO fica ao lado das aulas
em `Videos/`. Projeto é multidisciplinar (vídeo, áudio, arte, marca), então a
estrutura passa a ser (decisão do dono, uma pasta por peça):

```
~/Design/
  Biblioteca/          assets de terceiros; Videos/Musicas entra em Biblioteca/musica
  Estilos/             identidades próprias (hoje Identidades/noite)
  Projetos/<projeto>/  uma pasta por peça entregue, com todos os arquivos dela;
                       o que é comum às peças fica na raiz do projeto
  0-Archive/
```

Mapa da mudança (nomes de pasta são decisão do agente):

| Hoje | Depois |
|---|---|
| `Videos/so-p2-serie/` | `Projetos/so-p2/kit/` |
| `Videos/so-p2-aula-<n>-<tema>/` | `Projetos/so-p2/aula-<n>-<tema>/` |
| `Videos/hardware-es/` | `0-Archive/hardware-es/` (já estava para arquivar) |
| `Videos/Musicas/` | `Biblioteca/musica/` |
| `Fesc/01. Logomarca FESC/`, `Fesc/02. Kit Digital/` | `Projetos/fesc/logomarca/`, `Projetos/fesc/kit-digital/` |
| `Syncfast/` | `Projetos/syncfast/logo/` |
| `Identidades/noite/` | `Estilos/noite/` |

O que mudar junto:

- caminhos absolutos dentro dos projetos: as cenas e palcos das aulas 1 a 4
  apontam para `so-p2-serie` e `Identidades`; `video.md`, `direcao.md`,
  `contrato.md` e `serie.md` também. Os `.fcproj` e scripts de lote antigos
  não precisam (viram comparação ou arquivo);
- a skill `video` (pasta do vídeo vira `~/Design/Projetos/<projeto>/<peça>/`,
  identidades em `Estilos/`), a skill `artcraft` (projeto em
  `~/Design/Projetos/<projeto>/<peça>/`), o `docs/design.md` do dotfiles e a
  linha do `~/Design` na tabela de áreas do `AGENTS.md`;
- conferir depois da mudança que uma cena da aula 4 ainda renderiza.

Os apps Flatpak já enxergam `~/Design` inteiro, então a mudança não mexe em
permissão. `~/Design` é par do syncfast: a mudança sobe como mover pastas e o
outro PC recebe igual; fazer com o syncfast parado e conferir o par depois,
para não virar apagar e reenviar 3 GB. A marca de uma área continua na área
(`~/TEAjudo`), como diz o `AGENTS.md`.

### Idioma

Decisão do agente: repertório e ofício em pt-BR, com nota onde o inglês muda
(sobretudo na escrita para fala).

### Piloto

Aula 4 de SO (`~/Design/Videos/so-p2-aula-4-entrada-e-saida/`), passando pelo
fluxo novo a partir do roteiro (decisão do dono):

1. A fala da aula inteira é reescrita para ser falada, sem mexer na Tela.
   Esboço: o roteiro novo e uma amostra narrada para o dono ouvir.
2. Narração nova, `ouvir.py` limpo, cenas renderizadas de novo com
   `planos.py` (as animações se ajustam à fala pelas frações de tempo; o que
   estourar se corrige na cena).
3. Primeiro corte montado à mão no FilmCraft e no SoundCraft, com som
   decidido momento a momento. Esboço: `corte-1.mp4`.
4. Corte final aprovado pelo dono.

O `final-v1.mp4` já entregue fica intocado. O `final.mp4`, o `final.srt` e a
pasta `montagem/` que o fluxo automático gerou viram `comparacao/` (só para
comparar) e somem quando o corte novo for aprovado.

## Fica com quem constrói

- O texto de cada entrada do repertório, pesquisado em fontes reais
  (guias de roteiro e edição para YouTube, canais de referência) e adaptado às
  ferramentas daqui.
- A forma exata do índice do repertório e dos arquivos de ofício.
- A redação nova do `SKILL.md`, desde que fique curta: etapas, o que cada uma
  entrega, como consultar repertório, biblioteca e ofício, padrões de
  qualidade.
- Como aproveitar no `oficio/` o que o `som.py` e o `montar.py` ensinaram
  sobre os CLIs antes de apagá-los.
