local programs = require("variables")
local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local ipc = "noctalia msg "

local directions = {
  LEFT = "H",
  DOWN = "J",
  UP = "K",
  RIGHT = "L",
}

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(ipc .. "session lock"))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. "+" .. directions.LEFT, hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. "+" .. directions.DOWN, hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. "+" .. directions.RIGHT, hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. "+" .. directions.UP, hl.dsp.focus({ direction = "up" }))

hl.bind(mainMod .. " + SHIFT +" .. directions.LEFT, hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT +" .. directions.DOWN, hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT +" .. directions.RIGHT, hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT +" .. directions.UP, hl.dsp.window.move({ direction = "up" }))

hl.bind(
  mainMod .. " + CTRL +" .. directions.LEFT,
  hl.dsp.window.resize({ x = -40, y = 0, relative = true }),
  { repeating = true }
)
hl.bind(
  mainMod .. " + CTRL +" .. directions.DOWN,
  hl.dsp.window.resize({ x = 0, y = 40, relative = true }),
  { repeating = true }
)
hl.bind(
  mainMod .. " + CTRL +" .. directions.RIGHT,
  hl.dsp.window.resize({ x = 40, y = 0, relative = true }),
  { repeating = true }
)
hl.bind(
  mainMod .. " + CTRL +" .. directions.UP,
  hl.dsp.window.resize({ x = 0, y = -40, relative = true }),
  { repeating = true }
)

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
  local key = i % 10 -- 10 maps to key 0
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Core binds
hl.bind(mainMod .. "+D", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. "+C", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. "+comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"))

-- SUPER+P abre o seletor (plugin raphael/hypr-displays).
hl.bind(
  mainMod .. " + P",
  hl.dsp.exec_cmd(
    "noctalia msg plugin raphael/hypr-displays:modes all next; noctalia msg panel-open raphael/hypr-displays:modes"
  )
)

-- Fora de monitors.lua: declarados junto com hl.monitor, param de disparar (hyprwm/Hyprland#14858).
hl.bind("switch:on:Lid Switch", function()
  require("monitors").evaluate()
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
  require("monitors").evaluate()
end, { locked = true })

-- Print abre o seletor do plugin raphael/hypr-shots: área, monitor, janela ou
-- anotação, escolhidos com setas ou 1-6.
hl.bind("Print", hl.dsp.exec_cmd(ipc .. "panel-open raphael/hypr-shots:menu"))
