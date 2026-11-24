-- Decisions for the special workspace that shows the other machine, kept free
-- of `hl` so plain Lua can test them (tests/remote_state.lua). remote.lua
-- executes the actions.
local M = {}

M.CLASS = "com.moonlight_stream.Moonlight"

local RESET = { kind = "submap", name = "reset" }
local REMOTE = { kind = "submap", name = "remote" }
local SHOW = { kind = "special", show = true }
local HIDE = { kind = "special", show = false }

local MSG = {
  checking = "Checking if %s is on...",
  opening = "%s found, opening the stream",
  no_stream = "%s is on, but Sunshine is not answering",
  off = "%s is off or not on the network",
  closed = "%s stream closed",
  taken = "%s stream closed: %s is now watching this screen",
}

function M.new(peer)
  return { peer = peer, ws = "special:" .. peer, probing = false, shown = false }
end

function M.msg(state, key)
  return (MSG[key]:gsub("%%s", state.peer))
end

local function notify(state, key)
  return { kind = "notify", text = M.msg(state, key) }
end

local function enter()
  return { SHOW, { kind = "focus_stream" }, REMOTE }
end

function M.toggle(state, stream_alive)
  if state.shown then
    return { RESET, HIDE }
  end
  if stream_alive then
    state.probing = false
    return enter()
  end
  if state.probing then
    return {}
  end
  state.probing = true
  return { notify(state, "checking"), { kind = "probe" } }
end

function M.probe_result(state, sunshine_ok, ssh_ok, stream_running)
  if not state.probing then
    return {}
  end
  state.probing = false
  if sunshine_ok and stream_running then
    return enter()
  end
  if sunshine_ok then
    return { SHOW, notify(state, "opening"), { kind = "launch" }, REMOTE }
  end
  return { notify(state, ssh_ok and "no_stream" or "off") }
end

function M.special_active(state, name)
  local was = state.shown
  state.shown = name == state.ws
  if state.shown then
    return { REMOTE }
  end
  return was and { RESET } or {}
end

function M.window_open(state, class, ws, address)
  if class == M.CLASS then
    return { { kind = "viewing", on = true } }
  end
  if ws == state.ws then
    return { { kind = "move_window", address = address } }
  end
  return {}
end

-- Moonlight's splash and stream windows share CLASS and the splash unmaps once
-- streaming starts, so a close only counts when no CLASS window is left.
function M.window_close(state, class, stream_alive, taken)
  if class ~= M.CLASS or stream_alive then
    return {}
  end
  local why = notify(state, taken and "taken" or "closed")
  if state.shown then
    return { { kind = "viewing", on = false }, RESET, HIDE, why }
  end
  return { { kind = "viewing", on = false }, why }
end

function M.probe_timeout(state)
  state.probing = false
end

function M.on_config_reloaded(state)
  state.probing = false
  return { RESET }
end

return M
