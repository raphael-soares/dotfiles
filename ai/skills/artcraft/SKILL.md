---
name: artcraft
description: >
  Use para qualquer trabalho com os apps do ArtCraft no PC fedora (VectorCraft,
  PhotoCraft, LightCraft, FilmCraft, EffectCraft, SoundCraft, WordCraft,
  GridCraft, PdfCraft): logo, vetor, edição de foto, vídeo, motion, áudio,
  narração, documento, planilha, PDF; quando o dono pede para abrir a janela,
  quer ver o que está sendo feito, ou um servidor do app dá erro.
---

# Apps do ArtCraft

Cada app é um servidor MCP no omp (`craft-mcp <app>`, do módulo `creative` do
dotfiles). Ele trabalha sem janela até o dono pedir para ver; aí a ferramenta
`open_window` abre o app no arquivo salvo e daí em diante o agente e o dono
mexem no mesmo documento, com o mesmo Histórico e o mesmo Ctrl+Z. Como funciona
por dentro: `docs/creative.md` do dotfiles.

## Qual app

| Trabalho | App | Formato nativo |
|---|---|---|
| Vetor, logo, ilustração, ícone | VectorCraft | `.vectorcraft` |
| Edição e montagem de foto, camadas | PhotoCraft | `.pcraft` |
| Biblioteca de fotos, revelação de raw | LightCraft | catálogo do app; o resultado sai por `export` |
| Edição de vídeo, timeline | FilmCraft | `.fcproj` |
| Motion graphics, título animado | EffectCraft | `.ecproj` |
| Áudio, narração, mixagem | SoundCraft | `.scraft` |
| Documento de texto | WordCraft | `.docx`; não tem janela |
| Planilha | GridCraft | `.xlsx` |
| PDF pronto (páginas, preencher, assinar) | PdfCraft | o próprio `.pdf`; não tem janela |

## Regras

- **Sem janela por padrão.** `open_window` só quando o dono pedir ("abre a
  janela", "quero ver", "me mostra no app"). Oferecer no fim está ok; chamar
  por conta própria, não.
- **Projeto em `~/Creative/Projetos/<projeto>/<peça>/`**, uma pasta por peça entregue e o comum na raiz do projeto, salvo no formato nativo da tabela. SVG,
  PNG, PDF e afins são exportação: só quando o dono pedir, ao lado do nativo.
- **Texto continua texto.** Nada de converter em contorno ou curva, a não ser
  que o dono peça.
- **Antes de `open_window`:** salve e passe o caminho. O que não foi salvo no
  motor sem janela não vai para a janela.
- **Com a janela aberta:** o dono também mexe. Leia o estado atual
  (`doc_inspect` ou o equivalente do app) antes de cada mudança e trabalhe no
  documento aberto, nunca numa cópia. Um pedido do dono vira um lote só
  (`command_batch`, `batch`) com rótulo legível, para um Ctrl+Z desfazer o
  pedido inteiro. Com a janela aberta, não chame `open_window` de novo.
- **Fechar a janela é do dono.** Peça para ele fechar (e salvar, se quiser
  guardar o que mexeu). Nunca `pkill`, menu Sair ou atalho.
- **Janela fechada:** a próxima chamada falha uma vez com "window was closed ...
  Open <caminho> to continue". Abra esse arquivo de novo antes de seguir.
- **Comandos pelo próprio app.** Os apps estão em alfa e mudam nomes entre
  versões. Antes de usar uma ferramenta de memória, consulte `command_list`
  (ou `list_commands`) e as instruções que o servidor manda no `initialize`.
- **Antes de dizer pronto:** `render_preview` (ou `render_page`,
  `render_frame`), olhe a imagem e corrija o que estiver errado.
- **Erro do servidor:** repasse a mensagem ao dono em vez de contornar. "close
  and reopen VectorCraft" quer dizer: o app foi aberto antes do deploy e não
  escuta o agente; peça para fechar e abrir de novo, depois chame
  `open_window` outra vez.

## Erros comuns

- PhotoCraft só aceita caminho dentro de `~/Creative`; fora dela recusa com
  "automation path rejected".
- LightCraft lista as ferramentas em modo compacto: o que não estiver na lista
  roda por `run_command` depois de `command_list`.
- PdfCraft e WordCraft não têm `open_window`. Se o dono quiser ver, salve e
  diga o caminho: ele abre o arquivo à mão, sem histórico compartilhado.
- App que não aparece no omp não foi instalado pelo ArtCraft Launcher, ou foi
  instalado depois do último deploy: `dotter deploy` e `/mcp reload`.
