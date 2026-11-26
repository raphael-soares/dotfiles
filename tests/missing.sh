#!/usr/bin/env bash
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# The stubs above must win over the host's id, getent and the like, so missing.sh runs
# under a real bash that resolves them through PATH.
BASH_REAL=$(type -P bash)
failures=0
fail() { echo "FAILED: $*"; failures=$((failures + 1)); }

# The machine: a file under $T/sys says something is installed, enabled or open.
# PATH holds only these stubs and the basic tools, so the host's own rpm or yay
# never answers.
mkdir -p "$T/bin" "$T/tools" "$T/sys"/{rpm,pacman,repo,flatpak,enabled,fw} "$T/root" "$T/state"
for c in bash sh sed sha256sum cmp grep cat mkdir awk sort cut head tr env dirname basename rm \
  hostname id getent readlink; do
  p=$(type -P "$c") && ln -s "$p" "$T/tools/$c"
done
S=$T/sys
cat >"$T/bin/rpm" <<EOF
#!/bin/sh
[ "\$1" = -q ] && [ -e "$S/rpm/\$2" ]
EOF
cat >"$T/bin/pacman" <<EOF
#!/bin/sh
case \$1 in
  -T) shift; rc=0; for p; do [ -e "$S/pacman/\$p" ] || { echo "\$p"; rc=127; }; done; exit \$rc ;;
  -Si) [ -e "$S/repo/\$2" ] ;;
esac
EOF
cat >"$T/bin/flatpak" <<EOF
#!/bin/sh
case \$1 in
  remotes) cat "$S/remotes" 2>/dev/null; exit 0 ;;
  info) [ -e "$S/flatpak/\$2" ] ;;
