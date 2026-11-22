---
name: midia-buscar
description: >
  Use quando o dono pedir para achar, baixar ou pedir filme, série, anime ou
  episódio no Netflix local (Jellyfin, Seerr, Radarr, Sonarr, qBittorrent no PC
  fedora), quando quiser versão dublada, legendada ou de outro grupo, ou quando
  um episódio baixado não aparece no Jellyfin.
---

# Buscar mídia no Netflix local

Tudo passa por `mediactl` (no PATH, vem de `media/bin` do dotfiles), que usa o
`media-lib.sh` da pilha para ler as chaves de `~/.config/media/media.env` e do
`settings.json` do Seerr. Só roda no PC `fedora`, onde a pilha está no ar.

| Quero | Comando |
|---|---|
| Achar título e ver se já tem | `mediactl search "dune"` |
| Pedir filme ou série inteira | `mediactl request movie 438631` / `mediactl request tv 45790 1,2` |
| Ver releases de um episódio | `mediactl releases jojo 6 10` |
| Ver releases de um filme | `mediactl releases "dune"` |
| Filtrar releases (regex, maiúscula importa) | `--grep '\bMULTi\b'`, `--limit 10`, `--why` mostra o motivo da rejeição |
| Baixar o release N da última lista | `mediactl grab 3` |
| Acompanhar downloads | `mediactl queue` |
| Ver disco, tags, downloads e problemas de uma vez | `mediactl status` |
| Ver idiomas de áudio do que já está no Jellyfin | `mediactl audio "Frightening Monsters"` |
| Importar à força um arquivo baixado | `mediactl import jojo ~/Media/Downloads/Anime/<pasta> --grep S06E10` |

## Fluxo

1. `search`. Sem `[available]` nem `[partial]`, faça `request`: o Seerr manda
   para o Radarr ou o Sonarr, que baixam sozinhos. Anime é roteado para a
   pasta e a categoria Anime pela tag `anime` do Sonarr.
2. Para um release específico (dublado, outro grupo, outra qualidade), o
   título tem de já estar no Radarr ou no Sonarr: `releases`, depois `grab N`.
3. `queue` até 100%. O Sonarr ou o Radarr importa e avisa o Jellyfin, que leva
   cerca de um minuto para mostrar o item.

## Dublado

- O nome do release raramente diz "PT-BR". O perfil Anime já pontua release de
  Netflix com `MULTi` (VARYG, ToonsHub MULTi), que costuma trazer áudio `por`;
  `DUAL` é só japonês e inglês, e `MULTi` da Tsundere-Raws é francês. Confira
  depois com `audio`.
- `rejected` com "equal or higher Custom Format score" não impede o `grab`,
  mas o Sonarr pode recusar importar porque não vê melhora. Se o `queue` mostrar
  o download parado em `importPending` ou `importBlocked`, use `import` com a
  pasta do download.

## Erros comuns

- `releases` sem o título no Sonarr ou no Radarr: faça `request` antes.
- `grab` usa a última lista de `releases`; rode `releases` de novo se trocar de
  episódio.
- A busca de releases leva de 30 s a 2 min, porque consulta todos os indexers.
