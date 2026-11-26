-- The session environment goes to systemd before anything launches, in one shell so
-- the order holds: without it xdg-desktop-portal does not match the Hyprland backend
-- (it requires XDG_CURRENT_DESKTOP=Hyprland) and the GTK portal fails with "cannot open display".
local apps = {
  "noctalia",
  "flatpak run io.github.raphael_soares.syncfast --start-hidden",
  "flatpak run com.github.wwmm.easyeffects --service-mode --hide-window",
  "zapfast --start-hidden",
  "spotifast --start-hidden",
  "udiskie --automount --no-notify --no-tray",
  -- Flameshot's daemon owns the copied image, so it stays pasteable after the shot closes.
  "flameshot",
}

hl.on("hyprland.start", function()
  local script = "systemctl --user import-environment; dbus-update-activation-environment --systemd --all; "
  for _, app in ipairs(apps) do
    script = script .. app .. " & "
  end
  hl.exec_cmd(script)
end)
