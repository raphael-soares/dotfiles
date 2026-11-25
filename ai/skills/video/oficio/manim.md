# Manim

Como trabalhar no Manim. Quando ele é o meio certo para um bloco, quem decide é
a direção do vídeo (`repertorio/visual.md#Diagrama que se mexe (Manim)`).

## Quando usar

Serve quando o conteúdo é um mecanismo que se mexe com precisão: diagrama,
algoritmo passo a passo, estrutura de dados, gráfico, fórmula. O desenho sai
exato, repetível e no tempo da fala.

Não serve para tipografia livre, colagem, foto ou vídeo real, personagem com
expressão, textura e acabamento: isso vai para EffectCraft, VectorCraft,
PhotoCraft ou FilmCraft (`oficio/`). Manim por hábito deixa todo vídeo com cara
de slide animado.

## Rodar

Cenas importam a identidade por variável de ambiente: rode com
`VIDEO_DIR=<pasta da peça> IDENTIDADE=~/Design/Estilos/<nome>` e, na cena,
`sys.path.insert(0, os.environ["IDENTIDADE"])` e `from tema import *`.

| Para quê | Comando |
|---|---|
| storyboard | `PLANOS=0 manim -ql -s --media_dir cenas/.manim --disable_caching <arquivo> C` |
| rascunho | `PLANOS=0 manim -ql --media_dir cenas/.manim --disable_caching <arquivo> C` |
| final | `python3 ~/.omp/agent/skills/video/planos.py <pasta> [cena...]` (1920x1080, 30 fps, um clipe por plano em `cenas/planos/`) |

Sem `PLANOS=0` o rascunho sai com a folga de cada plano e imagem e voz
dessincronizam no `rascunho.py`.

Cada `self.ate(k)` acrescenta `FOLGA` segundos (3 por padrão) com a câmera
respirando e abre uma seção nova; o `planos.py` corta as seções em clipes. Com
`PLANOS=0` a cena sai inteira, sem folga, como antes (`manim -r 1920,1080 --fps
30`, copiada para `cenas/render/<id>.mp4`). Renderizar em paralelo na mesma
`--media_dir` corrompe o cache de texto (`ParseError: no element found`): cada
cena na sua (o `planos.py` já faz assim).

## Tempo e poses

O `Cena` do `tema.py` herda de `MovingCameraScene` e lê
`$VIDEO_DIR/audio/duracoes.json`. A cena usa `self.p(i, fração)` para os
`run_time` (fração da fala do plano de índice `i`, contado a partir de 0),
`self.ate(k)` para esperar o fim do plano `k` do roteiro (contado a partir de 1,
ou seja, o começo do plano de índice `k`), `self.t(fração)` quando a cena
inteira é um plano só, e termina com `self.fechar()`, que espera o que falta
para a duração da narração.

Com `-s`, as animações pulam para o fim e o `Cena` grava a pose de cada plano:
`self.ate(k)` salva `storyboard/<id>-<k>.png` (o fim do plano `k`, contado a
partir de 1, como no roteiro), `self.fechar()` salva o último e o primeiro
`play` salva antes `storyboard/inicio/<id>.png`, a abertura da cena, que o
crítico compara com o fim da cena anterior. Uma cena por
segundo, mais ou menos. Por isso toda cena chama `self.ate(k)` na virada de
cada plano, mesmo a que só tem um movimento: plano sem `ate` fica sem quadro e
o `revisao.py` recusa a rodada. Identidade antiga sem `_pose`, `_comecar`, `p`
ou `ate`: atualize o `tema.py` dela antes do storyboard.

Pose a pose: o arquivo da cena escrito no storyboard já chega em cada pose
final, com movimento simples. No rascunho você troca só o caminho entre as
poses (o movimento); as poses aprovadas no animatic não mudam. Toda cena monta o
próprio estado inicial com os construtores do `cenas/manim/palco.py` do vídeo,
para que qualquer cena renderize sozinha e comece onde a anterior terminou.

## Movimento

