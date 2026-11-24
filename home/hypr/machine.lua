local M = {}

M.peer = "arch"

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
