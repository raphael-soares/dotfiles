#!/usr/bin/env bash
# Lists what each module still needs by hand: packages, system files, services.
# Only reads the machine; prints commands for the owner to run and runs none.
# Usage: missing.sh [module...]   (no modules: the ones this machine deploys)
set -uo pipefail

REPO=${DOTFILES_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}
DISTRO=${DOTFILES_DISTRO:-$(. /etc/os-release && echo "$ID")}
ROOT=${DOTFILES_ROOT:-}
# shellcheck disable=SC2034  # read by home/manual.sh
CMDLINE=${DOTFILES_CMDLINE:-/proc/cmdline}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
REPO_SHOWN=${REPO/#"$HOME"/\~}

lines=()
step() { lines+=("$*"); }
note() { lines+=("# $*"); }
have() { command -v "$1" >/dev/null; }
list() { [[ -f $REPO/$MODULE/$1 ]] && grep -v -e '^#' -e '^$' "$REPO/$MODULE/$1"; }

need_packages() {
  local names missing=() repo=() aur=() p
  if [[ $DISTRO != arch && $DISTRO != fedora ]]; then
    names=$(list "packages.$DISTRO.txt" || { list packages.fedora.txt; list packages.arch.txt; })
    [[ -n $names ]] && note "install by hand: $(sort -u <<<"$names" | tr '\n' ' ' | sed 's/ $//')"
    return 0
  fi
  names=$(list "packages.$DISTRO.txt") || return 0
  case $DISTRO in
    arch)
      mapfile -t missing < <(pacman -T $names)
      ((${#missing[@]})) || return
      if have yay; then
        step "yay -S --needed ${missing[*]}"
        return
      fi
      for p in "${missing[@]}"; do
        if pacman -Si "$p" >/dev/null 2>&1; then repo+=("$p"); else aur+=("$p"); fi
      done
      ((${#repo[@]})) && step "sudo pacman -S --needed ${repo[*]}"
      ((${#aur[@]})) && note "AUR: ${aur[*]}"
      ;;
    fedora)
      for p in $names; do rpm -q "$p" >/dev/null 2>&1 || missing+=("$p"); done
      ((${#missing[@]})) && step "sudo dnf install ${missing[*]}"
      ;;
  esac
  return 0
}

need_flatpaks() {
  local ref id ids=() refs=()
  for ref in $(list flatpaks.txt); do
    id=${ref##*/}
    id=${id%.flatpakref}
    flatpak info "$id" >/dev/null 2>&1 && continue
    if [[ $ref == https://* ]]; then refs+=("$ref"); else ids+=("$ref"); fi
  done
  ((${#ids[@]} + ${#refs[@]})) || return 0
  grep -qx flathub <<<"$(flatpak remotes --user --columns=name 2>/dev/null)" ||
    step "flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
  ((${#ids[@]})) && step "flatpak install --user flathub ${ids[*]}"
  for ref in "${refs[@]}"; do step "flatpak install --user $ref"; done
  return 0
}

need_copr() {
  [[ $DISTRO == fedora ]] || return 0
  grep -q "/$1$" <<<"$(dnf copr list 2>/dev/null)" || step "sudo dnf copr enable -y $1"
}

# need_file <repo file> <system path> [<reload command>] [<sed script>]
# A path only root can read (sshd_config.d is 0700) is compared to the hash its
# printed command records once it runs.
need_file() {
  local src=$1 dest=$2 reload=${3:-} script=${4:-} cmd want key dir=$2
  if [[ -n $script ]]; then
    cmd="sed '$script' $REPO_SHOWN/$src | sudo install -Dm644 /dev/stdin $dest"
    want=$(sed "$script" "$REPO/$src" | sha256sum | cut -d' ' -f1)
  else
    cmd="sudo install -Dm644 $REPO_SHOWN/$src $dest"
    want=$(sha256sum <"$REPO/$src" | cut -d' ' -f1)
  fi
  [[ -n $reload ]] && cmd+=" && $reload"
  until [[ -z $dir || -d $ROOT$dir ]]; do dir=${dir%/*}; done
  if [[ -r $ROOT$dest || ( -x $ROOT${dir:-/} && ! -e $ROOT$dest ) ]]; then
    [[ $({ sha256sum <"$ROOT$dest"; } 2>/dev/null | cut -d' ' -f1) == "$want" ]] || step "$cmd"
    return 0
  fi
  key=manual-file-$(tr / _ <<<"$dest")
  [[ $(cat "$STATE/$key" 2>/dev/null) == "$want" ]] && return 0
  step "$cmd && mkdir -p ${STATE/#"$HOME"/\~} && echo $want > ${STATE/#"$HOME"/\~}/$key"
  note "could not read $dest; asked until the command above runs"
}

need_enabled() {
  local off=() unit
  for unit; do
    [[ $(systemctl is-enabled "$unit" 2>/dev/null) == enabled ]] || off+=("$unit")
  done
  ((${#off[@]})) && step "sudo systemctl enable --now ${off[*]}"
  return 0
}

need_firewall() {
  have firewall-cmd || return 0
  local closed=() rule
  for rule; do
    [[ $(firewall-cmd "--query-${rule#--add-}" 2>/dev/null) == yes ]] || closed+=("$rule")
  done
  ((${#closed[@]})) && step "sudo firewall-cmd --permanent ${closed[*]} && sudo firewall-cmd --reload"
  return 0
}

need_cmd() {
  local missing=() cmd
  for cmd; do have "$cmd" || missing+=("$cmd"); done
  ((${#missing[@]})) && note "not found, install with its own installer: ${missing[*]}"
  return 0
}

# A system service that reads files from the home is restarted by hand after they
# change; the printed command records their hash so it is asked once.
need_restart() {
  local unit=$1 key=$2 hash
  shift 2
  hash=$(cat "$@" 2>/dev/null | sha256sum | cut -d' ' -f1)
  [[ $(cat "$STATE/manual-$key" 2>/dev/null) == "$hash" ]] && return
  step "sudo systemctl restart $unit && mkdir -p ${STATE/#"$HOME"/\~} && echo $hash > ${STATE/#"$HOME"/\~}/manual-$key"
}

modules=("$@")
if ((${#modules[@]} == 0)); then
  config=$REPO/.dotter/local.toml
  [[ -f $config ]] || config=$REPO/.dotter/$(hostname -s).toml
  mapfile -t modules < <(sed -n 's/^packages *= *\[\(.*\)\]/\1/p' "$config" | tr -d '" ' | tr , '\n')
fi
for MODULE in "${modules[@]}"; do
  [[ -f $REPO/$MODULE/manual.sh ]] || { echo "missing.sh: no module $MODULE" >&2; exit 2; }
done

printed=0
for MODULE in "${modules[@]}"; do
  lines=()
  # shellcheck source=/dev/null
  source "$REPO/$MODULE/manual.sh"
  ((${#lines[@]})) || continue
  ((printed++)) || echo "Still to do by hand:"
  echo "==> $MODULE"
  printf '%s\n' "${lines[@]}"
done
exit 0
