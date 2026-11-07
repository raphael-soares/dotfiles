---
name: switch-mtp
description: >
  Operar o Nintendo Switch com CFW (CNX pack) pelo MTP do DBI a partir do Linux/KDE:
  instalar jogo (NSP/NSZ/XCI/XCZ), listar e baixar arquivos do cartao, backup de save
  e screenshot, e pente fino em crash de homebrew (crash_reports do Atmosphere, log do
  Ship of Harkinian, save corrompido). Use quando o usuario falar de Switch, MTP, DBI,
  instalar jogo no Switch, ver arquivo do cartao SD, save, ou crash de SoH / 2Ship.
---

# Switch por MTP (DBI + KIO)

Console deste usuario: CNX pack `22.5.0-2` (Atmosphere + hekate + emuMMC), DBI como
gerenciador de titulos, sphaira como menu de homebrew.

## Como funciona aqui

Ligue o console, abra o DBI, escolha `Run MTP responder`. O Linux nao monta nada: o
KDE fala MTP pelo worker KIO `/usr/lib64/qt6/plugins/kf6/kio/mtp.so`, e tudo passa por
`kioclient` com URL `mtp:/`.

- `gvfs-mtp` **nao** e usado neste sistema e nao precisa estar instalado. Se `gio mount -li`
  nao mostra o Switch, isso nao diz nada.
- `kio-fuse` **recusa** MTP (`SchemeNotSupported`). Nao existe caminho POSIX para o cartao.
  Ferramenta que precisa de arquivo real (`7z`, `unzip`, `md5sum`, `jq`) exige baixar antes.
- Uma sessao MTP por vez. Rode os comandos em serie. Encadear/aninhar chamadas de
  `kioclient` em pipeline chegou a travar por minutos no DBI.

Conferir que esta tudo de pe:

```bash
lsusb | grep 057e:201d          # "Nintendo Co., Ltd DBI" = responder ativo
kioclient ls mtp:/              # -> "DBI MTP Responder"
```

Os helpers ficam em `skill://switch-mtp/helpers.sh`:

```bash
source .omp/skills/switch-mtp/helpers.sh
sdconn                          # USB + storages
sdls switch/soh_debug           # listar
sdtree switch 2                 # arvore com profundidade
sdcat cnx.txt                   # ler texto
sdget switch/soh_debug/logs /tmp/           # baixar
sdput ./switch ""                           # enviar para a raiz do cartao
sdsize switch/soh_debug/soh.nro             # bytes
sdverify ./local/soh.nro switch/soh_debug/soh.nro   # compara por md5
sdinstall jogo.nsp                          # instala no cartao
sdinstall jogo.nsp nand                     # instala na memoria interna
sdtitles                                    # titulos instalados
sdlogs /tmp/switch-logs                     # puxa todos os logs de crash
```

## As 8 storages do DBI

| Storage | Serve para |
|---|---|
| `1: SD Card` | o cartao inteiro. E aqui que mora quase tudo |
| `2: Nand USER` | particao USER da NAND (`save`, `Contents`, `Album`) |
| `3: Nand SYSTEM` | **nao escreva**. Brick facil |
| `4: Installed games` | titulos instalados; da para baixar de volta como NSP. Tem o `InstalledApplications.csv` |
| `5: SD Card install` | pasta virtual de instalacao: copiar NSP aqui instala no cartao |
| `6: NAND install` | idem, instalando na memoria interna |
| `7: Saves` | saves por jogo, em `Installed games` e `Uninstalled games` |
| `8: Album` | screenshots e videos |

## Comandos crus

```bash
SD="mtp:/DBI MTP Responder/1: SD Card"
kioclient ls    "$SD/switch"
kioclient stat  "$SD/switch/soh_debug/soh.nro"       # SIZE, FILE_TYPE
kioclient cat   "$SD/cnx.txt"
kioclient copy  "$SD/arquivo" /tmp/                  # baixar
kioclient copy  ./pasta "$SD/destino/"               # enviar, recursivo
kioclient mkdir "$SD/nova"
kioclient remove "$SD/pasta"                         # apaga pasta cheia, sem perguntar
```

