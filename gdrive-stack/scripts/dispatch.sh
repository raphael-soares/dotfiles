#!/bin/bash
set -euo pipefail
# shellcheck disable=SC1091
source /scripts/runtime-env.sh
MODE="${1:-}"
[ -n "$MODE" ] || { echo "uso: dispatch.sh sync|backup"; exit 1; }
JOBS=/config/jobs.conf
[ -f "$JOBS" ] || { echo "jobs.conf não encontrado"; exit 1; }
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
while IFS='|' read -r jmode src dest || [ -n "${jmode:-}" ]; do
  first="$(trim "${jmode:-}")"
  case "$first" in ''|\#*) continue ;; esac
  jmode="$first"; src="$(trim "${src:-}")"; dest="$(trim "${dest:-}")"
  [ "$jmode" = "$MODE" ] || continue
  [ -n "$src" ] && [ -n "$dest" ] || { echo "[$MODE] linha inválida"; continue; }
  if [ ! -e "$src" ]; then echo "[$MODE] PULANDO (não existe): $src"; continue; fi
  if [ "$MODE" = "sync" ]; then
    echo "[sync] $src -> ${RCLONE_REMOTE}:${SYNC_BASE}/${dest}"
    rclone sync "$src" "${RCLONE_REMOTE}:${SYNC_BASE}/${dest}" \
      --create-empty-src-dirs --fast-list --log-level INFO
  else
    export RESTIC_REPOSITORY="rclone:${RCLONE_REMOTE}:${RESTIC_REPO_PATH}"
    restic snapshots >/dev/null 2>&1 || { echo "[backup] init repo"; restic init; }
    echo "[backup] $src (tag: ${dest})"
    restic backup "$src" --tag "$dest" --host "${BACKUP_HOST}"
    restic forget --tag "$dest" --host "${BACKUP_HOST}" \
      --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
  fi
done < "$JOBS"
echo "[$MODE] concluído."
