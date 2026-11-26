#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
export HOME=$T/home
export MEDIA_STATE=$HOME/.local/share/media MEDIA_LOG=$T/media.log
export MEDIA_BACKUP_REMOTE=$T/remote
mkdir -p "$HOME/.config/sops/age" "$HOME/.dotfiles" "$T/bin" "$T/remote"

# The fake rclone treats a remote as a local folder.
cat >"$T/bin/rclone" <<'EOF'
#!/bin/sh
case $1 in
  copy) mkdir -p "$3" && cp "$2" "$3" ;;
  lsf) ls "$4" | grep -E "$(printf '%s' "$3" | sed 's/\./\\./g; s/\*/.*/g')$" || true ;;
  delete) ;;
esac
EOF
chmod +x "$T/bin/rclone"
export PATH=$T/bin:$PATH

key=$HOME/.config/sops/age/keys.txt
age-keygen -o "$key" 2>/dev/null
recipient=$(age-keygen -y "$key")
printf 'creation_rules:\n  - path_regex: secrets/[^/]+\\.env$\n    age: %s\n' "$recipient" >"$HOME/.dotfiles/.sops.yaml"

for svc in radarr sonarr prowlarr jellyfin bazarr; do
  mkdir -p "$MEDIA_STATE/$svc"
  sqlite3 "$MEDIA_STATE/$svc/$svc.db" 'create table t(x); insert into t values (1);'
done
printf 'SECRETCANARY' >"$MEDIA_STATE/bazarr/config.yaml"
mkdir -p "$HOME/.config/qBittorrent" "$HOME/.local/share/qBittorrent"
printf 'conf' >"$HOME/.config/qBittorrent/qBittorrent.conf"
printf 'state' >"$HOME/.local/share/qBittorrent/torrent.fastresume"

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

"$REPO/media/bin/media-backup" 2>/dev/null
archive=$(ls "$T"/remote/media-*.tar.zst.age) || fail "no encrypted archive reached the remote"
[[ $(ls "$T/remote" | wc -l) == 1 ]] || fail "the remote holds more than the encrypted archive: $(ls "$T/remote")"
! grep -aq SECRETCANARY "$archive" || fail "the archive holds a setting in the clear"
[[ $(head -c 21 "$archive") == "age-encryption.org/v1" ]] || fail "the archive is not an age file"
age -d -i "$key" "$archive" | zstd -dcq | tar -tf - | grep -qx media/files.tar || fail "the archive does not decrypt to the media tree"

"$REPO/media/bin/media-restore-test" 2>/dev/null || fail "media-restore-test rejects a good archive"
age-keygen -o "$T/other.txt" 2>/dev/null
SOPS_AGE_KEY_FILE=$T/other.txt "$REPO/media/bin/media-restore-test" 2>/dev/null && fail "media-restore-test accepted a wrong key"
SOPS_AGE_KEY_FILE=$T/none.txt "$REPO/media/bin/media-restore-test" 2>/dev/null && fail "media-restore-test ran without a key"

rm "$T"/remote/*
MEDIA_SOPS_CONFIG=$T/none.yaml "$REPO/media/bin/media-backup" 2>/dev/null && fail "media-backup ran without a recipient"
[[ -z $(ls "$T/remote") ]] || fail "media-backup uploaded without a recipient"

((failures == 0)) && echo "media_backup: ok" || { echo "media_backup: $failures failure(s)"; exit 1; }
