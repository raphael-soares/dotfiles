-- The whole session environment goes to systemd before anything else: without it
-- xdg-desktop-portal does not match the Hyprland backend (it requires
-- XDG_CURRENT_DESKTOP=Hyprland) and the GTK portal fails with "cannot open display".
hl.on("hyprland.start", function()
  hl.exec_cmd(
    "systemctl --user import-environment $(env | cut -d= -f1) && dbus-update-activation-environment --systemd --all"
  )
  hl.exec_cmd("noctalia")
  hl.exec_cmd("flatpak run io.github.raphael_soares.syncfast --start-hidden")
  hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --service-mode --hide-window")
  hl.exec_cmd("flatpak run com.github.IsmaelMartinez.teams_for_linux --window.minimized")
  hl.exec_cmd("flatpak run com.rtosta.zapzap --hideStart")
  hl.exec_cmd("flatpak run rocks.spotifast.Spotifast")
  hl.exec_cmd("udiskie --automount --no-notify --no-tray")
end)
