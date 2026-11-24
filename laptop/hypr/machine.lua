local M = {}

M.peer = "fedora"

M.monitors = {
  -- Desk: external on the left, laptop on the right.
  -- "auto" depended on the order the monitors appeared at boot.
  -- peer_input: the LG's DDC input code for fedora's cable; while it shows fedora the
  -- laptop runs on its own screen alone.
  ["DP-1"] = { position = "0x0", peer_input = 0x03 },
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
  -- The rule only places new workspaces: those that fell onto eDP-1 go back when DP-1 returns.
  hl.on("monitor.added", function(m)
    if m.name ~= "DP-1" then return end
    hl.timer(function()
      for i = 1, 10 do
        hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(i), monitor = "DP-1" }))
      end
    end, { timeout = 500, type = "oneshot" })
  end)

  require("lid")
end

return M
