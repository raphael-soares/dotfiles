# Visual

Como a imagem carrega a ideia. Ofícios: `oficio/manim.md`,
`oficio/effectcraft.md`, `oficio/vectorcraft.md`, `oficio/photocraft.md`.

## A imagem explica, a voz acompanha

Padrão das aulas da Udesc.

O que é: cada conceito vira uma metáfora visual ou um mecanismo que se mexe; a
voz comenta o que está na tela.
Quando usar: vídeo explicativo.
Quando evitar: depoimento, entrevista, vídeo em que a pessoa falando é o
conteúdo.
Como fazer aqui: teste do mudo: sem som, o vídeo ainda dá a ideia. Se só a voz
explica, o plano está errado. A imagem aparece quando a voz fala dela.
Referência: princípio multimídia de Mayer (palavras e imagens juntas rendem
mais que só palavras), "Multimedia Learning", 2020.

## Metáfora que atravessa

O que é: uma só metáfora visual para o vídeo inteiro, reaproveitada em cada
bloco (a CPU como alguém numa mesa, os dispositivos como guichês).
Quando usar: tema abstrato com várias partes que se relacionam.
Quando evitar: quando a metáfora força o conceito e ensina errado; aí mostre o
mecanismo de verdade.
Como fazer aqui: a direção nomeia a metáfora e diz, para cada conceito, como
ele aparece dentro dela. Objetos que voltam têm o mesmo desenho e tamanho em
todas as cenas.
Referência: Mayer, princípio de coerência (um quadro mental, sem material
alheio).

## Diagrama que se mexe (Manim)

O que é: diagrama, algoritmo ou estrutura de dados animado com precisão, no
tempo da fala.
Quando usar: mecanismo exato, passo a passo, fórmula, gráfico.
Quando evitar: tipografia livre, colagem, foto, personagem expressivo; Manim
por hábito deixa o vídeo com cara de slide animado.
Como fazer aqui: `oficio/manim.md`. Algoritmo passo a passo vira um plano por
passo.
Referência: documentação da Manim Community (manim.community).

## Tipografia cinética

O que é: a palavra-chave entra com movimento e peso, como imagem.
Quando usar: abertura, nome de um conceito, número de impacto.
Quando evitar: para escrever a frase que a voz fala (redundância); para
parágrafos.
Como fazer aqui: EffectCraft (`oficio/effectcraft.md`), uma ou duas palavras
por vez, fonte do estilo.
Referência: Mayer, princípio de sinalização (destacar o essencial).

## Colagem e ilustração

O que é: cena montada com ilustração, ícone, foto recortada e textura.
Quando usar: situar no mundo real (pessoa, lugar, objeto do dia a dia); tom
leve.
Quando evitar: mecanismo preciso, que pede diagrama.
Como fazer aqui: só material da Biblioteca (`~/Creative/Biblioteca/`), com a
licença do `FONTES.md`; Humaaans pede o crédito "Humaaans, Pablo Stanley, CC BY
4.0".
Referência: princípio de personalização de Mayer (pessoas e situações
reconhecíveis).

## Cor com sentido

O que é: cada cor quer dizer uma coisa no vídeo inteiro; a cor de destaque é
"olhe aqui agora".
Quando usar: sempre.
Quando evitar: nunca; cor decorativa espalhada não aponta para nada.
Como fazer aqui: a direção fixa as cores. Se a fala nomeia uma cor ("a parte
laranja"), a cor não muda depois, porque trocar é regravar a narração.
Medidor e gráfico têm título neutro e legenda com amostra de cada cor.
Referência: Mayer, princípio de sinalização.

## Resumo visual

O que é: no fim, as ideias lado a lado, na mesma metáfora do vídeo.
Quando usar: fim de aula ou de vídeo com várias partes.
Quando evitar: vídeo de uma ideia só; o resumo repete.
Como fazer aqui: o último bloco reaproveita os objetos das cenas anteriores,
em miniatura, numa tela só; nunca uma lista de frases.
Referência: efeito de recuperação (retrieval practice), Roediger e Karpicke,
"Test-enhanced learning", Psychological Science, 2006.

## Margem e foco

O que é: texto e desenho dentro da área segura, grandes e centrados.
Quando usar: sempre.
Quando evitar: nunca.
Como fazer aqui: `margem.py` sobre os quadros até `margem ok`; corrija
aproximando a câmera ou aumentando o grupo, nunca encolhendo.
Referência: área segura de título da EBU R 95 ("Safe areas for 16:9 television
production").

## Quadro branco

O que é: o desenho vai se fazendo na tela, traço a traço, enquanto a voz
explica.
Quando usar: raciocínio que se constrói por partes; tom de aula informal.
Quando evitar: vídeo longo inteiro assim (cansa) e mecanismo que se mexe, que o
traço parado não mostra.
Como fazer aqui: Manim com `Create` sobre SVG de traço de mão, ou
EffectCraft com caminho revelado (`Trim Paths`).
Referência: Fiorella e Mayer, "Effects of observing the instructor draw
diagrams on learning from multimedia messages", Journal of Educational
Psychology, 2016.

## Gravação de tela

O que é: o que acontece num programa de verdade, gravado.
Quando usar: mostrar uma ferramenta real, um terminal, uma interface.
Quando evitar: quando o detalhe da interface distrai da ideia; um diagrama
explica melhor.
Como fazer aqui: ainda sem ferramenta nem ofício nesta skill; combine com o
dono antes de prometer na direção.
Referência: Mayer, princípio de coerência (aproximar e cortar o que não serve).
