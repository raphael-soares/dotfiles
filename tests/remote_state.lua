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
  check("toggle outside probes and says so", R.toggle(s, "3"),
    { { kind = "notify", text = R.MSG.checking }, { kind = "probe" } })
  check("toggle remembers origin", s.origin, "3")
  check("second toggle while probing does nothing", R.toggle(s, "3"), {})
end

do
  local s = R.new()
  R.toggle(s, "3")
  check("reachable launches", R.probe_result(s, true, true, false), {
    { kind = "goto", ws = R.WS }, { kind = "notify", text = R.MSG.opening }, { kind = "launch" },
    { kind = "submap", name = "remote" },
  })
  local t = R.new()
  R.toggle(t, "3")
  check("reachable with stream running focuses", R.probe_result(t, true, true, true), {
    { kind = "goto", ws = R.WS }, { kind = "focus_stream" }, { kind = "submap", name = "remote" },
  })
end

do
  local s = R.new()
  check("toggle with stream alive goes straight in", R.toggle(s, "3", true), {
    { kind = "goto", ws = R.WS }, { kind = "focus_stream" }, { kind = "submap", name = "remote" },
  })
  check("direct switch does not probe", s.probing, false)
  R.workspace_active(s, R.WS)
  check("direct switch remembers origin", R.toggle(s, R.WS, true),
    { { kind = "submap", name = "reset" }, { kind = "goto", ws = "3" } })
end

do
  local s = R.new()
  R.toggle(s, "3")
  R.toggle(s, "3", true)
  R.workspace_active(s, R.WS)
  R.toggle(s, R.WS, true)
  R.workspace_active(s, "3")
  check("probe reply after a direct switch is ignored", R.probe_result(s, true, true, true), {})
end

do
  local s = R.new()
  R.toggle(s, "3")
  check("ssh only", R.probe_result(s, false, true, false),
    { { kind = "notify", text = R.MSG.no_stream } })
  check("probe done allows next toggle", R.toggle(s, "3"),
    { { kind = "notify", text = R.MSG.checking }, { kind = "probe" } })
  check("nothing answers", R.probe_result(s, false, false, false),
    { { kind = "notify", text = R.MSG.off } })
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
  check("splash closing while the stream window lives is ignored", R.window_close(s, R.CLASS, true), {})
  check("stream closes while inside", R.window_close(s, R.CLASS, false), {
    { kind = "submap", name = "reset" },
    { kind = "notify", text = R.MSG.closed },
    { kind = "goto", ws = "3" },
  })
  local t = inside("3")
  R.workspace_active(t, "5")
  check("stream closes while elsewhere", R.window_close(t, R.CLASS, false),
    { { kind = "notify", text = R.MSG.closed } })
  check("other window closing is ignored", R.window_close(t, "firefox", false), {})
end

do
  local s = R.new()
  R.toggle(s, "3")
  R.probe_timeout(s)
  check("lost probe reply does not block the next toggle", R.toggle(s, "3"),
    { { kind = "notify", text = R.MSG.checking }, { kind = "probe" } })
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
