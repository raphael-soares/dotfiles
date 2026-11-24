#!/usr/bin/env bash
# Applies configuration inside the home only. Installing, downloading and anything
# that needs root is printed at the end by missing.sh for the owner to run.
set -euo pipefail

[[ ${DOTFILES_LINKS_ONLY:-} == 1 ]] && exit 0

REPO={{dotter.current_dir}}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
mkdir -p "$STATE"
have() { command -v "$1" >/dev/null; }
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
if have rbw && { rbw unlocked 2>/dev/null || [[ -t 0 ]]; }; then
  "$REPO/terminal/bin/secrets" pull || echo "==> secrets: run 'secrets setup' then 'secrets pull'"
fi
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
  jq '(.apps[] | select(.name == "Desktop")) |= del(."prep-cmd")' "$sunshine_apps" >"$sunshine_apps.new"
  mv "$sunshine_apps.new" "$sunshine_apps"
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
  systemctl --user mask --now fumon.service
fi
# libadwaita apps read the font from dconf, not from settings.ini. The icon theme comes
# from the Noctalia qt6ct template hook (noctalia/icon-theme.sh).
if have gsettings && gsettings writable org.gnome.desktop.interface font-name >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface font-name 'Sans 10'
  gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 10'
  gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
  gsettings set org.gnome.desktop.wm.preferences button-layout ':'
fi
systemctl --user enable --now gcr-ssh-agent.socket 2>/dev/null || true
# The "default" theme is what XCursor uses when the app asks for none.
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nInherits=Adwaita\n' >"$HOME/.icons/default/index.theme"
# Flatpak does not read the host settings.ini for the cursor; icons come from the portal.
if have flatpak; then
  flatpak override --user --unset-env=ICON_THEME --env=XCURSOR_THEME=Adwaita
fi
if have xdg-mime; then
  xdg-mime default org.gnome.Nautilus.desktop inode/directory
  xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp \
    image/avif image/heif image/tiff image/bmp image/svg+xml
  xdg-mime default org.gnome.Papers.desktop application/pdf
  xdg-mime default org.gnome.Showtime.desktop video/mp4 video/x-matroska video/webm \
    video/quicktime video/x-msvideo video/mpeg
  xdg-mime default org.gnome.TextEditor.desktop text/plain
fi
# Swapping the ~/.config/hypr link while Hyprland is running drops it into emergency mode.
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
  hyprctl reload >/dev/null && { noctalia msg config-reload || true; }
  hyprctl configerrors
fi
{{/if}}

{{#if dotter.packages.media}}
"$REPO/media/bin/media-deploy" "$REPO" || echo "==> media-deploy failed, see above" >&2
{{/if}}

{{#if dotter.packages.design}}
"$REPO/design/bin/design-deploy" "$REPO" || echo "==> design-deploy failed, see above" >&2
{{/if}}

{{#if dotter.packages.work}}
# Enterprise omp profile: its own auth (agent.db), the rest shared with the default one.
profile=$HOME/.omp/profiles/enterprise/agent
mkdir -p "$profile"
for item in AGENTS.md RULES.md config.yml keybindings.yml lsp.json skills prompts rules extensions themes; do
  ln -sfn "$REPO/ai/.omp/agent/$item" "$profile/$item"
done
{{/if}}
