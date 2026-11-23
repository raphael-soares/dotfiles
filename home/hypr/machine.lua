local M = {}

M.monitors = {
  ["DP-1"] = { mode = "1920x1080@143.94", position = "0x0", scale = "1" },
}

function M.setup()
  hl.on("hyprland.start", function()
    hl.exec_cmd("discord --start-minimized")
    hl.exec_cmd("steam -silent")
    hl.exec_cmd("openrgb --startminimized")
    hl.exec_cmd("qbittorrent --no-splash")
    hl.exec_cmd("flatpak run com.dec05eba.gpu_screen_recorder gsr-ui")
  end)
end

return M
