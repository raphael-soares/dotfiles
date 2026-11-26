#!/usr/bin/env bash
# Applies configuration inside the home only. Installing, downloading and anything
# that needs root is printed at the end by missing.sh for the owner to run.
set -euo pipefail

[[ ${DOTFILES_LINKS_ONLY:-} == 1 ]] && exit 0

REPO={{dotter.current_dir}}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
mkdir -p "$STATE"
have() { command -v "$1" >/dev/null; }
# An optional step that fails must not skip the steps after it.
try() { "$@" || echo "==> failed: $*" >&2; }
# On a fresh machine a step below can fail for a package not installed yet; the list of
# what to install is printed anyway.
trap '"$REPO/.dotter/missing.sh" {{#each dotter.packages}}{{#if this}}{{@key}} {{/if}}{{/each}}|| true' EXIT

{{#if dotter.packages.terminal}}
# Noctalia's Ghostty template rewrites the theme line of ~/.config/ghostty/config,
# so that file is a real one that only includes the repo's files. Ghostty resolves
# an include from the linked file's real path, so machine.conf is included here.
ghostty_config=$HOME/.config/ghostty/config
if [[ -L $ghostty_config || ! -e $ghostty_config ]]; then
  rm -f "$ghostty_config"
  printf 'config-file = base\nconfig-file = ?machine.conf\n' >"$ghostty_config"
fi
# Ghostty also reads config.ghostty and writes a template with no setting in it there
# when it starts before ~/.config/ghostty/config exists; it only repeats the comments.
ghostty_template=$HOME/.config/ghostty/config.ghostty
if [[ -f $ghostty_template ]] && ! grep -qvE '^[[:space:]]*(#|$)' "$ghostty_template"; then
  rm -f "$ghostty_template"
fi
"$REPO/terminal/bin/secrets" check || true
{{/if}}

{{#if dotter.packages.desktop}}
rules=$(cat "$REPO"/desktop/audio/wireplumber/* | sha256sum)
if [[ $(cat "$STATE/wireplumber" 2>/dev/null) != "$rules" ]] && have systemctl; then
  if systemctl --user restart wireplumber; then
    echo "$rules" >"$STATE/wireplumber"
    echo "==> WirePlumber restarted; reconnect Bluetooth to renegotiate A2DP"
  fi
fi
{{/if}}

{{#if dotter.packages.hyprland}}
# Sunshine runs from boot as a system unit, so the other machine reaches the login
# screen. Portal capture would wait on a permission dialog nobody sees there.
sunshine_conf=$HOME/.config/sunshine/sunshine.conf
mkdir -p "${sunshine_conf%/*}"
for line in 'capture = kms' 'system_tray = disabled'; do
  grep -qx "$line" "$sunshine_conf" 2>/dev/null || echo "$line" >>"$sunshine_conf"
done
# Installed next to Plasma, Sunshine's Desktop app toggles HDR with kscreen-doctor,
# which fails outside Plasma and so aborts every connection.
sunshine_apps=${sunshine_conf%/*}/apps.json
if have jq && jq -e 'any(.apps[] | select(.name == "Desktop") | ."prep-cmd"[]?; .do | test("kscreen-doctor"))' \
  "$sunshine_apps" >/dev/null 2>&1; then
  jq '(.apps[] | select(.name == "Desktop")) |= del(."prep-cmd")' "$sunshine_apps" >"$sunshine_apps.new" &&
    mv "$sunshine_apps.new" "$sunshine_apps" || echo "==> failed: Sunshine apps.json" >&2
fi
for unit in app-dev.lizardbyte.app.Sunshine.service sunshine.service; do
  systemctl --user disable --now "$unit" 2>/dev/null || true
done
# Moonlight's stream settings, the same on both machines: Super and the other system
# shortcuts always go to the other side, 10 Mbit/s (fedora is on Wi-Fi), the mouse set
# for a desktop ("mouseacceleration" is Moonlight's key for that option) and full screen
# (windowmode=1). Under Hyprland remote.lua makes the window fullscreen either way.
moonlight_conf="$HOME/.config/Moonlight Game Streaming Project/Moonlight.conf"
if pgrep -x moonlight >/dev/null; then
  echo "==> Moonlight is open and rewrites its settings on exit; deploy again after closing it"
else
  mkdir -p "${moonlight_conf%/*}"
  grep -qx '\[General\]' "$moonlight_conf" 2>/dev/null || printf '[General]\n' >>"$moonlight_conf"
  for setting in capturesyskeys=2 bitrate=10000 autoadjustbitrate=false mouseacceleration=true windowmode=1; do
    if grep -q "^${setting%%=*}=" "$moonlight_conf"; then
      sed -i "s/^${setting%%=*}=.*/$setting/" "$moonlight_conf"
    else
      sed -i "/^\[General\]$/a $setting" "$moonlight_conf"
    fi
  done
fi
# Fedora's hyprland pulls in uwsm, whose %post starts its failed-unit notifier in every
# graphical session, Plasma included. Neither session here runs under uwsm.
if systemctl --user cat fumon.service >/dev/null 2>&1; then
  try systemctl --user mask --now fumon.service
fi
# libadwaita apps read the font from dconf, not from settings.ini. The icon theme comes
# from the Noctalia qt6ct template hook (noctalia/icon-theme.sh).
if have gsettings && gsettings writable org.gnome.desktop.interface font-name >/dev/null 2>&1; then
  try gsettings set org.gnome.desktop.interface font-name 'Sans 10'
  try gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 10'
  try gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
  try gsettings set org.gnome.desktop.wm.preferences button-layout ':'
fi
systemctl --user enable --now gcr-ssh-agent.socket 2>/dev/null || true
# The "default" theme is what XCursor uses when the app asks for none.
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/icons/default"
printf '[Icon Theme]\nInherits=Adwaita\n' >"${XDG_DATA_HOME:-$HOME/.local/share}/icons/default/index.theme"
# Flatpak does not read the host settings.ini for the cursor; icons come from the portal.
if have flatpak; then
  try flatpak override --user --unset-env=ICON_THEME --env=XCURSOR_THEME=Adwaita
  # ~/Documents is a symlink into ~/Drive; xdg-documents alone does not reach the target.
  try flatpak override --user --filesystem="$HOME/Drive"
fi
if have xdg-mime; then
  try xdg-mime default org.gnome.Nautilus.desktop inode/directory
  try xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp \
    image/avif image/heif image/tiff image/bmp image/svg+xml
  try xdg-mime default org.gnome.Papers.desktop application/pdf
  try xdg-mime default org.gnome.Showtime.desktop video/mp4 video/x-matroska video/webm \
    video/quicktime video/x-msvideo video/mpeg
  try xdg-mime default org.gnome.TextEditor.desktop text/plain
fi
# Swapping the ~/.config/hypr link while Hyprland is running drops it into emergency mode.
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  try hyprctl reload >/dev/null
  try noctalia msg config-reload
  try hyprctl configerrors
fi
{{/if}}

{{#if dotter.packages.media}}
"$REPO/media/bin/media-deploy" "$REPO" || echo "==> media-deploy failed, see above" >&2
{{/if}}

{{#if dotter.packages.creative}}
"$REPO/creative/bin/creative-deploy" "$REPO" || echo "==> creative-deploy failed, see above" >&2
{{/if}}

{{#if dotter.packages.work}}
# Enterprise omp profile: its own auth (agent.db), the rest shared with the default one.
profile=$HOME/.omp/profiles/enterprise/agent
mkdir -p "$profile"
for item in AGENTS.md RULES.md config.yml keybindings.yml lsp.json mcp.json skills prompts rules extensions themes agents; do
  ln -sfn "$REPO/ai/.omp/agent/$item" "$profile/$item"
done
{{/if}}
