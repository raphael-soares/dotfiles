-- Decisions for the desktop stream workspace, kept free of `hl` so plain Lua
-- can test them (tests/remote_state.lua). remote.lua executes the actions.
local M = {}

M.WS = "name:desktop"
M.CLASS = "com.moonlight_stream.Moonlight"
M.FALLBACK = "1"

local RESET = { kind = "submap", name = "reset" }
local REMOTE = { kind = "submap", name = "remote" }

function M.new()
  return { origin = nil, probing = false, on_ws = false }
end

local function back(state)
  return state.origin or M.FALLBACK
end

function M.toggle(state, current_ws)
  if current_ws == M.WS then
    return { RESET, { kind = "goto", ws = back(state) } }
  end
  if state.probing then
    return {}
  end
  state.origin = current_ws
  state.probing = true
  return { { kind = "probe" } }
end

function M.probe_result(state, sunshine_ok, ssh_ok, stream_running)
  state.probing = false
  if sunshine_ok then
    return { { kind = "goto", ws = M.WS }, { kind = stream_running and "focus_stream" or "launch" }, REMOTE }
  end
  if ssh_ok then
    return { { kind = "notify", text = "Desktop on, no graphical session" } }
  end
  return { { kind = "notify", text = "Desktop unavailable" } }
end

function M.workspace_active(state, ws)
  local was = state.on_ws
  state.on_ws = ws == M.WS
  if state.on_ws then
    return { REMOTE }
  end
  return was and { RESET } or {}
end

function M.window_open(state, class, ws, address)
  if ws ~= M.WS or class == M.CLASS then
    return {}
  end
  return { { kind = "move_window", address = address, ws = back(state) } }
end

-- Moonlight's splash and stream windows share CLASS and the splash unmaps once
-- streaming starts, so a close only counts when no CLASS window is left.
function M.window_close(state, class, stream_alive)
  if class ~= M.CLASS or stream_alive then
    return {}
  end
  local lost = { kind = "notify", text = "Connection to desktop lost" }
  if not state.on_ws then
    return { lost }
  end
  return { RESET, lost, { kind = "goto", ws = back(state) } }
end

function M.probe_timeout(state)
  state.probing = false
end

function M.on_config_reloaded(state)
  state.probing = false
  return { RESET }
end

return M
