#!/usr/bin/env bash
set -euo pipefail

machine=${1:?usage: tests/machines.sh arch|fedora}
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
H=$T/home
mkdir -p "$H"

cd "$REPO"
HOME=$H DOTFILES_LINKS_ONLY=1 dotter -q -y \
  -l ".dotter/$machine.toml" \
  --cache-file "$T/cache.toml" --cache-directory "$T/cache" deploy

failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

repo_link() {
  local target=$H/$1
  [[ -L $target ]] || { fail "$1 is not a symlink"; return; }
  [[ $(readlink -f "$target") == "$REPO"/* ]] || fail "$1 does not point into the repo"
}
real_dir() { [[ -d $H/$1 && ! -L $H/$1 ]] || fail "$1 is not a real directory"; }
exists() { [[ -e $H/$1 || -L $H/$1 ]] || fail "$1 does not exist"; }
absent() { [[ ! -e $H/$1 && ! -L $H/$1 ]] || fail "$1 exists and should not"; }

for f in .bashrc .bash_profile .profile .config/environment.d/99-session.conf .config/aws/config \
  .config/git/config .config/git/ignore .config/starship.toml \
  .config/fzf/fzf.sh .config/mise/config.toml .config/nvim .config/ghostty/base \
  .config/fastfetch/config.jsonc \
  .claude/CLAUDE.md .claude/settings.json .claude/skills .claude/hooks/rtk-rewrite.sh \
  .omp/agent/AGENTS.md .omp/agent/config.yml .omp/agent/skills .omp/agent/extensions \
  .omp/agent/rules .omp/agent/prompts .omp/agent/themes .omp/agent/agents .local/bin/fila \
  .config/fontconfig/conf.d/50-fonts.conf .local/share/applications/zapfast.desktop \
  .local/share/icons/hicolor/scalable/apps/whatsapp.svg \
  .config/wireplumber/wireplumber.conf.d/53-bluetooth-a2dp-only.conf \
  .config/wireplumber/wireplumber.conf.d/55-fuxi-soft-mixer.conf \
  .config/syncfast/config.toml; do
  repo_link "$f"
done
for d in .omp/agent .claude .claude/hooks .local/bin .config/ghostty .config/syncfast \
  .config/wireplumber/wireplumber.conf.d; do
  real_dir "$d"
done
[[ -f $H/.claude/skills/discussao/SKILL.md ]] || fail ".claude/skills does not reach the skills"

hypr_shared=(.config/hypr .config/xdg-desktop-portal/hyprland-portals.conf
  .config/noctalia-plugins/hypr-remote .local/bin/screenshot
  .config/noctalia/base.toml
  Pictures/Wallpaper/forest-4.jpg .config/ghostty/machine.conf
  .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini .config/hypr-machine
  .local/bin/remote-serving .local/bin/remote-control .local/bin/monitor-away)
[[ ! -e $H/.config/noctalia-plugins/hypr-shots ]] || fail "the old screenshot plugin is still deployed"
laptop_only=(.local/bin/vpn .local/bin/omp-agendado-work .omp/overlays
  .config/shell/rc.d/work.sh)
desktop_only=(.config/media/compose.yaml .config/media/configarr .local/bin/media-deploy .local/bin/media-compose
  .config/autostart/org.qbittorrent.qBittorrent.desktop .config/systemd/user/configarr.timer .config/systemd/user/configarr.service
  .local/bin/craft-mcp .local/bin/creative-deploy .config/audiocpp .omp/agent/models.yml)

hook=$T/cache/.dotter/post_deploy.sh
if [[ -f $hook ]]; then
  bash -n "$hook" || fail "rendered hook has a syntax error"
else
  fail "hook was not rendered"
fi
hook_has() { [[ -f $hook ]] && grep -q -- "$1" "$hook"; }
shared_in_hook=(hyprctl 'xdg-mime default' 'capture = kms' missing.sh)
laptop_only_in_hook=(enterprise)
desktop_only_in_hook=(media-deploy creative-deploy)
# The deploy configures; installing, downloading and anything needing root is printed
# by missing.sh for the owner to run.
gone_from_hook=(plasmalogin kwriteconfig6 kwinrc roundcorners home/greetd/config.toml laptop/greetd/config.toml
  'sudo ' 'dnf ' 'pacman ' 'yay ' 'flatpak install' 'flatpak uninstall' 'curl ' 'gh release' 'git clone'
  'omp plugin install' 'npx ' 'uv tool install')
for p in "${gone_from_hook[@]}"; do ! hook_has "$p" || fail "$machine hook still has $p"; done
for p in "${shared_in_hook[@]}"; do hook_has "$p" || fail "$machine hook lacks $p"; done
modules=$(sed -n 's/^packages *= *\[\(.*\)\]/\1/p' ".dotter/$machine.toml" | tr -d '",')
for m in $modules; do [[ -f $REPO/$m/manual.sh ]] || fail "module $m has no manual.sh"; done
called=$(grep -o '/\.dotter/missing\.sh" .*' "$hook" | tr -s ' ' | sed "s/^[^ ]* //; s/ *|| true' EXIT$//")
[[ $(tr ' ' '\n' <<<"$called" | sort | xargs) == $(tr ' ' '\n' <<<"$modules" | sort | xargs) ]] ||
  fail "hook runs missing.sh for [$called], the machine deploys [$modules]"
! ls "$REPO"/*/remove.*.txt >/dev/null 2>&1 || fail "removal lists are back"

# A fresh machine: only basic tools, and a gsettings without the GNOME schemas. The deploy
# must still finish and print what to install.
mkdir -p "$T/bare"
for c in bash sed grep cat mkdir rm ln cp mv sort cut head tr env dirname basename readlink \
  sha256sum cmp awk hostname id getent printf xargs; do
  p=$(type -P "$c") && ln -s "$p" "$T/bare/$c"
done
printf '#!/bin/sh\necho "No such schema" >&2\nexit 1\n' >"$T/bare/gsettings"
chmod +x "$T/bare/gsettings"
rc=0
out=$("$(type -P env)" -i HOME="$H" PATH="$T/bare" "$(type -P bash)" "$hook" 2>&1) || rc=$?
[[ $rc == 0 ]] || fail "$machine deploy on a bare machine exited $rc: $out"
grep -q "Still to do by hand:" <<<"$out" || fail "$machine deploy on a bare machine printed no manual steps: $out"
for f in "${hypr_shared[@]}"; do exists "$f"; done
repo_link .config/hypr
[[ -f $H/.config/hypr/hyprland.lua ]] || fail ".config/hypr does not reach hyprland.lua"
[[ -f $H/.config/hypr/remote.lua ]] || fail ".config/hypr does not reach the shared remote.lua"
[[ ! -e $H/.config/hypr-machine/remote.lua ]] || fail "hypr-machine has its own remote.lua, which shadows the shared one"
links_to() { [[ $(readlink -f "$H/$1") == "$REPO/$2" ]] || fail "$1 does not point to $2"; }
drive_link() {
  [[ -L $H/$1 && $(readlink "$H/$1") == "$H/$2" ]] || fail "$1 is not a link to $2"
}
drive_link Documents Drive/Documents
drive_link Pictures/Wallpaper Drive/Personal/Wallpaper
[[ -L $H/Pictures/Wallpaper/forest-4.jpg && -f $H/Drive/Personal/Wallpaper/forest-4.jpg ]] ||
  fail "forest-4.jpg is not linked inside the Drive wallpaper folder"
[[ ! -e $H/.config/go/env ]] || fail "go/env is back; GOPATH lives in session.conf"
for v in GOPATH PATH EDITOR BROWSER; do
  grep -q "^$v=" "$H/.config/environment.d/99-session.conf" || fail "session.conf lacks $v"
done
! grep -q AWS_SHARED_CREDENTIALS_FILE "$H/.config/environment.d/99-session.conf" ||
  fail "session.conf forces a plain credentials file; the AWS CLI uses credential_process"
repo_link .local/bin/zen
links_to .config/noctalia/base.toml hyprland/noctalia/base.toml
! grep -qx com.stremio.Stremio "$REPO"/*/flatpaks.txt || fail "the Flathub Stremio is still listed"
! git -C "$REPO" ls-files --error-unmatch hyprland/hypr/hyprtoolkit.conf >/dev/null 2>&1 ||
  fail "hyprtoolkit.conf is tracked, and Noctalia rewrites it with each machine's colors"
git -C "$REPO" check-ignore -q hyprland/hypr/hyprtoolkit.conf || fail "hyprtoolkit.conf is not ignored"
! grep -q initial_session "$REPO/hyprland/greetd/config.toml" || fail "the shared greetd config autologins"
[[ ! -e $H/.local/state/noctalia/settings.toml ]] ||
  fail "Noctalia's state file is deployed, and its interface writes theme and wallpaper there"
[[ ! -e $H/.local/share/kwin ]] || fail "KWin files are still deployed"

case $machine in
  arch)
    for f in "${laptop_only[@]}"; do exists "$f"; done
    for f in "${desktop_only[@]}"; do absent "$f"; done
    grep -q 'peer = "fedora"' "$H/.config/hypr-machine/machine.lua" || fail "arch does not name fedora as its peer"
    links_to .config/noctalia/machine.toml laptop/noctalia/machine.toml
    for p in "${laptop_only_in_hook[@]}"; do hook_has "$p" || fail "hook lacks $p"; done
    for p in "${desktop_only_in_hook[@]}"; do ! hook_has "$p" || fail "arch hook has $p"; done
    absent .local/share/applications/stremio-enhanced.desktop
    for m in $modules; do
      ! grep -qi stremio "$REPO/$m/manual.sh" 2>/dev/null || fail "$m/manual.sh asks arch for Stremio or its plugin"
    done
    ;;
  fedora)
    for f in "${laptop_only[@]}"; do absent "$f"; done
    for f in "${desktop_only[@]}"; do repo_link "$f"; done
    for p in "${laptop_only_in_hook[@]}"; do ! hook_has "$p" || fail "fedora hook has $p"; done
    for p in "${desktop_only_in_hook[@]}"; do hook_has "$p" || fail "fedora hook lacks $p"; done
    [[ -f $H/.config/hypr-machine/machine.lua ]] || fail "hypr-machine does not reach machine.lua"
    links_to .config/noctalia/machine.toml home/noctalia/machine.toml
    grep -q 'peer = "arch"' "$H/.config/hypr-machine/machine.lua" || fail "fedora does not name arch as its peer"
    links_to .local/share/applications/stremio-enhanced.desktop media/stremio/stremio-enhanced.desktop
    ;;
  *) echo "unknown machine: $machine"; exit 2 ;;
esac

if ((failures)); then
  echo "$machine: $failures failure(s)"
  exit 1
fi
echo "$machine: ok"