- A mesma coisa mudando é `Transform` ou `ReplacementTransform`, nunca sumir e
  aparecer outra. O olho acompanha o objeto.
- Grupo entra com `LaggedStart` (`lag_ratio` de 0,1 a 0,3), não tudo de uma vez
  nem um por vez em `play` separados.
- O que não é o assunto agora fica apagado, não some: o contexto continua ali.
  Em forma só de contorno, `set_opacity` acende o preenchimento vazio e vira
  bloco; apague com `set_stroke(opacity=0.25)` e, no que tem preenchimento,
  `set_fill(opacity=...)` proporcional. Peça redesenhada a cada quadro (um
  `always_redraw`, como um medidor) não herda a opacidade do grupo: ela tem de
  ler a opacidade da moldura ao se redesenhar. Para entrar ou sair, adicione a
  peça com `self.add` e anime só a moldura (`FadeIn(m.moldura)`): um `FadeIn` ou
  `FadeOut` no grupo inteiro quebra com `zip() argument 2 is shorter than
  argument 1`. O `-s` do storyboard pula as animações e não pega esse erro; ele
  só aparece no rascunho.
- O caminho que a coisa faz é conteúdo. `Transform` leva em linha reta, por
  cima de tudo; quando o trajeto ensina (o dado passa pela CPU, sobe pelo
  barramento), cada peça percorre a rota desenhada com `MoveAlongPath`, e não
  só a primeira. Bloco que voa direto do disco para a memória numa cena de
  polling desenha DMA.
- A revelação ganha aproximação de câmera
  (`self.camera.frame.animate.scale(0.6).move_to(alvo)`); a volta ao quadro
  inteiro marca que o bloco acabou.
- Uma mudança por vez. Duas coisas mexendo em lugares diferentes dividem o olho.
- Depois da ideia principal, um respiro sem nada novo: "pausa" na coluna Tom e o
  `.wav` do plano esticado na narração (`oficio/voz.md`). A cena só
  espera.
- A cor de destaque da identidade é "olhe aqui agora". Usada em tudo, não aponta
  para nada.
- Ritmo rápido, rápido, lento: o que é passagem anda depressa, a revelação
  demora.

## Margem e forma

Nada a menos de 10% da borda. O `tema.py` da identidade fixa o quadro em 16×9
unidades (`config.frame_width = 16.0`, `config.frame_height = 9.0`); no quadro
padrão do Manim (14,2×8) os mesmos números dariam 5%. Com 16×9, o conteúdo
fica com `x` entre -6,4 e 6,4 e `y` entre -3,6 e 3,6: a `AREA_SEGURA` e o
`encaixar(grupo)` do `tema.py`. Identidade nova copia essas duas linhas de
`config`. A cena encaixa o grupo nessa área em vez de posicionar perto da
borda; prefira aproximar a câmera a encolher tudo para caber. O `margem.py`
confere os quadros renderizados: borda, tamanho (`pequeno`) e centro
(`descentrado`).

O `Cena` confere cada pose em `ate()` e `fechar()`: imprime `fonte pequena`
para todo `Text` visível abaixo de 24 pt na tela (o tamanho conta escala e
zoom da câmera; `FONTE_MIN` muda o piso) e `estourou` quando a animação passa
do fim do plano. Identidade nova copia esse `_conferir` junto com o `Cena`.

Emoji não renderiza em `Text`: desenhe ícones com formas (polígono, arco).
Texto sobre bloco de destaque usa a cor de texto clara, não a do fundo. Forma
com preenchimento opaco sobe para a frente quando é animada e tapa o texto que
estava em cima dela: desenhe caixas e chips só com contorno.

## Fórmula

Sempre Typst, nunca LaTeX nem `MathTex`:

```typst
#set page(width: auto, height: auto, margin: 4pt, fill: none)
#set text(fill: white, size: 28pt)
$ "FB"(n) = h_"esq" - h_"dir" $
```

`typst compile --format svg f.typ f.svg`, depois `SVGMobject("f.svg")` na cena.
Use a cor do texto que a identidade manda.
