#!/usr/bin/env bash
# Helpers para falar com o Nintendo Switch pelo MTP do DBI, via KIO (KDE).
# Uso: source .omp/skills/switch-mtp/helpers.sh
#
# Toda funcao usa `kioclient`. Nao existe ponto de montagem: o caminho remoto
# e sempre uma URL mtp:/, e ferramenta que precisa de arquivo real (7z, unzip,
# md5sum) exige baixar antes com sdget.

# Nome do dispositivo MTP, detectado uma vez e guardado em cache.
_sd_dev() {
  if [ -z "${SD_DEV:-}" ]; then
    SD_DEV=$(kioclient ls mtp:/ 2>/dev/null | awk 'NF && $0 != "."' | head -n 1)
    export SD_DEV
  fi
  [ -n "$SD_DEV" ] || { echo "MTP: nenhum dispositivo. DBI esta com o MTP responder aberto?" >&2; return 1; }
  printf '%s' "$SD_DEV"
}

# Monta a URL de uma storage. sd_url "1: SD Card" "switch/soh_debug"
sd_url() {
  local dev store="$1" path="${2:-}"
  dev=$(_sd_dev) || return 1
  if [ -n "$path" ]; then printf 'mtp:/%s/%s/%s' "$dev" "$store" "${path#/}"
  else printf 'mtp:/%s/%s' "$dev" "$store"; fi
}

# Atalho para a storage do cartao SD. sdurl switch/soh_debug
sdurl() { sd_url "1: SD Card" "${1:-}"; }

# Conexao e storages disponiveis.
sdconn() {
  local dev
  lsusb | awk '/057e:201d/ {print "USB: " $0}'
  dev=$(_sd_dev) || return 1
  echo "MTP: $dev"
  kioclient ls "mtp:/$dev" 2>/dev/null | awk 'NF && $0 != "."'
}

# Lista uma pasta do cartao. sdls switch/soh_debug
sdls() { kioclient ls "$(sdurl "${1:-}")" 2>&1 | awk 'NF && $0 != "."' | sort; }

# Lista uma pasta de qualquer storage. sdls_at "7: Saves" "Installed games"
sdls_at() { kioclient ls "$(sd_url "$1" "${2:-}")" 2>&1 | awk 'NF && $0 != "."' | sort; }

# Arvore recursiva com profundidade limitada. sdtree switch/soh_debug 2
# Resolve o dispositivo uma vez: sem isso cada chamada aninhada reabre a sessao MTP.
sdtree() {
  export SD_DEV="${SD_DEV:-$(_sd_dev)}"
  [ -n "$SD_DEV" ] || return 1
  _sdtree "${1:-}" "${2:-2}" 1
}

_sdtree() {
  local base="$1" max="$2" depth="$3" item child
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    child="${base:+$base/}$item"
    printf '%*s%s\n' $(( (depth - 1) * 2 )) '' "$item"
    if [ "$depth" -lt "$max" ] && kioclient ls "$(sdurl "$child")" >/dev/null 2>&1; then
      _sdtree "$child" "$max" $(( depth + 1 ))
    fi
  done < <(sdls "$base")
}

# Tamanho em bytes de um arquivo do cartao. sdsize switch/soh_debug/soh.nro
sdsize() { kioclient stat "$(sdurl "$1")" 2>/dev/null | awk '/^SIZE/{print $2}'; }

# Conteudo de um arquivo de texto. sdcat cnx.txt
sdcat() { kioclient cat "$(sdurl "$1")" 2>&1; }

# Baixa do cartao. sdget switch/soh_debug/logs/*.log /tmp/
sdget() { kioclient --overwrite copy "$(sdurl "$1")" "${2:-.}" 2>&1; }

# Envia para o cartao, sobrescrevendo. sdput ./switch "" -> raiz do cartao
sdput() {
  local src="$1" dst="${2:-}"
  [ -e "$src" ] || { echo "nao existe: $src" >&2; return 1; }
  kioclient --overwrite copy "$src" "$(sdurl "$dst")/" 2>&1
}

# Cria pasta. sdmkdir switch/minhapasta
sdmkdir() { kioclient mkdir "$(sdurl "$1")" 2>&1; }

# APAGA. Pasta com conteudo tambem, sem confirmar. sdrm switch/soh_debug
sdrm() { kioclient remove "$(sdurl "$1")" 2>&1; }

# Instala titulo. sdinstall jogo.nsp        (no cartao)
#                sdinstall jogo.nsp nand    (na memoria interna)
sdinstall() {
  local file="$1" alvo="${2:-sd}" store
  [ -f "$file" ] || { echo "nao existe: $file" >&2; return 1; }
  case "$alvo" in
    nand) store="6: NAND install" ;;
    *)    store="5: SD Card install" ;;
  esac
  echo "instalando $(basename "$file") em $store"
  kioclient copy "$file" "$(sd_url "$store")/" 2>&1
  echo "--- titulos instalados agora:"
  sdtitles
}

# Titulos instalados, com title id e versao.
sdtitles() { kioclient cat "$(sd_url "4: Installed games" InstalledApplications.csv)" 2>&1; }

# Puxa logs de homebrew e crash reports para uma pasta local. sdlogs /tmp/switch-logs
sdlogs() {
  local out="${1:-/tmp/switch-logs}" p
  mkdir -p "$out"
  for p in switch/soh_debug/logs switch/2ship/logs atmosphere/logs \
           atmosphere/crash_reports atmosphere/fatal_reports; do
    kioclient ls "$(sdurl "$p")" >/dev/null 2>&1 || continue
    mkdir -p "$out/$(echo "$p" | tr / _)"
    kioclient --overwrite copy "$(sdurl "$p")" "$out/$(echo "$p" | tr / _)/" 2>&1
    echo "puxado: $p"
  done
  find "$out" -type f -printf '%10s  %p\n' | sort -k2
}

# Confere se o arquivo no cartao e identico ao local, por md5.
# sdverify ./switch/soh_debug/soh.nro switch/soh_debug/soh.nro
sdverify() {
  local local_f="$1" remote="$2" tmp lsize rsize
  [ -f "$local_f" ] || { echo "nao existe: $local_f" >&2; return 1; }
  lsize=$(stat -c %s "$local_f"); rsize=$(sdsize "$remote")
  if [ "$lsize" != "$rsize" ]; then
    echo "TAMANHO DIFERENTE: local=$lsize cartao=${rsize:-ausente}"; return 1
  fi
  tmp=$(mktemp -d)
  kioclient --overwrite copy "$(sdurl "$remote")" "$tmp/" >/dev/null 2>&1
  if [ "$(md5sum < "$local_f" | cut -d' ' -f1)" = "$(md5sum < "$tmp/$(basename "$remote")" | cut -d' ' -f1)" ]; then
    echo "IGUAL ($lsize bytes)"; rm -rf "$tmp"
  else
    echo "MD5 DIFERENTE"; rm -rf "$tmp"; return 1
  fi
}
