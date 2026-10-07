-- O ambiente inteiro da sessão vai pro systemd antes de tudo: sem ele o
-- xdg-desktop-portal não casa o backend do Hyprland (exige
-- XDG_CURRENT_DESKTOP=Hyprland) e o portal GTK falha com "cannot open display".
hl.on("hyprland.start", function()
  hl.exec_cmd(
    "systemctl --user import-environment $(env | cut -d= -f1) && dbus-update-activation-environment --systemd --all"
  )
  hl.exec_cmd("noctalia")
  hl.exec_cmd("flatpak run com.github.wwmm.easyeffects --service-mode --hide-window")
  hl.exec_cmd("flatpak run com.github.IsmaelMartinez.teams_for_linux --minimized")
  hl.exec_cmd("flatpak run com.rtosta.zapzap --hideStart")
  hl.exec_cmd("flatpak run com.spotify.Client")
  hl.exec_cmd("udiskie --automount --no-notify --no-tray")
end)
