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

hl.bind(
  mainMod .. " + M",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. "+" .. directions.LEFT, hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. "+" .. directions.DOWN, hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. "+" .. directions.RIGHT, hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. "+" .. directions.UP, hl.dsp.focus({ direction = "up" }))

hl.bind(mainMod .. " + SHIFT +" .. directions.LEFT, hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT +" .. directions.DOWN, hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT +" .. directions.RIGHT, hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT +" .. directions.UP, hl.dsp.window.swap({ direction = "up" }))

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

-- Window grouping (tabs)
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }))
hl.bind(mainMod .. " + ALT +" .. directions.LEFT, hl.dsp.window.move({ into_group = "l" }))
hl.bind(mainMod .. " + ALT +" .. directions.DOWN, hl.dsp.window.move({ into_group = "d" }))
hl.bind(mainMod .. " + ALT +" .. directions.RIGHT, hl.dsp.window.move({ into_group = "r" }))
hl.bind(mainMod .. " + ALT +" .. directions.UP, hl.dsp.window.move({ into_group = "u" }))
hl.bind(mainMod .. " + ALT + TAB", hl.dsp.group.next())
hl.bind(mainMod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev())

-- Toggle gaps/borders/rounding off (e.g. for screen sharing)
local saved_gaps = {
  gaps_in = hl.get_config("general.gaps_in"),
  gaps_out = hl.get_config("general.gaps_out"),
  border_size = hl.get_config("general.border_size"),
  rounding = hl.get_config("decoration.rounding"),
}
local gaps_off = false

hl.bind(mainMod .. " + SHIFT + G", function()
  gaps_off = not gaps_off
  if gaps_off then
    hl.config({
      general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
      decoration = { rounding = 0 },
    })
  else
    hl.config({
      general = { gaps_in = saved_gaps.gaps_in, gaps_out = saved_gaps.gaps_out, border_size = saved_gaps.border_size },
      decoration = { rounding = saved_gaps.rounding },
    })
  end
end)

-- Seletor de modo de monitor e clamshell automático vivem no plugin
-- raphael/hypr-displays da Noctalia. O primeiro SUPER+P abre no modo em vigor,
-- os seguintes avançam; Esc fecha, Enter confirma.
hl.bind(
  mainMod .. " + P",
  hl.dsp.exec_cmd(
    "noctalia msg plugin raphael/hypr-displays:watch all next; noctalia msg panel-open raphael/hypr-displays:modes"
  )
)

-- Print abre o seletor do plugin raphael/hypr-shots: área, monitor, janela ou
-- anotação, escolhidos com setas ou 1-6.
hl.bind("Print", hl.dsp.exec_cmd(ipc .. "panel-open raphael/hypr-shots:menu"))
