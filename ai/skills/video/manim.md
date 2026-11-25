# Manim na skill video

Referência do `SKILL.md` para storyboard, rascunho e passada final.

## Rodar

Cenas importam a identidade por variável de ambiente: rode com
`VIDEO_DIR=<pasta do vídeo> IDENTIDADE=<pasta da identidade>` e, na cena,
`sys.path.insert(0, os.environ["IDENTIDADE"])` e `from tema import *`.

| Para quê | Comando |
|---|---|
| storyboard | `manim -ql -s --media_dir cenas/.manim --disable_caching <arquivo> C` |
| rascunho | `manim -ql --media_dir cenas/.manim --disable_caching <arquivo> C` |
| final | `manim -r 1920,1080 --fps 30 --media_dir cenas/.manim --disable_caching <arquivo> C` (o `-qh` sai a 60 fps) |

Copie o `.mp4` para `cenas/render/<id>.mp4`. Renderizar em paralelo corrompe o
cache de texto (`ParseError: no element found`): uma cena por vez, e a que
falhou roda de novo sozinha.

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
  ler a opacidade da moldura ao se redesenhar.
- A revelação ganha aproximação de câmera
  (`self.camera.frame.animate.scale(0.6).move_to(alvo)`); a volta ao quadro
  inteiro marca que o bloco acabou.
- Uma mudança por vez. Duas coisas mexendo em lugares diferentes dividem o olho.
- Depois da ideia principal, um respiro sem nada novo: "pausa" na coluna Tom e o
  `.wav` do plano esticado na narração (seção Voz do `SKILL.md`). A cena só
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
confere os quadros renderizados.

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
