local R = require("remote_state")

local HOST = "fedora.local"
local KEY = "SUPER + grave"
local state = R.new()
local M = {}

local function ws_key(ws)
  if not ws or not ws.name then
    return nil
  end
  if ws.name == R.WS:sub(6) then
    return R.WS
  end
  return tonumber(ws.name) and ws.name or "name:" .. ws.name
end

local function stream_running()
  for _, w in ipairs(hl.get_windows()) do
    if w.class == R.CLASS then
      return true
    end
  end
  return false
end

-- The probe runs outside the compositor so a powered off desktop never
-- blocks it; the shell reports back through `hyprctl eval`.
local function probe()
  local port = function(p)
    return "timeout 1 bash -c '</dev/tcp/" .. HOST .. "/" .. p .. "' 2>/dev/null && echo true || echo false"
  end
  hl.exec_cmd(
    'hyprctl eval "require(\\"remote\\").probe_done($('
      .. port(47989)
      .. "), $("
      .. port(22)
      .. '))"'
  )
end

local function run(actions)
  for _, a in ipairs(actions) do
    if a.kind == "probe" then
      probe()
    elseif a.kind == "goto" then
      hl.dispatch(hl.dsp.focus({ workspace = a.ws }))
    elseif a.kind == "launch" then
      hl.exec_cmd("moonlight stream " .. HOST .. " Desktop")
    elseif a.kind == "focus_stream" then
      hl.dispatch(hl.dsp.focus({ window = "class:" .. R.CLASS }))
    elseif a.kind == "submap" then
      hl.dispatch(hl.dsp.submap(a.name))
    elseif a.kind == "notify" then
      hl.exec_cmd("notify-send -a Desktop '" .. a.text .. "'")
    elseif a.kind == "move_window" then
      hl.dispatch(hl.dsp.window.move({ workspace = a.ws, window = "address:" .. a.address, follow = false }))
    end
  end
end

function M.probe_done(sunshine_ok, ssh_ok)
  run(R.probe_result(state, sunshine_ok, ssh_ok, stream_running()))
end

local function toggle()
  run(R.toggle(state, ws_key(hl.get_active_workspace())))
end

hl.bind(KEY, toggle)
hl.define_submap("remote", function()
  hl.bind(KEY, toggle)
end)

hl.window_rule({
  name = "desktop-stream",
  workspace = R.WS,
  fullscreen = true,
  match = { class = "^(" .. R.CLASS:gsub("%.", "\\.") .. ")$" },
})

hl.on("workspace.active", function(ws)
  run(R.workspace_active(state, ws_key(ws)))
end)
hl.on("window.open", function(w)
  run(R.window_open(state, w.class, ws_key(w.workspace), w.address))
end)
hl.on("window.close", function(w)
  run(R.window_close(state, w.class))
end)
hl.on("config.reloaded", function()
  run(R.on_config_reloaded(state))
end)

return M
