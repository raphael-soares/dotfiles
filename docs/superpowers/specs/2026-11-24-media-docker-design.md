# Media stack on Docker

## Intent

The owner asked to move the media stack (`media` module, fedora only) from
Podman quadlets to Docker, with no further questions. Behaviour seen from
outside stays the same: same services, ports, data folders, nightly updates,
watchdog, health report and logs in `mediactl`.

## Goals

- One `media/compose.yaml` replaces `media/containers/*.container` and
  `media.network`. `docker ps` and `docker compose` show and drive the stack.
- Same data on disk: every bind mount keeps its host path, files stay owned
  by the owner's user.
- `media-deploy`, `media-watchdog`, `media-updates`, `health` and configarr
  talk to Docker instead of systemd quadlet units.
- `missing.sh media` prints what Docker needs from root: Docker's repo and
  packages, `docker.service` enabled, the owner in the `docker` group.

## Non-goals

- The `design` module (Kokoro) stays on Podman; `design/packages.fedora.txt`
  keeps `podman`.
- No rollback of a bad image: `podman auto-update` rolled back, `docker
  compose pull` does not. The failure is logged and the next deploy or update
  replaces it.
- No migration code in the repo: the owner's one machine is cut over by hand
  once (stop the quadlet units, disable `podman-auto-update.timer`).

## Decisions (my calls; the owner opted out of questions)

| Topic | Choice | Why |
|---|---|---|
| Engine | rootful Docker Engine (docker-ce, already installed and enabled on fedora) | the standard Docker setup; rootless Docker cannot reach qBittorrent on the host's loopback without RootlessKit tuning |
| Access | the owner in the `docker` group (already in `/etc/group`) | needed to run `docker` without sudo; the group is root-equivalent, which is Docker's usual trade |
| Definition | one compose file, project `media`, linked to `~/.config/media/compose.yaml` | one place, `docker compose` works from anywhere through `media-compose` |
| Wrapper | `media-compose`: `docker compose -f ~/.config/media/compose.yaml` with the owner's uid, gid and the render/video gids exported | compose.yaml stays free of machine numbers |
| Users | linuxserver images keep `PUID`/`PGID`; Jellyfin, whisper, whisper-cpp and configarr run as the owner's uid | Podman's `UserNS=keep-id` gave the same file ownership |
| Restart | `restart: unless-stopped`, Docker starts at boot | replaces `Restart=on-failure` plus `WantedBy=default.target` |
| Host access | `host.docker.internal:host-gateway` on Radarr and Sonarr | replaces `host.containers.internal` for qBittorrent's WebUI |
| Network | `media`, subnet `10.89.42.0/24` kept | same addresses as before |
| Configarr | compose service in profile `manual`, run by `configarr.service` (`media-compose run --rm`) on the existing timer | a one-shot job, not a daemon |
| Updates | `media-update.timer` (daily) runs `media-updates`: pull, `up -d`, log each container whose image changed, prune old images | replaces `podman-auto-update.timer` and its drop-in |
| Logs | Docker's default json-file driver, read with `docker logs <name>` | no journald setup needed |

## Deploy

`media-deploy` stops early with a clear message when `docker info` fails.
Otherwise `media-compose up -d --remove-orphans` starts the stack; compose
recreates a container whose definition changed. A changed `asr-shim.py` (a
mounted file compose cannot see) restarts `whisper`. `--check` compares each
service's compose config hash with the running container's label and reports
the ones that differ or are not running.

## Cutover on fedora

1. Merge, then stop the quadlet units and disable `podman-auto-update.timer`.
2. Deploy under `sg docker` (the session predates the group).
3. Reboot, so the user systemd manager (lingering) gets the `docker` group for
   configarr and the update timer.
