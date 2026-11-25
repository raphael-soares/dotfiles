# Som

Desenho de som e mixagem. Som é quase sempre subtração: voz limpa, ambiente
controlado, pouco efeito. Ofício: `oficio/soundcraft.md`.

## Efeito por intenção

O que é: cada efeito existe porque a direção quer que a pessoa sinta ou note
algo naquele momento (o erro, a chegada, a virada). Nunca um som por tipo de
animação.
Quando usar: nos momentos que a direção marcou; poucos por minuto.
Quando evitar: em toda entrada de elemento; som em tudo vira barulho e não
aponta para nada.
Como fazer aqui: na direção, uma lista "momento, o que a pessoa deve sentir,
som". No SoundCraft, cada efeito posto à mão, com o motivo em `som.md` da peça.
Referência: Descript, "How to sound design a YouTube video" ("the cartoony
sounds draw too much attention to themselves").

## Voz na frente

O que é: a voz é o que importa; tudo o mais fica abaixo dela.
Quando usar: sempre.
Quando evitar: nunca.
Como fazer aqui: passa-alta em 80 Hz e compressor na trilha da voz; efeito e
ambiente pelo menos 12 dB abaixo; mixagem final em -16 LUFS integrado e pico
até -1 dBTP.
Referência: Descript, "How to sound design a YouTube video" ("viewers forgive
a rough picture and leave over bad audio").

## Tom de sala

O que é: um ambiente quase inaudível por baixo de tudo, para o silêncio entre
frases não soar como buraco.
Quando usar: narração gravada ou sintética, que sem ambiente soa seca demais.
Quando evitar: quando há música contínua; ela já preenche.
Como fazer aqui: tom de sala da Biblioteca em loop, perto de -32 dB.
Referência: NPR Training, "Campfire tales" (som ambiente para situar a cena).

## Som que chega antes

O que é: o som de algo aparece um instante antes da imagem, ou antes de a voz
explicar, e a curiosidade "o que é isso?" segura a atenção.
Quando usar: entrada de um elemento importante; troca de cena.
Quando evitar: quando o som é ambíguo e ninguém vai reconhecer.
Como fazer aqui: o efeito começa 3 a 6 quadros antes da animação.
Referência: NPR Training, "Campfire tales" ("let the sound come in first; then
refer to it").

## Música só com pedido

O que é: trilha musical por baixo da voz.
Quando usar: só quando o dono pede. Então, uma música com motivo para cada
trecho, que abaixa na fala e sobe nas pausas, e muda quando o vídeo muda de
parte.
Quando evitar: sem pedido do dono; e loop da mesma faixa por minutos, que vira
papel de parede.
Como fazer aqui: automação de volume na trilha da música (`automation.
write_range`), baixa nos trechos de fala.
Referência: NPR Training, "Score: best practices for using music in audio
storytelling" ("articulate why you are using a piece of music").

## Silêncio de propósito

O que é: um momento sem efeito nenhum, só a voz ou nem ela.
Quando usar: antes da revelação; depois da ideia principal.
Quando evitar: no meio de uma explicação; parece falha.
Como fazer aqui: marque na direção; o SoundCraft não põe nada ali.
Referência: Walter Murch, "In the Blink of an Eye" (o som que se tira).
