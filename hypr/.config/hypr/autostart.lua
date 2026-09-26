-- Sem estas variáveis no gerenciador de usuário do systemd, o xdg-desktop-portal
-- não casa o backend do Hyprland (ele exige XDG_CURRENT_DESKTOP=Hyprland) e
-- captura de tela e compartilhamento de tela somem do barramento.
hl.on("hyprland.start", function()
  hl.exec_cmd(
    "dbus-update-activation-environment --systemd "
      .. "XDG_CURRENT_DESKTOP XDG_SESSION_TYPE WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE "
      .. "QT_QPA_PLATFORMTHEME"
  )
  hl.exec_cmd("noctalia")
end)
