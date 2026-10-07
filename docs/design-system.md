# Design system do desktop

Hyprland + Noctalia seguindo o macOS em superfície, barra e tipografia, com
cor, forma, espaço e movimento no Material 3 (M3). Este documento diz o que
cada decisão visual é, onde ela mora e como trazer um app novo para dentro do
sistema.

## Princípios

1. **Cada eixo tem um dono.** Cor, forma, espaço e movimento seguem o M3.
   Superfície, profundidade, barra e tipografia seguem o macOS. Misturar os
   dois no mesmo eixo é o que deixa o resultado incoerente.
2. **Cor indica foco e ação, não enfeite.** O `primary` aparece na janela
   focada, no item selecionado e no botão principal. O resto é superfície.
3. **Um valor, um lugar.** Todo token tem uma fonte só. Config escrito à mão
   consome o token, nunca copia o valor.
4. **Nada quica.** Movimento é rápido e assenta sem passar do ponto.

| Eixo | Dono | Resumo |
|---|---|---|
| Cor | M3 | Papéis de cor gerados pelo Noctalia |
| Superfície e profundidade | macOS | Fio de 1px, sombra suave, tudo opaco |
| Forma | M3 | Escala de raio curta, canto aninhado coerente |
| Espaçamento | M3 | Grade de 4px |
| Tipografia | macOS | Inter no papel da SF Pro, mono só em código |
| Barra | macOS | Menu bar: reta, cheia, fio só embaixo, sem sombra |
| Movimento | M3 | Curvas M3 e spring criticamente amortecida |
| Ícones | Papirus | Papirus-Dark nos apps, Tabler na shell |

## Cor

A paleta vem do Noctalia (`[theme]` em
`noctalia/.local/state/noctalia/settings.toml`), seja do wallpaper, seja de um
esquema pronto. O que o sistema fixa são os **papéis**, não os valores: trocar
a paleta na UI do Noctalia tem que mudar o desktop inteiro sem editar arquivo.

| Papel | Uso |
|---|---|
| `primary` | Foco e ação: item selecionado, botão principal |
| `secondary` | Destaque secundário: grupo ativo, segunda cor de gráfico |
| `surface` | Fundo de janela, painel e terminal |
| `on_surface` | Texto e fios sobre `surface` |
| `error` | Erro e ação destrutiva |

Só modo escuro (`[theme] mode = "dark"`), como o macOS escuro fixo. Superfícies
são em tom, não preto puro (`pure_black_dark` desligado). O M3 usa o tom para
separar planos (`surface` < container), e preto puro apaga essa hierarquia.

Como cada app recebe a paleta:

- **Template do Noctalia** (`theme.templates` no `settings.toml`): GTK 3/4,
  Hyprland, Alacritty, btop, cava, kitty e os da comunidade. O Noctalia
  reescreve os arquivos gerados a cada troca de paleta; eles ficam fora do git.
- **Hyprland**: não usa a paleta. A borda da janela é branca com alfa
  (`borders.lua`), como o fio neutro do macOS.
- **Ferramentas de terminal** (nvim, fzf, tmux, starship): usam as cores ANSI do
  terminal, que vêm do template do Alacritty. Cor nelas é índice ANSI (0 a 15),
  nunca hex.

Exceções: a sombra é preta com alfa (`look.lua`) e a borda da janela é branca
com alfa (`borders.lua`), em qualquer paleta.

## Superfície e profundidade

| Nível | O quê | Tratamento |
|---|---|---|
| 0 | Wallpaper | Nada |
| 1 | Janela | Fio de 1px + sombra (raio 28, deslocamento 0,6) |
| 2 | Barra, painel, launcher, notificação, OSD | Sólido: fundo opaco na cor da paleta + sombra |

- **Borda da janela**, em `borders.lua`: sem cor, como no macOS. Focada com
  branco a 25% (`40`), sem foco com branco a 8% (`14`). O foco se lê pelo
  degrau do fio, pela sombra maior e pelo `dim_inactive` (0,08) nas outras.
- **Sombra**: alfa 0,35 em todo o sistema. Janela focada `0x59000000` em
  `look.lua` (0x59 ≈ 0,35), e a shell com `[shell.shadow] alpha = 0.35` no
  Noctalia. Janela sem foco cai para `0x33000000`, então a focada fica
  visualmente mais perto.
- **Sem transparência nem blur**, nem na shell: a cor da tela vem só da
  paleta, e texto nunca fica por cima de texto. No Noctalia,
  `background_opacity = 1.0` na barra e no OSD,
  `settings_window_translucent = false` no `[shell]` e `transparency_mode` no
  padrão (`"solid"`, que o Noctalia omite do arquivo). No Hyprland,
  `blur = { enabled = false }` em `look.lua`.

