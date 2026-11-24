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
`$VIDEO_DIR/audio/duracoes.json`. A cena usa `self.p(plano, fração)` para os
`run_time` (fração da fala daquele plano), `self.ate(plano)` para esperar o
plano começar, `self.t(fração)` quando a cena inteira é um plano só, e termina
com `self.fechar()`, que espera o que falta para a duração da narração.

Com `-s`, as animações pulam para o fim e o `Cena` grava a pose de cada plano:
`self.ate(k)` salva `storyboard/<id>-<k>.png` (o fim do plano `k`, contado a
partir de 1, como no roteiro) e `self.fechar()` salva o último. Uma cena por
segundo, mais ou menos. Por isso toda cena chama `self.ate(k)` na virada de
cada plano, mesmo a que só tem um movimento: plano sem `ate` fica sem quadro e
o `revisao.py` recusa a rodada. Identidade antiga sem `_pose`, `p` ou `ate`:
atualize o `tema.py` dela antes do storyboard.

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
- O que não é o assunto agora fica apagado (`set_opacity(0.25)`), não some: o
  contexto continua ali.
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

Nada a menos de 10% da borda (conteúdo dentro de `x` entre -6,4 e 6,4 e `y`
entre -3,6 e 3,6). O `tema.py` define essa área (`AREA_SEGURA`,
`encaixar(grupo)`); a cena encaixa o grupo nela em vez de posicionar perto da
borda. Prefira aproximar a câmera a encolher tudo para caber.

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