Detalhes que custam tempo se ignorados:

- A URL inteira vai entre aspas. O `1: ` do nome da storage faz parte do caminho.
- Sobrescrever exige `--overwrite`, senao da `A file named ... already exists`.
- `remove` apaga pasta com conteudo dentro e nao pede confirmacao. Nao tem lixeira.
- Data de modificacao chega como `Dec 31 1969` em tudo. Nunca compare por data:
  compare `SIZE` e, quando importa, md5 do arquivo baixado (`sdverify`).
- Velocidade medida neste console: leitura 37 MB/s (4,06 GB em 110 s), escrita 17 MB/s
  (51 MB em 3,0 s). Copiar o pacote HD de 4 GB leva uns 4 minutos. Se for mexer em
  varios gigas, leitor de cartao no PC ganha de longe.

## Instalar titulo

```bash
kioclient copy jogo.nsp "mtp:/DBI MTP Responder/5: SD Card install/"
```

Aceita NSP, NSZ, XCI, XCZ e MSP. A pasta e virtual: o arquivo nao "fica" la, ele e
consumido pelo instalador do DBI, que mostra o progresso na tela do console.

Verificar depois, sempre pela lista de titulos, nunca pelo status do comando:

```bash
sdtitles     # ou: kioclient cat "mtp:/DBI MTP Responder/4: Installed games/InstalledApplications.csv"
```

Erro `Could not write to file <nome>.nsp` significa arquivo invalido ou corrompido,
rejeitado pelo instalador (testado de proposito com um NSP falso: nada foi instalado).
Nao e caminho errado.

## Pente fino em crash de homebrew

Mapa completo de onde ha evidencia, com o que cada lugar entrega:

| Caminho | Conteudo |
|---|---|
| `atmosphere/crash_reports/<unixts>_<titleid>.log` | relatorio do Atmosphere: `Result`, tipo de excecao, registradores, stack de todas as threads |
| `atmosphere/crash_reports/<unixts>_<titleid>.jpg` | framebuffer do momento. Em homebrew vem preto, nao serve |
| `atmosphere/crash_reports/dumps/` | dumps binarios |
| `atmosphere/fatal_reports/` | tela de erro fatal do sistema (mais raro que crash_report) |
| `atmosphere/erpt_reports/` | relatorios da propria Nintendo, centenas de UUIDs. Ruido, ignore |
| `switch/soh_debug/logs/Ship of Harkinian.log` | log do SoH, com arquivo e linha do fonte. **A melhor fonte** |
| `switch/2ship/logs/` | mesmo esquema para Majora's Mask (2Ship) |
| `switch/soh_debug/Save/` | `file1.sav`, `global.sav` e, quando houve escrita interrompida, `file1.temp` |
| `switch/DBI/logs/` | log do DBI (costuma estar vazio) |

Title ids uteis: `01743b480fde0000` = forwarder do OoT (SoH), `01e6f9ce66d50000` = Majora's Mask,
`05446530aca7e000` = sphaira. Homebrew rodando por forwarder aparece como
`Process Name: Forwarder`; rodando pelo sphaira, como `Application` com o id do sphaira.

### Triagem de crash report

O binario e carregado com ASLR, entao endereco absoluto muda a cada boot e dois
relatorios do mesmo bug parecem diferentes. Normalize pelo delta em relacao ao PC:

```bash
for f in *.log; do
  pc=$(awk '/Crashed Thread Info/,/Stack Trace/' "$f" | awk '/PC:/{print $2; exit}')
  printf "%s  " "$f"
  awk '/Crashed Thread Info/,/Stack Dump/' "$f" | awk '/ReturnAddress/{print $2}' |
    while read -r r; do printf "%+d " $(( 0x$r ? 0x$r - 0x$pc : 0 )); done
  echo
done
```

Deltas iguais = mesmo bug, mesmo caminho de codigo, ainda que os enderecos absolutos
nao batam. Ler tambem:

