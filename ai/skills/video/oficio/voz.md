# Voz

Narração com o OmniVoice e conferência com o Whisper. Como escrever o que a voz
vai dizer está em `repertorio/fala.md`; aqui é só o ofício de gravar.

## Subir o serviço

O OmniVoice roda no container Docker `audiocpp`. Antes de narrar (não faz nada
se já estiver no ar):

```bash
docker compose -f ~/.config/audiocpp/compose.yaml up -d
timeout 600 bash -c 'until curl -sf 127.0.0.1:8880/v1/models >/dev/null; do sleep 3; done'
```

A primeira chamada carrega o modelo na GPU e demora mais. Se a voz não
responder, suba o container e rode de novo. Nunca troque de voz, modelo ou
motor para contornar: continuou falhando, pare e conte ao dono o erro. A
ferramenta `tts` do omp não serve (falha com "No available speech model matches
the speech role").

## Vozes

`professora` (pt-BR) e `teacher` (inglês), clones de uma gravação sintética
fixa: todas as cenas soam como a mesma pessoa. A voz vem da linha `- Voz:` do
`video.md`.

A amostra da `professora` tem 8,6 s (duas frases). O servidor processa a
amostra em todo pedido: com a de 23 s cada fala levava 38% a mais, e o timbre
não mudou. Amostra nova fica curta, com o `reference_text` igual ao que ela diz.

## Narrar

`python3 ~/.omp/agent/skills/video/narrar.py <pasta> [cena...]`:

- grava cada plano em `audio/planos/<id>-<n>.wav`, junta a cena em
  `audio/<id>.wav` e regrava `audio/duracoes.json` (`<id>` e `<id>#planos`);
- pede `speed` 0,9: na velocidade padrão o OmniVoice come o último som da
  frase. Não tire esse parâmetro;
- pede 16 passos (`num_inference_steps`; o padrão é 32): leva metade do
  tempo, e o dono não ouviu diferença. Com 8 a voz já erra palavra;
- estica 0,8 s o plano com "pausa" na coluna Tom;
- avisa o plano cuja fala passa 2,5 s do Tempo do roteiro;
- guarda o som cru de cada fala em `audio/cache/`, pela voz, velocidade e
  texto: rodar de novo só pede ao servidor a fala que mudou. Trocou o modelo
  ou a amostra da voz no servidor, apague `audio/cache/`;
- sem argumento narra tudo; com `<id>`, só a cena; com `<id>#<n>`, gera de
  novo aquele plano mesmo com o texto igual (outra tomada, ignorando o cache).

Respiro no fim de uma cena: estique o `.wav` dela com `apad=whole_dur=<total>`
e grave o total novo em `<id>`, sem mexer nos planos.

## Amostra antes do vídeo inteiro

Narre duas ou três cenas, ouça e mostre ao dono antes de narrar o resto. É
nessa hora que o texto que soa lido aparece; depois de narrar tudo, consertar
custa o vídeo inteiro.

## Conferir

`python3 ~/.omp/agent/skills/video/ouvir.py <pasta> [cena...]` passa cada plano
no Whisper e lista fim cortado e texto que destoa do roteiro, com o que ouviu
ao lado, pelo id `<id>#<n>`. Palavra errada no roteiro: corrija o texto e narre
a cena. Texto certo e tomada ruim: `narrar.py <pasta> <id>#<n> ...` com os ids
da lista. Repita até `voz ok` ou até sobrar só plano marcado por sigla: o
Whisper também erra sigla (ouve RAID como "rei"), então esse plano não se
refaz, vai para a lista do dono. O dono ouve só os planos dessa lista, não a
aula inteira.

Whisper à mão: `curl -s "127.0.0.1:9000/asr?language=pt&output=txt" -F
audio_file=@x.wav`. Ele só entende wav 16 kHz mono; o wav float de um bounce do
SoundCraft faz ele devolver "[música]". Converta antes: `ffmpeg -i in.wav -ar
16000 -ac 1 x.wav`.

## Pronúncia

O OmniVoice lê "CPU", "DMA", "RAM" e "polling" do jeito normal. Escreva a fala
com a grafia certa, sempre. Termo que sair errado: troque a palavra, reordene a
frase ou explique o termo, nunca escreva grafia fonética (nada de "pú-lin" ou
"dê-éme-á"). Termo em inglês continua em inglês.

Cada vídeo tem uma tabela "Pronúncia" em `video.md` (termo, conferido sim ou
não). Termo novo: gere uma frase curta, passe no Whisper e ouça antes de narrar
o vídeo inteiro.

## Inglês

`teacher`, Whisper com `language=en`. O resto do fluxo é igual.
