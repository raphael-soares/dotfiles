local M = {}

local MODES = { extend = true, external = true, internal = true }
local DEFAULT_MODE = "extend"
local ENABLE_TIMEOUT_MS = 5000
local SETTLE_MS = 100

local WILDCARD = { mode = "preferred", position = "auto", scale = "1" }
local RULES = {}

-- 1080p60 padrao (148,5 MHz) e o VIC 16 da TV: o i915 manda faixa limitada
-- com Broadcast RGB automatico e o aquamarine nao seta a propriedade.
-- CVT-RB (cvt -r 1920 1080 60) nao casa com modo CEA e sai em faixa completa.
RULES["DP-1"] = {
  mode = "modeline 138.50 1920 1968 2000 2080 1080 1083 1088 1111 +hsync -vsync",
  position = "0x0",
  scale = "1",
}

-- Mesa: externo à esquerda, notebook à direita.
-- "auto" dependia da ordem em que os monitores apareciam no boot.
RULES["eDP-1"] = { mode = "preferred", position = "auto-right", scale = "1" }

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

local function connected(name)
  local status = readFile("/sys/class/drm/" .. entries[name] .. "/status")
  return status ~= nil and trim(status) == "connected"
end

local function lidClosed()
  if not LID_PATH then return false end
  local state = readFile(LID_PATH)
  return state ~= nil and state:find("closed") ~= nil
end

local function declare(name, disabled)
  if declared[name] == disabled then return end
  local rule = RULES[name] or WILDCARD
  hl.monitor({
    output = name,
    disabled = disabled,
    mode = rule.mode,
    position = rule.position,
    scale = rule.scale,
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

local function target()
  local anyExt = false
  for _, name in ipairs(externals) do
    if connected(name) then anyExt = true end
  end
  local extOn = pref ~= "internal" or internal == nil
  local intOn = not anyExt or pref == "internal" or (pref == "extend" and not lidClosed())

  local want = {}
  if internal then want[internal] = intOn end
  for _, name in ipairs(externals) do
    want[name] = extOn
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

  -- Só desliga quando o que deve ficar ligado já está ativo: o 0.56 só aplica
  -- regra no frame de um monitor que desenha, e sem nenhum a sessão fica sem
  -- tela (hyprwm/Hyprland#14496).
  if #missing(want) > 0 then
    armEnableTimeout()
    return
  end

  for name, on in pairs(want) do
    if not on then declare(name, true) end
  end
end

-- Callback de monitor.* roda dentro do ensureMonitorStatus, que zera o reload
-- agendado ao voltar; a regra gravada ali se perderia.
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

-- Externo é o principal: SUPER+1..0 só trocam o DP-1, e o notebook fica no 11.
-- Sem o DP-1 conectado, a regra não se aplica e os workspaces caem no eDP-1.
for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = i == 1 })
end
hl.workspace_rule({ workspace = "11", monitor = "eDP-1", default = true })

return M
