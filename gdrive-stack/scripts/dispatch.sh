#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /scripts/runtime-env.sh
MODE="${1:-}"
[ -n "$MODE" ] || { echo "uso: dispatch.sh sync|backup"; exit 1; }
JOBS=/config/jobs.yaml
[ -f "$JOBS" ] || { echo "jobs.yaml não encontrado"; exit 1; }

# yq valida o YAML e emite uma linha TSV por job: mode <TAB> src <TAB> dest
yq -r '(.jobs // [])[] | [.mode, .src, .dest] | @tsv' "$JOBS" |
while IFS=$'\t' read -r jmode src dest; do
  [ -n "$jmode" ] && [ "$jmode" != "null" ] || continue
  [ "$jmode" = "$MODE" ] || continue
  if [ -z "$src" ] || [ -z "$dest" ] || [ "$src" = null ] || [ "$dest" = null ]; then
    echo "[$MODE] job inválido (src/dest faltando)"; continue
  fi
  if [ ! -e "$src" ]; then echo "[$MODE] PULANDO (não existe): $src"; continue; fi
  if [ "$MODE" = "sync" ]; then
    # dest com "/" no começo = caminho absoluto a partir da raiz do remote
    # (ignora SYNC_BASE); senão, fica sob <SYNC_BASE>/<dest>.
    case "$dest" in
      /*) target="${RCLONE_REMOTE}:${dest#/}" ;;
      *)  target="${RCLONE_REMOTE}:${SYNC_BASE}/${dest}" ;;
    esac
    echo "[sync] $src -> ${target}"
    rclone sync "$src" "${target}" \
      --create-empty-src-dirs --fast-list --log-level INFO
  else
    export RESTIC_REPOSITORY="rclone:${RCLONE_REMOTE}:${RESTIC_REPO_PATH}"
    restic snapshots >/dev/null 2>&1 || { echo "[backup] init repo"; restic init; }
    echo "[backup] $src (tag: ${dest})"
    restic backup "$src" --tag "$dest" --host "${BACKUP_HOST}"
    restic forget --tag "$dest" --host "${BACKUP_HOST}" \
      --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
  fi
done
echo "[$MODE] concluído."
