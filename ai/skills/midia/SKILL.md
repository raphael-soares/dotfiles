---
name: midia
description: >
  Use para qualquer coisa do Netflix local do dono (Jellyfin, Seerr, Radarr,
  Sonarr, Bazarr, qBittorrent no PC fedora): achar, pedir ou baixar filme,
  série ou anime; trocar release, dublado ou qualidade; legendas e áudio;
  apagar; o que ele assistiu e recomendações; downloads parados; o que a
  pilha fez ou por que algo quebrou.
---

# Netflix local

Tudo passa por `mediactl` (no PATH, de `media/bin` do dotfiles). Só roda no PC
`fedora`. Para o que o `mediactl` não cobre, `source ~/.local/bin/media-lib.sh`
dá `api <radarr|sonarr|prowlarr|bazarr|seerr|jellyfin> <MÉTODO> <caminho>` e
`qbt <caminho>`, já autenticados. Como a pilha funciona: `docs/media.md` do
dotfiles.

## Comandos

| Quero | Comando |
|---|---|
| Achar título e ver se já tem | `mediactl search "dune"` |
| Pedir filme ou série | `mediactl request movie 438631` / `mediactl request tv 45790 1,2` |
| Arquivo, qualidade, tamanho, áudio e legenda do que já tem | `mediactl info "la haine"` / `mediactl info jojo` |
| Idiomas de áudio no Jellyfin | `mediactl audio "Frightening Monsters"` |
| Legendas: o que falta em toda a biblioteca, ou de um título | `mediactl subs` / `mediactl subs jojo` |
| Releases de um filme ou episódio | `mediactl releases "dune"` / `mediactl releases jojo 6 10` |
| Filtrar releases (regex, maiúscula importa) | `--grep '\bMULTi\b'`, `--limit 10`, `--why` mostra a rejeição |
| Baixar o release N da última lista | `mediactl grab 3` |
| Mandar o Radarr/Sonarr buscar de novo | `mediactl research "dune"` / `mediactl research jojo 6` / `mediactl research jojo 6 10` |
| Downloads | `mediactl queue` |
| Disco, tags, downloads, saúde e falhas da semana | `mediactl status` |
| O que a pilha fez e o que falhou, com hora | `mediactl log` / `mediactl log 200` |
| O que cada pessoa assistiu por último | `mediactl watched 30` |
| Apagar o arquivo e não baixar de novo | `mediactl delete "dune"` / `mediactl delete jojo 6 1` |
| Importar à força um download | `mediactl import jojo ~/Media/Downloads/Anime/<pasta> --grep S06E10` |

## Fluxos

- **Pedir:** `search`; sem `[available]` nem `[partial]`, `request`. O Seerr
  manda ao Radarr ou Sonarr, que escolhem o release pelo perfil (4K com 1080p
  de reserva, até 120 MB por minuto) e baixam sozinhos. Leva cerca de um
  minuto entre o 100% do `queue` e o item aparecer no Jellyfin.
- **Release específico** (dublado, outro grupo, menor): o título tem de estar
  no Radarr ou no Sonarr. `releases`, depois `grab N`.
- **Recomendar:** parta de `watched` (o gosto real) e de `search` para saber
  o que já tem. Proponha antes de pedir; só peça o que o dono aprovar.
- **Algo não apareceu ou quebrou:** `status`, depois `log`. Download parado
  sem semente é trocado sozinho em 6 h pelo `media-torrents`; 4K lento vira
  1080p. Importação travada (`importPending`/`importBlocked`): `import`.
- **Apagar:** é irreversível e só com confirmação explícita do dono para
  aquele título. Também pode ser feito no próprio Jellyfin; nos dois casos o
  item deixa de ser vigiado e o torrent sai pela limpeza.

## Dublado

- O nome do release raramente diz "PT-BR". O perfil Anime pontua release de
  Netflix com `MULTi` (VARYG, ToonsHub MULTi), que costuma trazer áudio `por`;
  `DUAL` é só japonês e inglês, e `MULTi` da Tsundere-Raws é francês. Confira
  com `audio` ou `info`.
- `rejected` com "equal or higher Custom Format score" não impede o `grab`,
  mas o Sonarr pode recusar importar; aí use `import`.

## Erros comuns

- `releases`, `info`, `subs`, `research` e `delete` precisam do título no
  Radarr ou no Sonarr: faça `request` antes. O termo casa com o primeiro título
  que o contém, filme antes de série; seja específico.
- `grab` usa a última lista de `releases`.
- `releases` leva de 30 s a 2 min, porque consulta todos os indexers.
- Não mude configuração pela API à mão: ela vem do repo (`media/configarr`,
  `media/bin/media-deploy`) e a conferência diária acusa a diferença. Mude o
  repo e rode `media-deploy ~/.dotfiles`.
