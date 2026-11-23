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
    -- Both are background layers and the last one mapped stays on top, so the
    -- desktop icons wait for the Noctalia wallpaper.
    hl.exec_cmd(
      "sh -c 'until hyprctl layers | grep -q noctalia-wallpaper; do sleep 0.5; done; exec pcmanfm-qt --desktop'"
    )
  end)
end

return M
