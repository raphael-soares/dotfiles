package.path = arg[0]:gsub("tests/remote_state.lua$", "") .. "hyprland/hypr/?.lua;" .. package.path
local R = require("remote_state")

local failures = 0
local function check(name, actual, expected)
  local function dump(t)
    if type(t) ~= "table" then return tostring(t) end
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(x, y) return tostring(x) < tostring(y) end)
    local out = {}
    for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. "=" .. dump(t[k]) end
    return "{" .. table.concat(out, ",") .. "}"
  end
  local a, e = dump(actual), dump(expected)
  if a ~= e then
    failures = failures + 1
    print("FAILED: " .. name .. "\n  got:      " .. a .. "\n  expected: " .. e)
  end
end

local function inside(origin)
  local s = R.new()
  R.toggle(s, origin)
  R.probe_result(s, true, true, false)
  R.workspace_active(s, R.WS)
  return s
end

do
  local s = R.new()
  check("toggle outside probes", R.toggle(s, "3"), { { kind = "probe" } })
  check("toggle remembers origin", s.origin, "3")
  check("second toggle while probing does nothing", R.toggle(s, "3"), {})
end

do
  local s = R.new()
  R.toggle(s, "3")
  check("reachable launches", R.probe_result(s, true, true, false), {
    { kind = "goto", ws = R.WS }, { kind = "launch" }, { kind = "submap", name = "remote" },
  })
  local t = R.new()
  R.toggle(t, "3")
  check("reachable with stream running focuses", R.probe_result(t, true, true, true), {
    { kind = "goto", ws = R.WS }, { kind = "focus_stream" }, { kind = "submap", name = "remote" },
  })
end

do
  local s = R.new()
  R.toggle(s, "3")
  check("ssh only", R.probe_result(s, false, true, false),
    { { kind = "notify", text = "Desktop on, no graphical session" } })
  check("probe done allows next toggle", R.toggle(s, "3"), { { kind = "probe" } })
  check("nothing answers", R.probe_result(s, false, false, false),
    { { kind = "notify", text = "Desktop unavailable" } })
end

do
  local s = inside("3")
  check("toggle inside returns", R.toggle(s, R.WS),
    { { kind = "submap", name = "reset" }, { kind = "goto", ws = "3" } })
  local t = R.new()
  check("toggle inside without origin falls back", R.toggle(t, R.WS),
    { { kind = "submap", name = "reset" }, { kind = "goto", ws = R.FALLBACK } })
end

do
  local s = R.new()
  check("entering by other means enters passthrough", R.workspace_active(s, R.WS),
    { { kind = "submap", name = "remote" } })
  check("leaving resets", R.workspace_active(s, "2"), { { kind = "submap", name = "reset" } })
  check("moving between laptop workspaces does nothing", R.workspace_active(s, "4"), {})
end

do
  local s = inside("3")
  check("stream closes while inside", R.window_close(s, R.CLASS), {
    { kind = "submap", name = "reset" },
    { kind = "notify", text = "Connection to desktop lost" },
    { kind = "goto", ws = "3" },
  })
  local t = inside("3")
  R.workspace_active(t, "5")
  check("stream closes while elsewhere", R.window_close(t, R.CLASS),
    { { kind = "notify", text = "Connection to desktop lost" } })
  check("other window closing is ignored", R.window_close(t, "firefox"), {})
end

do
  local s = inside("3")
  check("intruder sent back", R.window_open(s, "firefox", R.WS, "0xabc"),
    { { kind = "move_window", address = "0xabc", ws = "3" } })
  check("moonlight stays", R.window_open(s, R.CLASS, R.WS, "0xdef"), {})
  check("window elsewhere ignored", R.window_open(s, "firefox", "2", "0x1"), {})
end

do
  local s = R.new()
  check("reload resets submap", R.on_config_reloaded(s), { { kind = "submap", name = "reset" } })
end

if failures > 0 then
  print("remote_state: " .. failures .. " failure(s)")
  os.exit(1)
end
print("remote_state: ok")
