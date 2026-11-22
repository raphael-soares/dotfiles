---
name: midia-buscar
description: >
  Use quando o dono pedir para achar, baixar ou pedir filme, série, anime ou
  episódio no Netflix local (Jellyfin, Seerr, Radarr, Sonarr, qBittorrent no PC
  fedora), quando quiser versão dublada, legendada ou de outro grupo, ou quando
  um episódio baixado não aparece no Jellyfin.
---

# Buscar mídia no Netflix local

Tudo passa por `python3 ~/.dotfiles/ai/skills/midia-buscar/midia.py`, que lê as
chaves de `~/.config/media/media.env` e do `settings.json` do Seerr. Só roda no
PC `fedora`, onde a pilha está no ar.

| Quero | Comando |
|---|---|
| Achar título e ver se já tem | `midia.py search "dune"` |
| Pedir filme ou série inteira | `midia.py request movie 438631` / `request tv 45790 --seasons 1,2` |
| Ver releases de um episódio | `midia.py releases jojo --season 6 --episode 10` |
| Ver releases de um filme | `midia.py releases "dune"` |
| Filtrar releases (regex, maiúscula importa) | `--grep '\bMULTi\b'`, `--why` mostra o motivo da rejeição |
| Baixar o release N da última lista | `midia.py grab 3` |
| Acompanhar downloads | `midia.py queue` |
| Ver idiomas de áudio do que já está no Jellyfin | `midia.py audio "Frightening Monsters"` |
| Importar à força um arquivo baixado | `midia.py import jojo ~/Media/Downloads/Anime/<pasta> --grep S06E10` |

## Fluxo

1. `search`. Sem `[available]` nem `[partial]`, faça `request`: o Seerr manda
   para o Radarr ou o Sonarr, que baixam sozinhos. Anime é roteado para a
   pasta e a categoria Anime pela tag `anime` do Sonarr.
2. Para um release específico (dublado, outro grupo, outra qualidade), o
   título tem de já estar no Radarr ou no Sonarr: `releases`, depois `grab N`.
3. `queue` até 100%. O Sonarr ou o Radarr importa e avisa o Jellyfin; o item
   aparece no app sem refresh manual.

## Dublado

- O nome do release raramente diz "PT-BR". Release de Netflix com `MULTi`
  (VARYG, ToonsHub MULTi) costuma trazer áudio `por`; `DUAL` é só japonês e
  inglês. Confira depois com `audio`.
- `rejected` com "equal or higher Custom Format score" não impede o `grab`,
  mas o Sonarr pode recusar importar porque não vê melhora. Se o `queue` mostrar
  o download parado em `importPending` ou `importBlocked`, use `import` com a
  pasta do download.

## Erros comuns

- `releases` sem o título no Sonarr ou no Radarr: faça `request` antes.
- `grab` usa a última lista de `releases` (`/tmp/agents/midia-releases.json`);
  rode `releases` de novo se trocar de episódio.
- A busca de releases leva de 30 s a 2 min, porque consulta todos os indexers.
