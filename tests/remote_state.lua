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

local SHOW = { kind = "special", show = true }
local HIDE = { kind = "special", show = false }
local REMOTE = { kind = "submap", name = "remote" }
local RESET = { kind = "submap", name = "reset" }

local function shown()
  local s = R.new("fedora")
  R.special_active(s, s.ws)
  return s
end

do
  local s = R.new("fedora")
  check("special workspace is named after the peer", s.ws, "special:fedora")
  check("messages name the peer", R.msg(s, "taken"), "fedora stream closed: fedora is now watching this screen")
  check("checking message", R.msg(s, "checking"), "Checking if fedora is on...")
  check("no_stream message", R.msg(s, "no_stream"), "fedora is on, but Sunshine is not answering")
end

do
  local s = R.new("fedora")
  check("toggle hidden, no stream: probes", R.toggle(s, false),
    { { kind = "notify", text = R.msg(s, "checking") }, { kind = "probe" } })
  check("probing is remembered", s.probing, true)
  check("second toggle while probing does nothing", R.toggle(s, false), {})
end

do
  local s = R.new("arch")
  check("toggle hidden, stream alive: shows it", R.toggle(s, true),
    { SHOW, { kind = "focus_stream" }, REMOTE })
  check("showing directly does not probe", s.probing, false)
end

do
  local s = shown()
  check("toggle shown hides", R.toggle(s, true), { RESET, HIDE })
end

do
  local s = R.new("fedora")
  R.toggle(s, false)
  check("probe sunshine ok, no stream: launches", R.probe_result(s, true, true, false),
    { SHOW, { kind = "notify", text = R.msg(s, "opening") }, { kind = "launch" }, REMOTE })
  local t = R.new("fedora")
  R.toggle(t, false)
  check("probe sunshine ok, stream running: focuses", R.probe_result(t, true, true, true),
    { SHOW, { kind = "focus_stream" }, REMOTE })
end

do
  local s = R.new("fedora")
  R.toggle(s, false)
  check("probe ssh only", R.probe_result(s, false, true, false),
    { { kind = "notify", text = R.msg(s, "no_stream") } })
  R.toggle(s, false)
  check("probe nothing", R.probe_result(s, false, false, false),
    { { kind = "notify", text = R.msg(s, "off") } })
  check("probe reply when not probing is ignored", R.probe_result(s, true, true, true), {})
end

do
  local s = R.new("fedora")
  R.toggle(s, false)
  R.probe_timeout(s)
  check("lost probe reply does not block the next toggle", R.toggle(s, false),
    { { kind = "notify", text = R.msg(s, "checking") }, { kind = "probe" } })
end

do
  local s = R.new("fedora")
  check("special shown enters passthrough", R.special_active(s, s.ws), { REMOTE })
  check("special shown is remembered", s.shown, true)
  check("special hidden resets", R.special_active(s, nil), { RESET })
  check("hidden again does nothing", R.special_active(s, nil), {})
  check("another special workspace is not the stream", R.special_active(s, "special:magic"), {})
end

do
  local s = shown()
  check("moonlight opening marks viewing", R.window_open(s, R.CLASS, s.ws, "0x1"), { { kind = "viewing", on = true } })
  check("other app on the stream is moved out", R.window_open(s, "firefox", s.ws, "0xabc"),
    { { kind = "move_window", address = "0xabc" } })
  check("other app elsewhere is ignored", R.window_open(s, "firefox", "2", "0x2"), {})
end

do
  local s = shown()
  check("splash closing while the stream lives is ignored", R.window_close(s, R.CLASS, true, false), {})
  check("other window closing is ignored", R.window_close(s, "firefox", false, false), {})
end

do
  local s = R.new("fedora")
  check("last moonlight closes while hidden", R.window_close(s, R.CLASS, false, false),
    { { kind = "viewing", on = false }, { kind = "notify", text = R.msg(s, "closed") } })
  check("taken while hidden says why", R.window_close(s, R.CLASS, false, true),
    { { kind = "viewing", on = false }, { kind = "notify", text = R.msg(s, "taken") } })
end

do
  local s = shown()
  check("taken while shown hides and says why", R.window_close(s, R.CLASS, false, true), {
    { kind = "viewing", on = false }, RESET, HIDE, { kind = "notify", text = R.msg(s, "taken") },
  })
end

do
  local s = R.new("fedora")
  R.toggle(s, false)
  check("reload resets submap", R.on_config_reloaded(s), { RESET })
  check("reload clears probing", s.probing, false)
end

if failures > 0 then
  print("remote_state: " .. failures .. " failure(s)")
  os.exit(1)
end
print("remote_state: ok")
