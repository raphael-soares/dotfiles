#!/bin/bash
set -e
# cron do busybox roda com env mínimo -> persistir as vars pros scripts.
: > /scripts/runtime-env.sh
while IFS='=' read -r k v; do
  printf 'export %s=%q\n' "$k" "$v" >> /scripts/runtime-env.sh
done < <(printenv | grep -E '^(RESTIC_|RCLONE_|SYNC_|BACKUP_|TZ)=')
mkdir -p /var/spool/cron/crontabs
cp /config/crontab /var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root
echo "[entrypoint] crontab instalado; iniciando crond"
exec crond -f -l 8
