# gdrive-stack

Docker stack that mirrors folders to Google Drive (`rclone`) and keeps
incremental encrypted backups (`restic`, with rclone as backend). Single Alpine
container, scheduled by busybox cron inside it (no systemd, no host cron).

## Setup

```bash
cd ~/.dotfiles/gdrive-stack
./setup.sh
```

`setup.sh` is idempotent: checks Docker, generates `.env` (SYNC_ROOT,
BACKUP_HOST, TZ, a strong restic password), runs the Drive OAuth in the browser,
then builds and starts the container. It prints the restic password at the end.
Save it: lose it and the backups are unrecoverable.

Then edit `config/jobs.yaml` and run `docker compose up -d`.

## Configuring jobs

`config/jobs.yaml` is the only file you edit to choose what runs:

```yaml
jobs:
  - mode: sync          # one-way mirror to Drive
    src: /home/raphael/Notes
    dest: notes         # lands at <SYNC_BASE>/notes; leading "/" = absolute path
  - mode: backup        # versioned restic snapshot
    src: /home/raphael/Workspace
    dest: workspace     # restic tag (not a folder)
```

- `src` must be under `SYNC_ROOT` (the only path mounted, read-only).
- Backups go to one restic repo, separated by tag (dedup, one password).
  Retention: 7 daily, 4 weekly, 6 monthly.
- Default schedule (`config/crontab`): sync hourly, backup at 03:30.

## Commands

```bash
docker compose ps
docker compose logs -f backup
docker compose exec backup /scripts/dispatch.sh sync     # run sync now
docker compose exec backup /scripts/dispatch.sh backup   # run backup now

# restic snapshots / restore:
docker compose exec backup sh -c \
  'RESTIC_REPOSITORY=rclone:$RCLONE_REMOTE:$RESTIC_REPO_PATH restic snapshots'
docker compose exec backup sh -c \
  'RESTIC_REPOSITORY=rclone:$RCLONE_REMOTE:$RESTIC_REPO_PATH restic restore latest --target /tmp/restore --tag notes'
```

## Notes

- `sync` mirrors: files deleted from `src` are deleted on Drive. Use `backup`
  for history.
- A failing job doesn't abort the others; `dispatch.sh` exits non-zero if any
  failed.
- `.env` and `config/rclone.conf` are gitignored. Never commit secrets.