## Forma

Escala de raio: `0 · 4 · 8 · 12 · 16 · 28`. Nenhum raio fora dela.

| Elemento | Raio |
|---|---|
| Janela | 12 com `rounding_power = 2.5`, que puxa para o canto contínuo do macOS |
| Painéis do Noctalia | Escala interna do Noctalia (`corner_radius_scale` no padrão 1.0) |
| Caixa de login da tela de bloqueio | 12, campo 6 |
| Barra | 0: reta, largura cheia, colada no topo, como a menu bar do macOS |

Regras:

- **Encostou na borda da tela, não tem canto convexo nesse lado.** A barra
  ocupa a largura toda e fica reta.
- **Toda superfície tem o fio neutro de 1px**, igual ao da janela sem foco
  (painéis: `[shell.panel] borders`). Só a janela focada leva o fio com
  `primary`. Na barra o fio fica só embaixo, sem sombra, como a menu bar do
  macOS: o Noctalia não controla a borda por lado, então `margin_edge = -1` e
  `margin_ends = -1` empurram o fio de cima e os laterais 1px para fora da tela.
- **Painel cai logo abaixo da barra.** Central de controle, sessão, wallpaper e
  clipboard flutuam em `top_center`. O launcher e o diálogo do polkit abrem no
  centro da tela.
- **Cor de borda no Noctalia só aceita papel do tema ou hex.**
  `outline_variant` não é aceito, e um valor inválido faz o Noctalia descartar
  o `settings.toml` inteiro e voltar à barra padrão. Rode
  `noctalia config validate` depois de editar o arquivo à mão.
- **Canto aninhado**: raio de dentro = raio de fora menos o padding entre os
  dois. Um cartão de raio 16 com padding 8 leva botão de raio 8.

## Espaçamento

Grade de 4px. Todo espaçamento é múltiplo de 4.

| Onde | Valor |
|---|---|
| Entre janelas (`gaps_in`) | 4, e o espaço visível entre duas janelas fica 8 |
| Janela até a borda da tela (`gaps_out`) | 8 |
| Padding do terminal | 16 na horizontal, 12 na vertical |
| Barra | altura 38 (37 visíveis, a menu bar dos MacBook com notch), padding 16, espaço entre widgets 12 |

## Tipografia

A família mora em um lugar só:
`desktop/.config/fontconfig/conf.d/50-fontes.conf` faz `sans-serif` resolver
para **Inter** e `monospace` para **JetBrainsMono Nerd Font**. Os apps pedem o
nome genérico:

| App | Pede |
|---|---|
| GTK 3/4 (`settings.ini`) | `Sans 10` |
| Apps libadwaita (gsettings, aplicado pelo `install.sh`) | `Sans 10` e `Monospace 10` |
| Qt | Segue o GTK (`QT_QPA_PLATFORMTHEME=gtk3`) |
| Noctalia | `sans-serif` (padrão; sem `font_family` no `settings.toml`) |
| Alacritty | `JetBrainsMono Nerd Font` pelo nome |

O Alacritty é a exceção: pede a família pelo nome, para o terminal não depender
do alias.

Tamanho base 10pt (13px a 96 dpi), perto dos 13px do macOS. Hierarquia por peso
e tamanho, nunca por cor. A Inter faz o papel da SF Pro, que só é licenciada
para hardware Apple; na barra vale a Inter comum (não a Display), que é a
versão para tamanho pequeno, como a SF Text. A barra segue a menu bar do
macOS: à esquerda o workspace e a janela ativa (a janela em negrito, 700, como
o nome do app no macOS); à direita a bandeja e os extras, depois bateria, rede,
bluetooth, volume, o botão da central de controle e o relógio no formato do
macOS em pt-BR (`sáb. 26 de set. 18:21`). O resto fica no peso padrão.

## Movimento

Tokens em `hypr/.config/hypr/animations.lua`:

| Curva | Tipo | Uso |
|---|---|---|
| `standard` | bezier (0.2, 0, 0, 1) | Mudança de estado no lugar: borda, fade, zoom |
| `decelerate` | bezier (0.05, 0.7, 0.1, 1) | Algo entrando: layer, workspace, fade in |
| `accelerate` | bezier (0.3, 0, 0.8, 0.15) | Algo saindo: fechar janela, fade out |
| `snappy` | spring, massa 1, rigidez 880, amortecimento 59 | Janela abrindo e se movendo |

