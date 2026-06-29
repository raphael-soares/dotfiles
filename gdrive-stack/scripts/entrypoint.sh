#!/bin/bash
set -e

[ -f /config/crontab ] || { echo "[entrypoint] erro: /config/crontab não encontrado"; exit 1; }

# cron do busybox roda com env mínimo -> persistir as vars pros scripts.
# HOME entra junto pra que o cache do restic caia no volume (/root/.cache/restic).
: > /scripts/runtime-env.sh
while IFS='=' read -r k v; do
  printf 'export %s=%q\n' "$k" "$v" >> /scripts/runtime-env.sh
done < <(printenv | grep -E '^(RESTIC_|RCLONE_|SYNC_|BACKUP_|TZ|HOME)=')
chmod 600 /scripts/runtime-env.sh   # contém RESTIC_PASSWORD

mkdir -p /var/spool/cron/crontabs
cp /config/crontab /var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root
echo "[entrypoint] crontab instalado; iniciando crond"
exec crond -f -l 8
