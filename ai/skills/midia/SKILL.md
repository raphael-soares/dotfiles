---
name: midia
description: >
  Use para qualquer coisa do Netflix local do dono (Jellyfin, Radarr, Sonarr,
  Bazarr, qBittorrent no PC fedora, plugin Arr Pick do Stremio): achar ou
  adicionar filme, série ou anime; legendas e áudio; apagar; o que ele
  assistiu e recomendações; downloads parados; o que a pilha fez ou por que
  algo quebrou.
---

# Netflix local

Tudo passa por `mediactl` (no PATH, de `media/bin` do dotfiles). Só roda no PC
`fedora`. Para o que o `mediactl` não cobre, `source ~/.local/bin/media-lib.sh`
dá `api <radarr|sonarr|prowlarr|bazarr|jellyfin> <MÉTODO> <caminho>` e
`qbt <caminho>`, já autenticados. Como a pilha funciona: `docs/media.md` do
dotfiles.

Nada baixa sozinho. O dono escolhe cada release no Stremio Enhanced com o
plugin Arr Pick: o botão redondo de download ao lado do play, numa linha do
Torrentio, ou "Baixar" no menu do botão direito. O plugin adiciona o título no
Radarr ou no Sonarr e manda aquele release. O botão mostra o progresso, e
clicar nele de novo para o download. Você não escolhe release.

## Comandos

| Quero | Comando |
|---|---|
| Achar título e ver se já está na biblioteca | `mediactl search "dune"` |
| Adicionar sem baixar | `mediactl add movie tt1160419` / `mediactl add tv 76885 1,2` |
| Arquivo, qualidade, tamanho, áudio e legenda do que já tem | `mediactl info "la haine"` / `mediactl info jojo` |
| Idiomas de áudio no Jellyfin | `mediactl audio "Frightening Monsters"` |
| Legendas: o que falta em toda a biblioteca, ou de um título | `mediactl subs` / `mediactl subs jojo` |
| Downloads | `mediactl queue` |
| Disco, tags, downloads, saúde e falhas da semana | `mediactl status` |
| O que a pilha fez e o que falhou, com hora | `mediactl log` / `mediactl log 200` |
| O que cada pessoa assistiu por último | `mediactl watched 30` |
| Apagar o arquivo e não baixar de novo | `mediactl delete "dune"` / `mediactl delete jojo 6 1` |
| Importar à força um download | `mediactl import jojo ~/Media/Downloads/Shows/<pasta> --grep S06E10` |

## Fluxos

- **Pedir:** diga ao dono para abrir o título no Stremio e clicar na versão
  que quiser. Leva cerca de um minuto entre o 100% do `queue` e
  o item aparecer no Jellyfin.
- **Adicionar sem baixar** (para acompanhar ou baixar depois): `search` dá o
  id (imdb para filme, tvdb para série), depois `add`. Toda série, anime
  incluso, vai para `~/Media/Shows`; anime ganha o tipo anime pelo gênero.
- **Recomendar:** parta de `watched` (o gosto real) e de `search` para saber
  o que já tem. Proponha; quem baixa é o dono, pelo Stremio.
- **Algo não apareceu ou quebrou:** `status`, depois `log`. Download parado há
  6 h, ou 4K que levaria mais de 12 h, sai da fila e do qBittorrent sozinho
  (`media-torrents`) e o dono recebe um aviso para escolher outra versão.
  Importação travada (`importPending`/`importBlocked`): `import`.
- **Apagar:** é irreversível e só com confirmação explícita do dono para
  aquele título. Também pode ser feito no próprio Jellyfin; nos dois casos o
  item deixa de ser vigiado e o torrent sai pela limpeza.

## Dublado

O nome do release raramente diz "PT-BR". Depois do download, confira com
`audio` ou `info`. Se não veio o áudio esperado, o arquivo precisa sair antes
(`delete`, com confirmação do dono), porque o perfil Manual não troca arquivo;
depois o dono escolhe outra versão no Stremio.

## Erros comuns

- `info`, `subs`, `import` e `delete` precisam do título no Radarr ou no
  Sonarr. O termo casa com o primeiro título que o contém, filme antes de
  série; seja específico.
- "has no Manual profile": o perfil vem do configarr; rode
  `media-deploy ~/.dotfiles`.
- Não mude configuração pela API à mão: ela vem do repo (`media/configarr`,
  `media/bin/media-deploy`) e a conferência diária acusa a diferença. Mude o
  repo e rode `media-deploy ~/.dotfiles`.
