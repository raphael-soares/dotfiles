#!/usr/bin/env bash
set -euo pipefail

maquina=${1:?uso: tests/maquinas.sh arch|fedora}
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
H=$T/home
mkdir -p "$H"

cd "$REPO"
HOME=$H DOTFILES_SO_LINKS=1 dotter -q -y \
  -l ".dotter/$maquina.toml" \
  --cache-file "$T/cache.toml" --cache-directory "$T/cache" deploy

falhas=0
falha() { echo "FALHOU: $*"; falhas=$((falhas + 1)); }

link_do_repo() {
  local alvo=$H/$1
  [[ -L $alvo ]] || { falha "$1 não é symlink"; return; }
  [[ $(readlink -f "$alvo") == "$REPO"/* ]] || falha "$1 não aponta para o repo"
}
pasta_real() { [[ -d $H/$1 && ! -L $H/$1 ]] || falha "$1 não é pasta real"; }
existe() { [[ -e $H/$1 || -L $H/$1 ]] || falha "$1 não existe"; }
ausente() { [[ ! -e $H/$1 && ! -L $H/$1 ]] || falha "$1 existe e não devia"; }

for f in .bashrc .bash_profile .gitconfig .config/git/ignore .config/starship.toml \
  .config/fzf/fzf.sh .config/mise/config.toml .config/nvim .config/ghostty/config \
  .config/fastfetch/config.jsonc \
  .claude/CLAUDE.md .claude/settings.json .claude/skills .claude/hooks/rtk-rewrite.sh \
  .omp/agent/AGENTS.md .omp/agent/config.yml .omp/agent/skills .omp/agent/extensions \
  .omp/agent/rules .omp/agent/prompts .omp/agent/themes .local/bin/fila \
  .config/fontconfig/conf.d/50-fontes.conf .local/share/applications/zapfast.desktop \
  .local/share/icons/hicolor/scalable/apps/whatsapp.svg \
  .config/wireplumber/wireplumber.conf.d/53-bluetooth-a2dp-only.conf \
  .config/wireplumber/wireplumber.conf.d/55-fuxi-soft-mixer.conf \
  .config/syncfast/config.toml; do
  link_do_repo "$f"
done
for d in .omp/agent .claude .claude/hooks .local/bin .config/ghostty .config/syncfast \
  .config/wireplumber/wireplumber.conf.d; do
  pasta_real "$d"
done
[[ -f $H/.claude/skills/discussao/SKILL.md ]] || falha ".claude/skills não chega nas skills"

so_notebook=(.config/hypr .config/xdg-desktop-portal/hyprland-portals.conf
  .config/noctalia-plugins/hypr-shots .local/state/noctalia/settings.toml
  Pictures/Wallpaper/forest-4.jpg .config/ghostty/maquina.conf
  .config/gtk-3.0/settings.ini .config/gtk-4.0/settings.ini
  .local/bin/vpn .local/bin/omp-agendado-work .omp/overlays
  .config/shell/rc.d/trabalho.sh)

hook=$T/cache/.dotter/post_deploy.sh
if [[ -f $hook ]]; then
  bash -n "$hook" || falha "hook renderizado tem erro de sintaxe"
else
  falha "hook não foi renderizado"
fi
hook_tem() { [[ -f $hook ]] && grep -q -- "$1" "$hook"; }
so_notebook_no_hook=(hyprctl greetd enterprise)

case $maquina in
  arch)
    for f in "${so_notebook[@]}"; do existe "$f"; done
    link_do_repo .config/hypr
    [[ -f $H/.config/hypr/hyprland.lua ]] || falha ".config/hypr não chega no hyprland.lua"
    for p in "${so_notebook_no_hook[@]}"; do hook_tem "$p" || falha "hook sem $p"; done
    ;;
  fedora)
    for f in "${so_notebook[@]}"; do ausente "$f"; done
    for p in "${so_notebook_no_hook[@]}"; do ! hook_tem "$p" || falha "hook do fedora com $p"; done
    ;;
  *) echo "máquina desconhecida: $maquina"; exit 2 ;;
esac

if ((falhas)); then
  echo "$maquina: $falhas falha(s)"
  exit 1
fi
echo "$maquina: ok"
