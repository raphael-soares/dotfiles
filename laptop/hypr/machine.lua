local M = {}

M.monitors = {
  ["DP-1"] = { mode = "1920x1080@143.99", position = "0x0", scale = "1" },
  -- Desk: external on the left, laptop on the right.
  -- "auto" depended on the order the monitors appeared at boot.
  ["eDP-1"] = { mode = "preferred", position = "auto-right", scale = "1" },
}

function M.setup()
  -- Outside monitors.lua: when declared next to hl.monitor, they stop firing (hyprwm/Hyprland#14858).
  hl.bind("switch:on:Lid Switch", function()
    require("monitors").evaluate()
  end, { locked = true, submap_universal = true })
  hl.bind("switch:off:Lid Switch", function()
    require("monitors").evaluate()
  end, { locked = true, submap_universal = true })

  hl.on("hyprland.start", function()
    hl.exec_cmd("flatpak run com.github.IsmaelMartinez.teams_for_linux --window.minimized")
  end)

  require("remote")
end

return M