| Duração | Valor | Uso |
|---|---|---|
| Curta | 100 a 150 ms (`speed` 1 a 1.5) | Saída, borda, fade |
| Média | 250 ms (`speed` 2.5) | Entrada, workspace, layer |

Regras:

- Entrada desacelera; saída acelera e é mais curta que a entrada.
- Em curva spring, o `speed` não define a duração, quem define é a rigidez
  com o amortecimento. `snappy` tem amortecimento crítico (ζ ≈ 1): assenta em
  uns 200 ms sem passar do ponto. Desde o Hyprland 0.56 as springs precisam de
  2 a 3 vezes mais rigidez que antes ([discussão
  #15495](https://github.com/hyprwm/Hyprland/discussions/15495)).
- Workspace troca com `slidefade 15%`: desliza pouco, só o suficiente para
  dizer de que lado veio.
- No Noctalia, `shell.animation.speed` é um multiplicador. Está em 2.0, o dobro
  do padrão, para acompanhar o Hyprland.
- **A shell anima a si mesma.** A regra de layer `shell-motion`
  (`windowrules.lua`) tira a animação do Hyprland das camadas `noctalia-*`.
  Com as duas ligadas, o fade do Hyprland somava por cima da animação do
  Noctalia, e o painel levava uns 40 ms a mais para assentar.

## Ícones

- **App** (launcher, bandeja, dock, gerenciador de arquivos): Papirus-Dark, do
  pacote `papirus-icon-theme`.
- Quem lê o tema: GTK (`settings.ini`), apps libadwaita (gsettings) e o Noctalia
  (lê o `gtk-3.0/settings.ini`). O `install.sh` ajusta os dois que ficam fora do
  repo.
- **Glifos da shell** (barra e painéis do Noctalia): fonte Tabler embutida. O
  config escolhe qual glifo vai em cada lugar (`launcher_icon`, `glyph` das
  ações de sessão), mas o conjunto não troca: o Noctalia só carrega o
  `noctalia-tabler.ttf` do pacote.

## Onde cada token mora

| Token | Arquivo | Escrito ou gerado |
|---|---|---|
| Paleta e templates | `noctalia/.local/state/noctalia/settings.toml` | Escrito (pela UI do Noctalia) |
| Cores no Hyprland | `hypr/.config/hypr/noctalia.lua` | Gerado, não usado |
| Borda da janela | `hypr/.config/hypr/borders.lua` | Escrito |
| Raio, sombra, gaps, blur desligado | `hypr/.config/hypr/look.lua` | Escrito |
| Opacidade da shell | `[bar]`, `[osd]`, `[shell]` e `[shell.panel]` no `settings.toml` | Escrito |
| Movimento | `hypr/.config/hypr/animations.lua` | Escrito |
| Família de fonte | `desktop/.config/fontconfig/conf.d/50-fontes.conf` | Escrito |
| Fonte e ícones no GTK | `desktop/.config/gtk-{3,4}.0/settings.ini` | Escrito |
| Tema do terminal | `~/.config/alacritty/themes/noctalia.toml` | Gerado, fora do git |

O `borders.lua` é o único lugar que define cor de borda. O `apply_theme()` do
`noctalia.lua` gerado não é chamado, porque ele sobrescreveria a borda.

O `settings.toml` é reescrito inteiro pela UI do Noctalia a cada mudança. Edite
o arquivo com a tela de configurações fechada, senão uma das duas escritas se
perde.

## Trazendo um app novo

1. A cor vem da paleta? Se o Noctalia tem template para ele, ligue em
   `theme.templates`. Se é de terminal, use índice ANSI.
2. A fonte vem do alias? Peça `sans-serif`/`Sans` ou `monospace`, nunca a
   família pelo nome.
3. Raio e espaçamento estão na escala?
4. Tem animação própria? Use as durações e curvas daqui.
5. É exceção? Registre abaixo, com o motivo.

## Exceções registradas

| Onde | O quê | Por quê |
|---|---|---|
| `windowrules.lua`, `pip-float` | Picture-in-Picture sem borda e opaco | O vídeo é o conteúdo; fio e transparência atrapalham |
| `alacritty.toml` | Família de fonte pelo nome | Escolha explícita, para o terminal não depender do alias |
| `look.lua`, sombra | Preto literal | Sombra não muda de cor com a paleta |
| `settings.toml`, `[bar.default] border` | `#ffffff14`, cópia do `inactive_border` do `borders.lua` | O Noctalia não lê o Hyprland; o fio da barra tem que ser igual ao da janela |
| `keymaps.lua`, `SUPER+SHIFT+G` | Zera gaps, borda e raio | Modo para compartilhar tela; restaura os valores do `look.lua` |
