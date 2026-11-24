local M = {}

local MODES = { extend = true, external = true, internal = true }
local DEFAULT_MODE = "extend"
local ENABLE_TIMEOUT_MS = 5000
local SETTLE_MS = 100

-- highrr: the LG UltraGear runs at 144 Hz on both machines without a rule of its own.
local WILDCARD = { mode = "highrr", position = "auto", scale = "1" }
local RULES = require("host").monitors or {}

local RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR")
local PREF_PATH = RUNTIME_DIR and (RUNTIME_DIR .. "/hypr-display-mode")

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function readFile(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("a")
  f:close()
  return content
end

local function lines(cmd)
  local out = {}
  local p = io.popen(cmd)
  if not p then return out end
  for line in p:lines() do
    table.insert(out, line)
  end
  p:close()
  return out
end

local internal
local externals = {}
local entries = {}
for _, line in ipairs(lines("ls -1 /sys/class/drm")) do
  local name = line:match("^card%d+%-(.+)$")
  if name then
    entries[name] = line
    if not internal and (name:match("^eDP%-") or name:match("^LVDS%-") or name:match("^DSI%-")) then
      internal = name
    else
      table.insert(externals, name)
    end
  end
end

local LID_PATH
do
  local lid = lines("ls -1 /proc/acpi/button/lid 2>/dev/null")[1]
  if lid then LID_PATH = "/proc/acpi/button/lid/" .. lid .. "/state" end
end

local pref = PREF_PATH and readFile(PREF_PATH)
pref = pref and trim(pref)
if not MODES[pref] then pref = DEFAULT_MODE end

local declared = {}
local settleTimer, enableTimer

-- An output whose monitor shows the other machine counts as unplugged (bin/monitor-away).
local function away(name)
  return RUNTIME_DIR ~= nil and readFile(RUNTIME_DIR .. "/hypr-away/" .. name) ~= nil
end
local function connected(name)
  if away(name) then return false end
  local status = readFile("/sys/class/drm/" .. entries[name] .. "/status")
  return status ~= nil and trim(status) == "connected"
end

function M.lidClosed()
  if not LID_PATH then return false end
  local state = readFile(LID_PATH)
  return state ~= nil and state:find("closed") ~= nil
end
local lidClosed = M.lidClosed

local function declare(name, disabled)
  if declared[name] == disabled then return end
  local rule = RULES[name] or {}
  hl.monitor({
    output = name,
    disabled = disabled,
    mode = rule.mode or WILDCARD.mode,
    position = rule.position or WILDCARD.position,
    scale = rule.scale or WILDCARD.scale,
  })
  declared[name] = disabled
end

local function activeSet()
  local active = {}
  for _, m in ipairs(hl.get_monitors()) do
    active[m.name] = true
  end
  return active
end

function M.anyExternalConnected()
  for _, name in ipairs(externals) do
    if connected(name) then return true end
  end
  return false
end
local anyExternalConnected = M.anyExternalConnected

local function target()
  local anyExt = anyExternalConnected()
  local extOn = pref ~= "internal" or internal == nil
  local intOn = not anyExt or pref == "internal" or (pref == "extend" and not lidClosed())

  local want = {}
  if internal then want[internal] = intOn end
  for _, name in ipairs(externals) do
    want[name] = extOn and not (internal and away(name))
  end
  return want
end

local function missing(want)
  local active = activeSet()
  local names = {}
  for name, on in pairs(want) do
    if on and connected(name) and not active[name] then table.insert(names, name) end
  end
  return names
end

local function armEnableTimeout()
  if enableTimer then return end
  enableTimer = true
  hl.timer(function()
    enableTimer = nil
    local names = missing(target())
    if #names > 0 then
      hl.notification.create({
        text = table.concat(names, ", ") .. " did not turn on; keeping the other screen on",
        timeout = 5000,
      })
    end
  end, { timeout = ENABLE_TIMEOUT_MS, type = "oneshot" })
end

function M.evaluate()
  local want = target()
  for name, on in pairs(want) do
    if on then declare(name, false) end
  end

  -- Only turns off once what must stay on is already active: 0.56 only applies a
  -- rule on the frame of a monitor that is drawing, and with none the session is left
  -- without a screen (hyprwm/Hyprland#14496).
  if #missing(want) > 0 then
    armEnableTimeout()
    return
  end

  for name, on in pairs(want) do
    if not on then declare(name, true) end
  end
end

-- A monitor.* callback runs inside ensureMonitorStatus, which clears the reload
-- scheduled on return; a rule written there would be lost.
local function schedule()
  if settleTimer then return end
  settleTimer = true
  hl.timer(function()
    settleTimer = nil
    M.evaluate()
  end, { timeout = SETTLE_MS, type = "oneshot" })
end

function M.set(mode)
  if not MODES[mode] then
    error("monitors.set: invalid mode " .. tostring(mode))
  end
  pref = mode
  if PREF_PATH then
    local f = io.open(PREF_PATH, "w")
    if f then
      f:write(mode .. "\n")
      f:close()
    end
  end
  M.evaluate()
end

hl.monitor({ output = "", mode = WILDCARD.mode, position = WILDCARD.position, scale = WILDCARD.scale })

do
  local active, want = activeSet(), target()
  local anyWantedActive = false
  for name, on in pairs(want) do
    if on and active[name] then anyWantedActive = true end
  end
  for name, on in pairs(want) do
    declare(name, (not on) and anyWantedActive)
  end
end

hl.on("monitor.added", schedule)
hl.on("monitor.removed", schedule)

hl.on("hyprland.start", function()
  for name, rule in pairs(RULES) do
    if rule.peer_input then
      hl.exec_cmd("monitor-away " .. name .. " " .. rule.peer_input)
    end
  end
end)

return M