esac
EOF
cat >"$T/bin/dnf" <<EOF
#!/bin/sh
[ "\$1 \$2" = "copr list" ] && cat "$S/coprs" 2>/dev/null
exit 0
EOF
cat >"$T/bin/systemctl" <<EOF
#!/bin/sh
[ "\$1" = is-enabled ] && [ -e "$S/enabled/\$2" ] && echo enabled
[ "\$1" = is-active ] && [ -e "$S/active/\$2" ] && echo active
exit 0
EOF
cat >"$T/bin/firewall-cmd" <<EOF
#!/bin/sh
v=\${1#--query-*=}
[ -e "$S/fw/\$(echo "\$v" | tr / _)" ] && echo yes
EOF
printf '#!/bin/sh\nexit 0\n' >"$T/yay"
chmod +x "$T"/bin/* "$T/yay"

# A repo with fake modules: missing.sh reads the modules and their files from it.
R=$T/repo
mkdir -p "$R/.dotter" "$R/pkgs" "$R/flat" "$R/files" "$R/done"
cp "$REPO/.dotter/missing.sh" "$R/.dotter/missing.sh"
printf 'a\nb\n' >"$R/pkgs/packages.fedora.txt"
printf 'a\nb\naur-x\n' >"$R/pkgs/packages.arch.txt"
printf 'a\nb\n' >"$R/pkgs/packages.void.txt"
echo 'need_packages' >"$R/pkgs/manual.sh"
printf 'app.X\nhttps://example.org/y.flatpakref\n' >"$R/flat/flatpaks.txt"
echo 'need_flatpaks' >"$R/flat/manual.sh"
echo 'conf = 1' >"$R/files/plain.conf"
echo 'user = @USER@' >"$R/files/tmpl.conf"
cat >"$R/files/manual.sh" <<'EOF'
need_file files/plain.conf /etc/plain.conf "sudo udevadm control --reload"
need_file files/tmpl.conf /etc/tmpl.conf "" "s/@USER@/ana/"
need_file files/plain.conf /etc/locked/x.conf
EOF
: >"$R/done/manual.sh"
echo 'need_restart demo.service demo "$REPO/files/plain.conf"' >"$R/restart.sh"
mkdir -p "$R/restart" && mv "$R/restart.sh" "$R/restart/manual.sh"
mkdir -p "$R/fw" && echo 'need_firewall --add-port=7878/tcp --add-service=ssh' >"$R/fw/manual.sh"
mkdir -p "$R/svc" && echo 'need_enabled a.service' >"$R/svc/manual.sh"
echo 'packages = ["pkgs", "done"]' >"$R/.dotter/local.toml"

run() {
  local distro=$1
  shift
  PATH=$T/bin:$T/tools HOME=$T/home DOTFILES_DISTRO=$distro DOTFILES_ROOT=$T/root \
    XDG_STATE_HOME=$T/state "$BASH_REAL" "$R/.dotter/missing.sh" "$@"
}
expect() {
  local name=$1 want=$2 got=$3
  [[ $got == "$want" ]] || fail "$name: expected [$want], got [$got]"
}
has() { grep -qxF -- "$2" <<<"$3" || fail "$1: no line [$2] in [$3]"; }
lacks() { ! grep -qF -- "$2" <<<"$3" || fail "$1: has [$2] in [$3]"; }

mkdir -p "$S/active"
expect "service off" "Still to do by hand:
==> svc
sudo systemctl enable --now a.service" "$(run fedora svc)"
touch "$S/enabled/a.service"
has "service enabled but stopped" "sudo systemctl enable --now a.service" "$(run fedora svc)"
touch "$S/active/a.service"
expect "service on" "" "$(run fedora svc)"

touch "$S/rpm/a" "$S/rpm/b"
expect "fedora, everything installed" "" "$(run fedora pkgs)"

rm "$S/rpm/b"
expect "fedora, one rpm missing" $'Still to do by hand:\n==> pkgs\nsudo dnf install b' "$(run fedora pkgs)"

touch "$S/pacman/a" "$S/repo/b"
cp "$T/yay" "$T/bin/yay"
has "arch with yay" "yay -S --needed b aur-x" "$(run arch pkgs)"
rm "$T/bin/yay"
out=$(run arch pkgs)
has "arch without yay" "sudo pacman -S --needed b" "$out"
has "arch without yay" "# AUR: aur-x" "$out"

out=$(run void pkgs)
has "unknown distro" "# install by hand: a b" "$out"
lacks "unknown distro" "sudo" "$out"

out=$(run fedora flat)
has "flatpaks" "flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo" "$out"
has "flatpaks" "flatpak install --user flathub app.X" "$out"
has "flatpaks" "flatpak install --user https://example.org/y.flatpakref" "$out"
echo flathub >"$S/remotes"
lacks "flatpaks, Flathub already added" "remote-add" "$(run fedora flat)"
touch "$S/flatpak/app.X" "$S/flatpak/y"
expect "flatpaks, all installed" "" "$(run fedora flat)"

mkdir -p "$T/root/etc"
cp "$R/files/plain.conf" "$T/root/etc/plain.conf"
echo 'user = ana' >"$T/root/etc/tmpl.conf"
mkdir -p "$T/root/etc/locked"
cp "$R/files/plain.conf" "$T/root/etc/locked/x.conf"
chmod 000 "$T/root/etc/locked"
out=$(run fedora files)
lacks "file equal" "/etc/plain.conf" "$out"
lacks "rendered file equal" "/etc/tmpl.conf" "$out"
if [[ -r $T/root/etc/locked/x.conf ]]; then
  echo "skipped: unreadable file check (running as root)"
else
  grep -qF "sudo install -Dm644 $R/files/plain.conf /etc/locked/x.conf && mkdir -p " <<<"$out" ||
    fail "unreadable file: no copy line in [$out]"
  has "unreadable file" "# could not read /etc/locked/x.conf; asked until the command above runs" "$out"
  mkdir -p "$T/state/dotfiles"
  sha256sum "$R/files/plain.conf" | cut -d' ' -f1 >"$T/state/dotfiles/manual-file-_etc_locked_x.conf"
  lacks "unreadable file, recorded" "/etc/locked/x.conf" "$(run fedora files)"
fi
chmod 755 "$T/root/etc/locked"
echo 'conf = 0' >"$T/root/etc/plain.conf"
echo 'user = bob' >"$T/root/etc/tmpl.conf"
out=$(run fedora files)
has "file differs" "sudo install -Dm644 $R/files/plain.conf /etc/plain.conf && sudo udevadm control --reload" "$out"
has "rendered file differs" "sed 's/@USER@/ana/' $R/files/tmpl.conf | sudo install -Dm644 /dev/stdin /etc/tmpl.conf" "$out"

out=$(run fedora restart)
line=$(grep '^sudo systemctl restart demo.service' <<<"$out" || true)
[[ -n $line ]] || fail "restart: no restart line in [$out]"
hash=$(sha256sum "$R/files/plain.conf" | cut -d' ' -f1)
mkdir -p "$T/state/dotfiles"
echo "$hash" >"$T/state/dotfiles/manual-demo"
expect "restart after the hash is recorded" "" "$(run fedora restart)"

out=$(run fedora fw)
has "firewall" "sudo firewall-cmd --permanent --add-port=7878/tcp --add-service=ssh && sudo firewall-cmd --reload" "$out"
touch "$S/fw/7878_tcp"
has "firewall, one open" "sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload" "$(run fedora fw)"

touch "$S/rpm/b"
rm "$S/flatpak/app.X"
out=$(run fedora "done" flat)
lacks "a complete module prints no header" "==> done" "$out"
has "the other module prints" "==> flat" "$out"

rm "$S/rpm/b"
out=$(run fedora)
has "no args read the machine's modules" "==> pkgs" "$out"

rc=0
run fedora nosuch >/dev/null 2>&1 || rc=$?
expect "unknown module" 2 "$rc"

# The repo's own modules, on the same stubbed machine.
real() {
  local distro=$1
  shift
  PATH=$T/bin:$T/tools HOME=$T/home DOTFILES_DISTRO=$distro DOTFILES_ROOT=$T/root \
    DOTFILES_CMDLINE=$T/cmdline XDG_STATE_HOME=$T/state DOTFILES_REPO=$REPO \
    "$BASH_REAL" "$REPO/.dotter/missing.sh" "$@"
}
mkdir -p "$T/home"
echo 'BOOT_IMAGE=/vmlinuz root=UUID=x ro' >"$T/cmdline"
has "home without the EDID argument" \
  'sudo grubby --update-kernel=ALL --args="drm.edid_firmware=DP-1:edid/lg-ultragear.bin video=DP-1:e"' \
  "$(real fedora home)"
echo 'BOOT_IMAGE=/vmlinuz drm.edid_firmware=DP-1:edid/lg-ultragear.bin video=DP-1:e' >"$T/cmdline"
lacks "home with the EDID argument" "grubby" "$(real fedora home)"

has "arch greetd config" \
  "sed 's/@GREETER@/greeter/' $REPO/hyprland/greetd/config.toml | sudo install -Dm644 /dev/stdin /etc/greetd/config.toml" \
  "$(real arch hyprland)"
grep -q "s/@GREETER@/greetd/" <<<"$(real fedora hyprland)" || fail "the greetd user does not follow the distro"
has "greetd is enabled by the shared module" "sudo systemctl enable --force greetd.service" "$(real arch hyprland)"
for m in "arch laptop" "fedora home"; do
  lacks "$m does not repeat the greetd config" "greetd/config.toml" "$(real $m)"
  lacks "$m does not repeat the greetd enable" "enable --force greetd" "$(real $m)"
  has "$m has its own PAM file" "sudo install -Dm644 $REPO/${m#* }/greetd/pam /etc/pam.d/greetd" "$(real $m)"
done
[[ $(real fedora home | grep -cx "sudo dracut -f --regenerate-all") == 1 ]] ||
  fail "home does not regenerate the initramfs exactly once"

printf '#!/bin/sh\n' >"$T/bin/sunshine"
printf '#!/bin/sh\necho "$1 cap_sys_admin=p"\n' >"$T/bin/getcap"
printf '#!/bin/sh\necho yes\n' >"$T/bin/loginctl"
chmod +x "$T/bin/sunshine" "$T/bin/getcap" "$T/bin/loginctl"
mkdir -p "$T/root/etc/systemd/system"
echo old >"$T/root/etc/systemd/system/sunshine-prelogin.service"
out=$(real fedora hyprland)
grep -F "/etc/systemd/system/sunshine-prelogin.service" <<<"$out" |
  grep -qF "&& sudo systemctl daemon-reload && sudo systemctl restart sunshine-prelogin.service" ||
  fail "a changed Sunshine unit does not restart Sunshine: [$out]"
rm "$T/bin/sunshine" "$T/bin/getcap" "$T/bin/loginctl"

lacks "hyprland on arch" "dnf copr" "$(real arch hyprland)"
has "hyprland on fedora without the copr" "sudo dnf copr enable -y lionheartp/Hyprland" "$(real fedora hyprland)"

out=$(real fedora sshd)
has "sshd without a key" "# add ~/.ssh/keys/personal.pub to ~/.ssh/authorized_keys, then run this again" "$out"
lacks "sshd without a key" "50-key-only" "$out"
mkdir -p "$T/home/.ssh" && echo 'ssh-ed25519 AAAA' >"$T/home/.ssh/authorized_keys"
has "sshd with a key" "sudo systemctl enable --now sshd avahi-daemon" "$(real fedora sshd)"

cat >"$T/bin/getent" <<'EOF'
#!/bin/sh
if [ "$2" = docker ]; then [ -e "$DOCKER_GROUP" ] && echo "docker:x:966:$USER" || echo "docker:x:966:"; exit 0; fi
exec /usr/bin/getent "$@"
EOF
cat >"$T/bin/id" <<'EOF'
#!/bin/sh
[ "$1" = -nG ] || exec /usr/bin/id "$@"
g=$(/usr/bin/id -nG | tr ' ' '\n' | grep -vx docker | tr '\n' ' ')
[ -e "$DOCKER_SESSION" ] && g="$g docker"
echo "$g"
EOF
chmod +x "$T/bin/getent" "$T/bin/id"
export DOCKER_GROUP=$T/docker-group DOCKER_SESSION=$T/docker-session
out=$(real fedora media)
has "media without Docker's repo" "sudo dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo" "$out"
has "media without the docker group" "sudo usermod -aG docker $USER" "$out"
has "media with Docker off" "sudo systemctl enable --now docker.service" "$out"
mkdir -p "$T/root/etc/yum.repos.d" && touch "$T/root/etc/yum.repos.d/docker-ce.repo"
lacks "media with Docker's repo" "docker-ce.repo" "$(real fedora media)"
while read -r p; do touch "$S/rpm/$p"; done <"$REPO/media/packages.fedora.txt"
touch "$S/fw/7878_tcp" "$S/fw/8990_tcp" "$S/enabled/docker.service" "$S/active/docker.service" "$DOCKER_GROUP"
out=$(real fedora media)
lacks "media in the docker group" "usermod" "$out"
has "media in the group, old session" "# reboot so this session and the user services get the docker group" "$out"
touch "$DOCKER_SESSION"
has "media without the Jellyfin app" "flatpak install --user flathub org.jellyfin.JellyfinDesktop" "$(real fedora media)"
touch "$S/flatpak/org.jellyfin.JellyfinDesktop"
out=$(real fedora media)
has "media without Stremio" "$REPO/media/install/stremio-enhanced" "$out"
has "media without Arr Pick" "# Arr Pick needs a gh account that reads raphael-soares/stremio-arr-pick" "$out"
mkdir -p "$T/home/.local/opt/stremio-enhanced" "$T/home/.config/stremio-enhanced/plugins"
install -m755 /dev/null "$T/home/.local/opt/stremio-enhanced/AppRun"
touch "$T/home/.config/stremio-enhanced/plugins/arr-pick.plugin.js"
expect "media with everything in place" "" "$(real fedora media)"
rm "$S/fw/8990_tcp"
has "media with a port closed" "sudo firewall-cmd --permanent --add-port=8990/tcp && sudo firewall-cmd --reload" "$(real fedora media)"

real fedora terminal ai desktop hyprland laptop work sshd home media >/dev/null 2>"$T/err" || fail "a real module failed"
[[ ! -s $T/err ]] || fail "real modules wrote errors: $(cat "$T/err")"

if ((failures)); then
  echo "missing: $failures failure(s)"
  exit 1
fi
echo "missing: ok"
