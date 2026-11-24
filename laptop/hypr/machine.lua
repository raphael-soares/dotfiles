local M = {}

M.peer = "fedora"

M.monitors = {
  -- Desk: external on the left, laptop on the right.
  -- "auto" depended on the order the monitors appeared at boot.
  ["DP-1"] = { position = "0x0" },
  ["eDP-1"] = { position = "auto-right" },
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

  -- External is the primary: SUPER+1..0 only switch DP-1, and the laptop stays on 11.
  -- Without DP-1 connected, the rule does not apply and the workspaces fall onto eDP-1.
  for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = i == 1 })
  end
  hl.workspace_rule({ workspace = "11", monitor = "eDP-1", default = true })

  require("lid")
end

return M
