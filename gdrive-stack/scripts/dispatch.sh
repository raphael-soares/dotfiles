#!/bin/bash
# Lê /config/jobs.yaml e roda os jobs do modo pedido (sync ou backup).
# Sem `set -e`: uma falha de job não derruba os outros. No fim, o exit code
# é diferente de zero se algum job falhou.
set -uo pipefail
# shellcheck disable=SC1091
source /scripts/runtime-env.sh
export HOME="${HOME:-/root}"   # garante o cache do restic no volume montado

MODE="${1:-}"
case "$MODE" in
  sync|backup) ;;
  *) echo "uso: dispatch.sh sync|backup"; exit 2 ;;
esac

JOBS=/config/jobs.yaml
[ -f "$JOBS" ] || { echo "[$MODE] erro: $JOBS não encontrado"; exit 1; }
command -v yq >/dev/null 2>&1 || { echo "[$MODE] erro: yq não está na imagem"; exit 1; }

# Remote do rclone tem que existir (senão o OAuth ainda não foi feito).
if ! rclone listremotes 2>/dev/null | grep -qx "${RCLONE_REMOTE}:"; then
  echo "[$MODE] erro: remote '${RCLONE_REMOTE}:' não existe em ${RCLONE_CONFIG:-?}."
  echo "          rode 'rclone config' e salve em config/rclone.conf (veja README)."
  exit 1
fi

# Valida o YAML e extrai os jobs como TSV: mode <TAB> src <TAB> dest.
if ! jobs_tsv="$(yq -r '(.jobs // [])[] | [.mode // "", .src // "", .dest // ""] | @tsv' "$JOBS" 2>&1)"; then
  echo "[$MODE] erro: YAML inválido em $JOBS:"
  echo "$jobs_tsv"
  exit 1
fi

ran=0
errors=0
while IFS=$'\t' read -r jmode src dest; do
  [ -n "$jmode" ] || continue
  case "$jmode" in
    sync|backup) ;;
    *) echo "[$MODE] AVISO: modo desconhecido '$jmode' (use sync|backup) — pulando"; continue ;;
  esac
  [ "$jmode" = "$MODE" ] || continue

  if [ -z "$src" ] || [ -z "$dest" ]; then
    echo "[$MODE] AVISO: job sem src/dest — pulando"; errors=$((errors+1)); continue
  fi

  # src precisa estar sob SYNC_ROOT, que é o único caminho montado no container.
  if [ -n "${SYNC_ROOT:-}" ]; then
    case "$src" in
      "$SYNC_ROOT"|"$SYNC_ROOT"/*) ;;
      *) echo "[$MODE] AVISO: '$src' fora de SYNC_ROOT ($SYNC_ROOT) — não montado, pulando"
         errors=$((errors+1)); continue ;;
    esac
  fi

  if [ ! -e "$src" ]; then
    echo "[$MODE] PULANDO (não existe no container): $src"; continue
  fi

  if [ "$MODE" = sync ]; then
    # dest com "/" no começo = caminho absoluto a partir da raiz do remote
    # (ignora SYNC_BASE); senão, fica sob <SYNC_BASE>/<dest>.
    case "$dest" in
      /*) target="${RCLONE_REMOTE}:${dest#/}" ;;
      *)  target="${RCLONE_REMOTE}:${SYNC_BASE}/${dest}" ;;
    esac
    echo "[sync] $src -> $target"
    if rclone sync "$src" "$target" --create-empty-src-dirs --fast-list --log-level INFO; then
      ran=$((ran+1))
    else
      echo "[sync] FALHOU (rclone exit $?): $src -> $target"; errors=$((errors+1))
    fi
  else
    export RESTIC_REPOSITORY="rclone:${RCLONE_REMOTE}:${RESTIC_REPO_PATH}"
    if ! restic cat config >/dev/null 2>&1; then
      echo "[backup] inicializando repositório restic em $RESTIC_REPOSITORY"
      if ! restic init; then
        echo "[backup] FALHOU ao inicializar o repo — abortando backups"
        errors=$((errors+1)); break
      fi
    fi
    echo "[backup] $src (tag: $dest)"
    if restic backup "$src" --tag "$dest" --host "$BACKUP_HOST"; then
      restic forget --tag "$dest" --host "$BACKUP_HOST" \
        --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune \
        || echo "[backup] AVISO: forget/prune falhou para tag '$dest'"
      ran=$((ran+1))
    else
      echo "[backup] FALHOU (restic exit $?): $src (tag: $dest)"; errors=$((errors+1))
    fi
  fi
done <<< "$jobs_tsv"

echo "[$MODE] concluído: $ran ok, $errors com erro."
[ "$errors" -eq 0 ]
