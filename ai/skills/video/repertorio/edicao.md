# Edição

Corte, ritmo e acabamento. Ofício no FilmCraft: `oficio/filmcraft.md`.

## Corte seco

O que é: um plano termina e o outro começa, sem transição.
Quando usar: o padrão; a maioria dos cortes deve ser invisível.
Quando evitar: mudança grande de lugar ou de tempo, que pede um aviso.
Como fazer aqui: `timeline.place` sem transição; o ponto do corte é o fim da
fala mais o respiro que o momento pede.
Referência: No Film School, "Eight essential cuts every video editor needs to
know" (standard cut).

## Respiro depois da ideia

O que é: um segundo ou dois de tela parada (ou câmera respirando) depois da
frase mais importante, antes de seguir.
Quando usar: depois de cada ideia principal; o espectador precisa de tempo para
juntar.
Quando evitar: entre frases de transição; respiro em tudo vira lentidão.
Como fazer aqui: deixe mais do clipe correr (o clipe traz até `FOLGA` segundos
sobrando); "pausa" na coluna Tom estica a fala.
Referência: princípio de segmentação de Mayer (pausas que o aprendiz controla
ou que o vídeo dá).

## Áudio que vaza (J e L)

O que é: o som do próximo plano começa antes da imagem (J) ou o do anterior
continua depois do corte (L).
Quando usar: para costurar blocos sem parecer slide trocando; a voz já começa
a próxima ideia enquanto a imagem fecha a anterior.
Quando evitar: quando a imagem nova é a revelação; o som não pode adiantar.
Como fazer aqui: com a voz em plano por plano, mova o início da fala alguns
quadros antes do corte de imagem na linha do tempo do SoundCraft.
Referência: Adobe, "L cut and J cut in film"; TechSmith, "How to edit videos:
L-cuts and J-cuts".

## Aproximação no corte (punch-in)

O que é: um corte para o mesmo quadro mais de perto, para marcar uma palavra ou
quebrar um plano longo.
Quando usar: plano de mais de 8 segundos sem mudança; ênfase.
Quando evitar: em diagrama com texto perto da borda; aproximar corta o texto.
Como fazer aqui: `effects.setParam` em `motion` (escala 110 a 120%), num
plano cortado com `timeline.razor`.
Referência: guias de edição para YouTube (jump cut e punch-in), por exemplo
1of10, "Video editing for beginners".

## Dissolver para mudança de tempo

O que é: uma imagem some enquanto a outra aparece.
Quando usar: passagem de tempo, mudança de lugar, volta ao começo.
Quando evitar: entre planos da mesma ideia; dissolver em todo corte deixa o
vídeo mole.
Como fazer aqui: `sequence.applyVideoTransition {effect: "cross_dissolve",
frames: 12 a 20}`.
Referência: No Film School, "Eight essential cuts" (dissolve).

## Textura e grão

O que é: papel, poeira ou grão sobrepostos ao vídeo inteiro, bem fracos.
Quando usar: quando o estilo pede algo feito à mão ou impresso.
Quando evitar: estilo limpo e digital; e nunca forte a ponto de pesar sobre o
texto.
Como fazer aqui: textura do estilo em V2 e grão em V3, modo Sobreposição,
opacidade perto de 35% e 8%.
Referência: prática de acabamento em motion design; texturas da Biblioteca
(`~/Design/Biblioteca/texturas/`).

## Legenda à parte

O que é: legenda num arquivo separado (SRT), nunca queimada na imagem.
Quando usar: sempre.
Quando evitar: nunca.
Como fazer aqui: gere o SRT pela linha do tempo e importe com
`captions.import`; entregue `final.srt` ao lado do `final.mp4`.
Referência: princípio de redundância de Mayer (legenda que repete a fala
atrapalha quem ouve; quem precisa liga).