- `Result: 0x2A8 (2168-0001)` e o crash generico reportado pelo creport; `0x4A8 (2168-0002)`
  aparece nos Data Abort.
- `Type: Data Abort` com `Fault Address: 0000000000000000` e ponteiro nulo.
  `Instruction Abort` e salto para endereco nao executavel, tipico de `std::terminate`
  depois de excecao C++ nao capturada numa thread.
- Se o bloco `Module Info` listar o modulo (`Name: soh`), o relatorio ja vem simbolizado
  como `soh + 0x276f4ec`, e da para comparar offsets entre relatorios direto.

### Log do SoH: onde ele para e o que isso diz

Sequencia de um boot saudavel:

```
OTRGlobals.cpp:820  Starting Ship of Harkinian version ...
ArchiveManager.cpp  Reading archive / Adding Archive   (uma por mod em mods/)
SDLAudioPlayer.cpp  SDL Audio initialized
SaveManager.cpp:500 Init Meta - fileNum: 0             (le cada save para o menu de arquivos)
z_play_otr.cpp:62   Scene Init - sceneNum: ...         (entrou no jogo)
```

Onde o log para de crescer e o ponto do crash. Parar em `Init Meta` significa morrer
lendo o save, antes de qualquer cena.

Salvamento aparece em par: `SaveManager.cpp:1132 Save File` seguido de
`SaveManager.cpp:1206 Save File Finish`. **`Save File` sem o `Finish` correspondente e
escrita interrompida**, e provavelmente deixou save corrompido. Loja salva a cada compra,
entao e o lugar com mais chance de pegar o console no meio de uma escrita.

### Save corrompido do SoH: assinatura e recuperacao

O SoH escreve `fileN.temp` completo e depois copia para `fileN.sav`. Se a copia for
interrompida, sobra um `.temp` valido e um `.sav` cortado. Como confirmar:

```bash
sdget switch/soh_debug/Save /tmp/save/
jq -e . /tmp/save/file1.sav   || echo "sav invalido"
jq -e . /tmp/save/file1.temp  && echo "temp valido"
head -c $(stat -c %s /tmp/save/file1.sav) /tmp/save/file1.temp | cmp -s - /tmp/save/file1.sav \
  && echo "sav e prefixo exato do temp: escrita cortada"
```

Corte em multiplo de 4096 confirma interrupcao no meio da gravacao, nao dado bagunçado.
Recuperacao: guardar copia dos dois no PC, depois subir o `.temp` como `.sav`.

O SoH abre um save invalido? Nao: ele morre no `Init Meta`, alguns segundos depois da
logo, sem mensagem na tela.

## Cartao deste console

```
/switch          apps homebrew (DBI, sphaira, JKSV, soh_debug, 2ship, ...)
/atmosphere      CFW: contents (sysmodules), config, crash_reports, erpt_reports
/bootloader      hekate: ini, payloads (fusee.bin, Lockpick_RCM.bin, TegraExplorer.bin)
/config          config dos homebrew (sys-clk, sys-patch, MissionControl, sphaira, ...)
/emuMMC          NAND virtual do emuMMC
/cnx.txt         versao do pacote CNX
```

Ship of Harkinian mora em `switch/soh_debug` (arquivos `.o2r`, mods em `mods/`, saves em
`Save/`), e o Majora's Mask em `switch/2ship`. Os dois convivem. O forwarder na tela
inicial aponta para `soh_debug`, nunca para `soh`.

## Nao faca

- Escrever em `3: Nand SYSTEM`, ou mexer em `PRF2SAFE.RCV` e em qualquer coisa com
  `prodinfo` no nome.
- Apagar pasta em `atmosphere/contents` no chute: cada uma e um sysmodule, e sumir com o
  errado deixa o console sem boot.
- Confiar em "copiou sem erro". Instalacao se confere na lista de titulos; arquivo grande
  se confere por tamanho e md5.
- Tirar o cabo ou deixar o console dormir no meio de uma copia. Cai a sessao MTP e, se
  estava escrevendo, o arquivo fica cortado.
