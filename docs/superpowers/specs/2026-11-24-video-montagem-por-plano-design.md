# Vídeo feito como um editor humano faria (skill video)

## Por quê

Dois problemas do vídeo de hoje:

- **Ajuste caro.** A imagem está amarrada à voz: cada cena é um mp4 do tamanho
  exato da fala, e qualquer mudança passa por um agente que renderiza de novo.
- **Cara de gerado.** Forma geométrica perfeita, movimento mecânico e silêncio
  fora da fala denunciam que ninguém fez aquilo à mão.

O dono quer as duas coisas resolvidas:

- poder pedir ajuste de ritmo e ordem, fala, visual e acabamento sem
  retrabalho caro;
- um vídeo que pareça feito por uma pessoa com ferramentas de verdade. A voz
  pode continuar sintética; o resto não pode ter cara de gerado.

A suíte ArtCraft instalada é a ferramenta. É ambiente de teste, então app em
alfa não é motivo para evitar nenhum.

## Metas

- O fluxo segue o de um estúdio pequeno: roteiro e direção, arte, animação por
  plano, voz, som, edição e acabamento, cada etapa no app próprio.
- Cada plano vira um clipe com folga em movimento no fim, e a montagem
  absorve os ajustes.
- A identidade visual sai de uma biblioteca de ilustrações da série feita no
  VectorCraft, não de retângulos com texto.
- O vídeo tem desenho de som: efeitos que acompanham o que aparece, ambiente
  de fundo, música baixando sob a voz e voz tratada.
- O acabamento de movimento (easing com anticipation e overshoot, motion blur,
  grão, títulos) é o que um motion designer faria.

## Fora

- Gerar muito material sem roteiro: o teste do mudo depende da direção.
- Fazer a voz se passar por humana.

## Abordagens

- **A. Fatiar o mp4 da cena** nas fronteiras dos planos. Barato, mas a folga é
  quadro parado e o visual continua o mesmo.
- **B. Render por plano no manim (escolhida pelo dono)**, ampliada pelo dono
  para usar a suíte inteira como um humano usaria.

## Desenho, por etapa

| Etapa | App | O que sai |
|---|---|---|
| Roteiro e direção | (como hoje) | `roteiro.md`, `direcao.md` com a lista de ilustrações e de sons por plano |
| Arte | VectorCraft | biblioteca da série em `.vectorcraft`, exportada em SVG; miniatura |
| Textura | PhotoCraft | fundo com textura (papel, ruído) da identidade |
| Voz | OmniVoice | wav por plano, conferido pelo `ouvir.py`; vem antes da animação, como hoje, porque o `Cena` lê o tempo de cada fala |
| Animação | manim (diagramas exatos) e EffectCraft (personagens, títulos, transições) | um clipe por plano com folga |
| Som | SoundCraft | efeitos, ambiente, música com ducking, voz equalizada e comprimida, mix em -16 LUFS |
| Edição | FilmCraft | `montagem.fcproj`: clipes no tempo da voz, cortes J/L, punch-in, legendas |
| Acabamento | EffectCraft ou FilmCraft | grão, motion blur, correção de cor leve; `final.mp4` |

- **Render por plano.** As cenas já chamam `ate(n)` no fim de cada plano. No
  modo por plano, o `Cena` do `tema.py` fecha uma seção ali (`next_section`):
  espera o fim da fala, roda a folga e abre a seção seguinte. O render com
  `--save_sections` grava um mp4 por plano. Os tempos descontam as folgas
  anteriores, então as cenas existentes não mudam.
- **Ajustes pedidos pelo dono** são feitos nos projetos (`.fcproj`, `.scraft`,
  `.ecproj`):
  - fala mais curta: aparar o clipe, ou `clip.speedDuration` quando o corte
    pegaria a pose final;
  - fala que passa da folga: renderizar só aquela cena, sem agente;
  - visual: take alternativo, decidido na direção.
- **Folga:** respiro genérico de câmera (deriva e zoom de cerca de 1%) por
  `FOLGA` segundos, padrão 3. Ela volta ao enquadramento de repouso antes de
  acabar, e o clipe seguinte começa da pose exata. Na edição a folga é sobra:
  aparada, ou usada como cauda num corte J/L.
- **Ilustração no manim:** os SVGs da biblioteca entram como `SVGMobject` pelo
  kit da série, no lugar das formas desenhadas em código. A biblioteca é da
  série, desenhada na paleta da identidade. O dono vê a folha da biblioteca
  antes de animar, como já faz com a identidade.
- **Som:** o desenho de som entra em todo vídeo. A música continua perguntada
  ao dono, como hoje.
- **Legendas:** trilha de legenda exportada ao lado do vídeo, nunca queimada
  (a regra de não repetir a fala na tela continua).
- **Alcance:** o fluxo novo vira o padrão da skill para vídeo novo. Os pontos
  de aprovação e as rodadas dos revisores ficam como estão. O modo por plano é
  o padrão do `Cena`, e `PLANOS=0` volta ao mp4 por cena.
- **Piloto:** a primeira entrega é a aula 4 da série SO (entrada e saída),
  refeita no fluxo novo, para comparar lado a lado com a versão atual, que é a
  mais caprichada das quatro.
- **Biblioteca de assets:** `~/Design/Biblioteca/` guarda o material de terceiros
  (efeitos sonoros, ambientes, músicas, ícones, ilustrações, texturas), só com
  licença livre para uso, e um `LICENCAS.md` com a fonte e a licença de cada
  pacote.

## Para quem constrói

- Formato do take alternativo.
- Nome e lugar dos clipes e dos projetos de cada app.
- Como achar o asset certo na biblioteca (índice, nomes).
- Divisão entre manim e EffectCraft por tipo de plano.
- Texto da skill (fluxo, Montagem, Mudança pedida pelo dono) e o contrato dos
  agentes.
