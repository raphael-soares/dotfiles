local M = {}

M.monitors = {
  -- Standard 1080p60 (148.5 MHz) is the TV's VIC 16: i915 sends limited range
  -- with automatic Broadcast RGB and aquamarine does not set the property.
  -- CVT-RB (cvt -r 1920 1080 60) does not match a CEA mode and goes out in full range.
  ["DP-1"] = {
    mode = "modeline 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync -vsync",
    position = "0x0",
    scale = "1",
  },
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
