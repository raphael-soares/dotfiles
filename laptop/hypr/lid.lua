local monitors = require("monitors")

local POLL_MS = 2000
local SUSPEND_MS = 10000

local function read(path)
  local f = io.open(path, "r")
  if not f then return "" end
  local content = f:read("a")
  f:close()
  return (content:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function list(dir)
  local out = {}
  local p = io.popen("ls -1 " .. dir .. " 2>/dev/null")
  if not p then return out end
  for line in p:lines() do
    table.insert(out, line)
  end
  p:close()
  return out
end

local TYPEC_PORTS = {}
for _, line in ipairs(list("/sys/class/typec")) do
  if line:match("^port%d+$") then table.insert(TYPEC_PORTS, line) end
end

local MAINS = {}
for _, line in ipairs(list("/sys/class/power_supply")) do
  local dir = "/sys/class/power_supply/" .. line .. "/"
  if read(dir .. "type") == "Mains" then table.insert(MAINS, dir .. "online") end
end

-- Dock = USB-C partner with DisplayPort alt mode (svid ff01); a plain charger has none.
-- Stays active when the monitor switches input or the peripherals go to the other PC.
local function dockAttached()
  for _, port in ipairs(TYPEC_PORTS) do
    local partner = "/sys/class/typec/" .. port .. "-partner/"
    local count = tonumber(read(partner .. "number_of_alternate_modes")) or 0
    for i = 0, count - 1 do
      if read(partner .. port .. "-partner." .. i .. "/svid") == "ff01" then return true end
    end
  end
  return false
end

local function onAC()
  for _, online in ipairs(MAINS) do
    if read(online) == "1" then return true end
  end
  return false
end

-- The hub blinks for ~3 s when its power fluctuates: only suspends after SUSPEND_MS
-- in a row with the lid closed, no external monitor, no dock and no charger.
-- On the charger it stays awake so the desktop can reach it over SSH.
local undockedPolls = 0
hl.timer(function()
  if not monitors.lidClosed() or monitors.anyExternalConnected() or dockAttached() or onAC() then
    undockedPolls = 0
    return
  end
  undockedPolls = undockedPolls + 1
  if undockedPolls * POLL_MS >= SUSPEND_MS then
    undockedPolls = 0
    hl.exec_cmd("systemctl suspend")
  end
end, { timeout = POLL_MS, type = "repeat" })

-- Takes the lid away from logind while this Hyprland lives; with no session (greeter, TTY) logind decides again.
hl.on("hyprland.start", function()
  local pid = read("/proc/self/stat"):match("^(%d+)")
  hl.exec_cmd(
    "systemd-inhibit --what=handle-lid-switch --who=Hyprland --why='lid.lua handles the lid' tail --pid="
      .. pid
      .. " -f /dev/null"
  )
end)
