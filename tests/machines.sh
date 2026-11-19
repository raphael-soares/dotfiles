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

for f in .bashrc .bash_profile .gitconfig .config/git/ignore .config/starship.toml \
  .config/fzf/fzf.sh .config/mise/config.toml .config/nvim .config/ghostty/config \
  .config/fastfetch/config.jsonc \
  .claude/CLAUDE.md .claude/settings.json .claude/skills .claude/hooks/rtk-rewrite.sh \
  .omp/agent/AGENTS.md .omp/agent/config.yml .omp/agent/skills .omp/agent/extensions \
  .omp/agent/rules .omp/agent/prompts .omp/agent/themes .local/bin/fila \
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

laptop_only=(.config/hypr .config/xdg-desktop-portal/hyprland-portals.conf
  .config/noctalia-plugins/hypr-shots .local/state/noctalia/settings.toml
  Pictures/Wallpaper/forest-4.jpg .config/ghostty/machine.conf
  .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini
  .local/bin/vpn .local/bin/omp-agendado-work .omp/overlays
  .config/shell/rc.d/work.sh)

hook=$T/cache/.dotter/post_deploy.sh
if [[ -f $hook ]]; then
  bash -n "$hook" || fail "rendered hook has a syntax error"
else
  fail "hook was not rendered"
fi
hook_has() { [[ -f $hook ]] && grep -q -- "$1" "$hook"; }
laptop_only_in_hook=(hyprctl greetd enterprise)
desktop_only_in_hook=(sshd_config.d sddm.conf.d setcap powerdevilrc)

case $machine in
  arch)
    for f in "${laptop_only[@]}"; do exists "$f"; done
    repo_link .config/hypr
    [[ -f $H/.config/hypr/hyprland.lua ]] || fail ".config/hypr does not reach hyprland.lua"
    for p in "${laptop_only_in_hook[@]}"; do hook_has "$p" || fail "hook lacks $p"; done
    for p in "${desktop_only_in_hook[@]}"; do ! hook_has "$p" || fail "arch hook has $p"; done
    ;;
  fedora)
    for f in "${laptop_only[@]}"; do absent "$f"; done
    for p in "${laptop_only_in_hook[@]}"; do ! hook_has "$p" || fail "fedora hook has $p"; done
    for p in "${desktop_only_in_hook[@]}"; do hook_has "$p" || fail "fedora hook lacks $p"; done
    ;;
  *) echo "unknown machine: $machine"; exit 2 ;;
esac

if ((failures)); then
  echo "$machine: $failures failure(s)"
  exit 1
fi
echo "$machine: ok"
