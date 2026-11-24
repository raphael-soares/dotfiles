local peer = require("host").peer
if not peer then
  return {}
end

local R = require("remote_state")

local HOST = peer .. ".local"
local KEY = "SUPER + grave"
local DIR = os.getenv("XDG_RUNTIME_DIR") .. "/remote"
local VIEWING = DIR .. "/viewing"
local SERVING = DIR .. "/serving"
local state = R.new(peer)
local M = {}

-- Read by bin/remote-control and the bar panel, which do not know the peer.
os.execute("mkdir -p '" .. DIR .. "'")
local peer_file = io.open(DIR .. "/peer", "w")
if peer_file then
  peer_file:write(peer)
  peer_file:close()
end

local function stream_running()
  for _, w in ipairs(hl.get_windows()) do
    if w.class == R.CLASS then
      return true
    end
  end
  return false
end

-- Linger keeps the runtime dir across logout and crashes, so a viewing file can be stale.
if not stream_running() then
  os.remove(VIEWING)
end

local function serving()
  local f = io.open(SERVING, "r")
  if f then
    f:close()
  end
  return f ~= nil
end

local function mark_viewing(on)
  if on then
    os.execute("mkdir -p '" .. DIR .. "'")
    local f = io.open(VIEWING, "w")
    if f then
      f:close()
    end
  else
    os.remove(VIEWING)
  end
end

-- The probe runs outside the compositor so a machine that is off never
-- blocks it; the shell reports back through `hyprctl eval`.
local function probe()
  local port = function(p)
    return "timeout 2 bash -c '</dev/tcp/" .. HOST .. "/" .. p .. "' 2>/dev/null && echo true || echo false"
  end
  -- pgrep: a Moonlight just launched has no window yet, and a second press would start another.
  hl.exec_cmd(
    'hyprctl eval "require(\\"remote\\").probe_done($('
      .. port(47989)
      .. "), $("
      .. port(22)
      .. "), $(pgrep -x moonlight >/dev/null && echo true || echo false))\""
  )
end

local function run(actions)
  for _, a in ipairs(actions) do
    if a.kind == "probe" then
      probe()
    elseif a.kind == "special" then
      if a.show ~= state.shown then
        hl.dispatch(hl.dsp.workspace.toggle_special(peer))
      end
    elseif a.kind == "launch" then
      hl.exec_cmd("moonlight stream " .. HOST .. " Desktop")
    elseif a.kind == "focus_stream" then
      hl.dispatch(hl.dsp.focus({ window = "class:" .. R.CLASS }))
    elseif a.kind == "submap" then
      hl.dispatch(hl.dsp.submap(a.name))
    elseif a.kind == "notify" then
      -- The synchronous hint makes each step replace the previous one instead of stacking.
      hl.exec_cmd(
        "notify-send -a " .. peer .. " -h string:x-canonical-private-synchronous:remote " .. peer .. " '" .. a.text .. "'"
      )
    elseif a.kind == "move_window" then
      local w = hl.get_window("address:" .. a.address)
      local ws = w and hl.get_active_workspace(w.monitor)
      if ws then
        hl.dispatch(hl.dsp.window.move({ workspace = ws, window = "address:" .. a.address, follow = false }))
      end
    elseif a.kind == "viewing" then
      mark_viewing(a.on)
    end
  end
end

function M.probe_done(sunshine_ok, ssh_ok, moonlight_running)
  run(R.probe_result(state, sunshine_ok, ssh_ok, moonlight_running or stream_running()))
end

local probe_gen = 0
local function toggle()
  local was_probing = state.probing
  run(R.toggle(state, stream_running()))
  if state.probing and not was_probing then
    probe_gen = probe_gen + 1
    local gen = probe_gen
    hl.timer(function()
      if gen == probe_gen then
        R.probe_timeout(state)
      end
    end, { timeout = 5000, type = "oneshot" })
  end
end

-- bin/remote-control and the bar panel call it through `hyprctl eval`.
M.toggle = toggle

-- dont_inhibit: Moonlight's own keyboard grab (Ctrl+Alt+Shift+Z) would otherwise swallow the way out.
hl.bind(KEY, toggle, { dont_inhibit = true })
hl.define_submap("remote", function()
  hl.bind(KEY, toggle, { dont_inhibit = true })
end)

hl.window_rule({
  name = "remote-stream",
  workspace = state.ws,
  fullscreen = true,
  match = { class = "^(" .. R.CLASS:gsub("%.", "\\.") .. ")$" },
})

hl.on("workspace.special_active", function(ws)
  run(R.special_active(state, ws and ws.name))
end)
hl.on("window.open", function(w)
  run(R.window_open(state, w.class, w.workspace and w.workspace.name, w.address))
end)
local close_pending = false
hl.on("window.close", function(w)
  if w.class ~= R.CLASS or close_pending then
    return
  end
  close_pending = true
  -- The window is gone by the time the timer fires and its fields read empty.
  hl.timer(function()
    close_pending = false
    run(R.window_close(state, R.CLASS, stream_running(), serving()))
  end, { timeout = 1500, type = "oneshot" })
end)
hl.on("config.reloaded", function()
  run(R.on_config_reloaded(state))
end)

return M
