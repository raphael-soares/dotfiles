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

M.MSG = {
  checking = "Checking if the desktop is on...",
  opening = "Desktop found, opening the stream",
  no_stream = "Desktop is on, but Sunshine is not streaming: no monitor connected to it, or nobody logged in",
  off = "Desktop is off or not on the network",
  closed = "Desktop stream closed",
}

local function enter_stream()
  return { { kind = "goto", ws = M.WS }, { kind = "focus_stream" }, REMOTE }
end

function M.toggle(state, current_ws, stream_alive)
  if current_ws == M.WS then
    return { RESET, { kind = "goto", ws = back(state) } }
  end
  if stream_alive then
    state.origin = current_ws
    return enter_stream()
  end
  if state.probing then
    return {}
  end
  state.origin = current_ws
  state.probing = true
  return { { kind = "notify", text = M.MSG.checking }, { kind = "probe" } }
end

function M.probe_result(state, sunshine_ok, ssh_ok, stream_running)
  state.probing = false
  if sunshine_ok and stream_running then
    return enter_stream()
  end
  if sunshine_ok then
    return { { kind = "goto", ws = M.WS }, { kind = "notify", text = M.MSG.opening }, { kind = "launch" }, REMOTE }
  end
  if ssh_ok then
    return { { kind = "notify", text = M.MSG.no_stream } }
  end
  return { { kind = "notify", text = M.MSG.off } }
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
  local lost = { kind = "notify", text = M.MSG.closed }
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
