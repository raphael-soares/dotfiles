--!nonstrict
-- Owns every hyprctl call. The panel only reads "status" and writes "request";
-- it never touches Hyprland directly.

local tr = noctalia.tr

local internal, external, lid = "", "", ""
local currentMode = ""
local applying = false
local manualOverride = nil -- { mode, external, lid } snapshot in effect when chosen
local revision = 0
local lastRequestNonce = nil
local pending = nil -- conector visto uma vez só, ainda não confirmado
local lastApplyMs = 0
local failures = 0
local lastTarget = nil

local COOLDOWN_MS = 3000
local MAX_FAILURES = 3

local function trim(s)
  return noctalia.string.trim(s or "")
end

local function isValidConnector(name)
  return name ~= "" and name:match("^[A-Za-z0-9%-]+$") ~= nil
end

local function detectOutputs()
  local cfgInternal = trim(noctalia.getConfig("internal_output"))
  local cfgExternal = trim(noctalia.getConfig("external_output"))
  if cfgInternal ~= "" and cfgExternal ~= "" then
    return cfgInternal, cfgExternal
  end

  local names = {}
  local entries = noctalia.listDir("/sys/class/drm")
  if entries then
    for _, entry in ipairs(entries) do
      local dash = entry:find("-")
      if dash then
        local connector = entry:sub(dash + 1)
        local content = noctalia.readFile("/sys/class/drm/" .. entry .. "/status")
        if type(content) == "string" and trim(content) == "connected" then
          table.insert(names, connector)
        end
      end
    end
  end
  table.sort(names)

  local detectedInternal, detectedExternal = "", ""
  for _, name in ipairs(names) do
    if detectedInternal == "" and (name:sub(1, 3) == "eDP" or name:sub(1, 4) == "LVDS") then
      detectedInternal = name
    end
  end
  for _, name in ipairs(names) do
    if name ~= detectedInternal and detectedExternal == "" then
      detectedExternal = name
    end
  end

  local resultInternal = cfgInternal ~= "" and cfgInternal or detectedInternal
  local resultExternal = cfgExternal ~= "" and cfgExternal or detectedExternal
  return resultInternal, resultExternal
end

local function readLid()
  local entries = noctalia.listDir("/proc/acpi/button/lid")
  if not entries then return "" end
  for _, entry in ipairs(entries) do
    local content = noctalia.readFile("/proc/acpi/button/lid/" .. entry .. "/state")
    if type(content) == "string" then
      if content:find("closed") then return "closed" end
      if content:find("open") then return "open" end
    end
  end
  return ""
end

local function getAutoEnabled()
  local v = noctalia.getConfig("auto_enabled")
  if v == nil then return true end
  return v == true or v == "true"
end

local function desiredAuto(i, e, l)
  if e == "" then return "internal" end
  if l == "closed" then return "external" end
  return "extend"
end

local function logicalWidth(name)
  if name == "" then return 1920 end
  local outputs = noctalia.outputs() or {}
  for _, o in ipairs(outputs) do
    if o.name == name then
      local scale = tonumber(o.scale) or 1
      if scale <= 0 then scale = 1 end
      local w = tonumber(o.width) or 1920
      return math.floor(w / scale + 0.5)
    end
  end
  return 1920
end

local function enableCmd(name, position, mirrorTarget)
  local extra = ""
  if mirrorTarget then
    extra = string.format(', mirror = "%s"', mirrorTarget)
  end
  return string.format(
    "hyprctl eval 'hl.monitor({ output = \"%s\", disabled = false, position = \"%s\", scale = \"1\"%s })'",
    name, position, extra
  )
end

local function disableCmd(name)
  return string.format("hyprctl eval 'hl.monitor({ output = \"%s\", disabled = true })'", name)
end

-- Sem "hyprctl reload" aqui: o reload reaplica a regra curinga de monitors.lua,
-- que liga tudo em posição automática, e era ele que desfazia o modo escolhido.
local function buildCommand(mode, internalName, externalName)
  local steps = {}

  if mode == "extend" then
    -- Arranjo físico da mesa: monitor à esquerda, notebook à direita.
    if externalName ~= "" then table.insert(steps, enableCmd(externalName, "0x0")) end
    if internalName ~= "" then
      local x = externalName ~= "" and logicalWidth(externalName) or 0
      table.insert(steps, enableCmd(internalName, x .. "x0"))
    end
  elseif mode == "external" then
    if externalName ~= "" then table.insert(steps, enableCmd(externalName, "0x0")) end
    if internalName ~= "" then table.insert(steps, disableCmd(internalName)) end
  elseif mode == "internal" then
    if internalName ~= "" then table.insert(steps, enableCmd(internalName, "0x0")) end
    if externalName ~= "" then table.insert(steps, disableCmd(externalName)) end
  elseif mode == "mirror" then
    if internalName ~= "" then table.insert(steps, enableCmd(internalName, "0x0")) end
    if externalName ~= "" then table.insert(steps, enableCmd(externalName, "0x0", internalName)) end
  end

  return table.concat(steps, "; ")
end

-- O modo que o Hyprland está executando agora, não o que o plugin acha que
-- mandou. Reload disparado por qualquer outra coisa (edição de config, tema)
-- religa os dois monitores, e sem ler o estado real a divergência ficaria de pé.
local function actualMode()
  local list = noctalia.outputs() or {}
  local hasInternal, hasExternal = false, false
  local ix, iy, ex, ey = 0, 0, 0, 0

  for _, o in ipairs(list) do
    if internal ~= "" and o.name == internal then
      hasInternal, ix, iy = true, o.x or 0, o.y or 0
    elseif external ~= "" and o.name == external then
      hasExternal, ex, ey = true, o.x or 0, o.y or 0
    end
  end

  if hasInternal and hasExternal then
    if ix == ex and iy == ey then return "mirror" end
    return "extend"
  elseif hasExternal then
    return "external"
  elseif hasInternal then
    return "internal"
  end
  return ""
end

local function publishStatus(errMsg)
  revision += 1
  noctalia.state.set("status", {
    mode = currentMode,
    internal = internal,
    external = external,
    lid = lid,
    auto = getAutoEnabled(),
    manual = manualOverride ~= nil,
    error = errMsg or "",
    revision = revision,
  })
end

local function applyMode(mode)
  if applying then return end

  if mode ~= "internal" and external == "" then
    noctalia.notifyError(tr("notify.title"), tr("panel.no_external"))
    publishStatus()
    return
  end
  if internal ~= "" and not isValidConnector(internal) then
    noctalia.notifyError(tr("notify.title"), tr("error.apply_failed"))
    publishStatus(tr("error.apply_failed"))
    return
  end
  if external ~= "" and not isValidConnector(external) then
    noctalia.notifyError(tr("notify.title"), tr("error.apply_failed"))
    publishStatus(tr("error.apply_failed"))
    return
  end

  applying = true
  lastTarget = mode
  lastApplyMs = noctalia.nowMs()
  local cmd = buildCommand(mode, internal, external)
  noctalia.runAsync(cmd, function(result)
    applying = false
    lastApplyMs = noctalia.nowMs()
    if not result or result.exitCode ~= 0 then
      local detail = result and trim(result.stderr or "") or ""
      if detail == "" then detail = tr("error.apply_failed") end
      failures += 1
      if failures >= MAX_FAILURES then
        noctalia.notifyError(tr("notify.title"), detail)
      end
      publishStatus(detail)
    else
      currentMode = mode
      publishStatus()
    end
  end)
end

-- Uma volta do laço: confirma os fatos, decide o alvo e só mexe no Hyprland
-- quando o que está na tela difere do alvo.
local function evaluate()
  local newInternal, newExternal = detectOutputs()
  local newLid = readLid()

  -- O conector some por um instante quando o monitor entra em DPMS ou o cabo
  -- balança, então muda de fato só com duas leituras iguais seguidas. A tampa
  -- vem do /proc e não oscila, então vale na hora.
  if newExternal ~= external then
    if pending == newExternal then
      pending = nil
      failures = 0
    else
      pending = newExternal
      lid = newLid
      publishStatus()
      return
    end
  else
    pending = nil
  end

  if manualOverride and (newExternal ~= manualOverride.external or newLid ~= manualOverride.lid) then
    manualOverride = nil
  end

  internal, external, lid = newInternal, newExternal, newLid
  currentMode = actualMode()

  if applying or (noctalia.nowMs() - lastApplyMs) < COOLDOWN_MS then
    publishStatus()
    return
  end

  local targetMode = nil
  if manualOverride then
    targetMode = manualOverride.mode
  elseif getAutoEnabled() then
    targetMode = desiredAuto(internal, external, lid)
  end

  if targetMode == nil or targetMode == currentMode then
    failures = 0
    lastTarget = nil
    publishStatus()
    return
  end

  -- Alvo que o Hyprland aceita mas não cumpre (pedir extend de tampa fechada,
  -- por exemplo) reaplicaria pra sempre. Três tentativas e para até os fatos
  -- mudarem.
  if lastTarget == targetMode then
    failures += 1
  end

  if failures >= MAX_FAILURES then
    publishStatus(tr("error.apply_failed"))
  else
    applyMode(targetMode)
  end
end

noctalia.state.watch("request", function(payload)
  if type(payload) ~= "table" then return end
  local nonce = payload.nonce
  if nonce ~= nil and nonce == lastRequestNonce then return end
  lastRequestNonce = nonce

  local mode = payload.mode
  if mode ~= "extend" and mode ~= "external" and mode ~= "internal" and mode ~= "mirror" then return end

  internal, external = detectOutputs()
  lid = readLid()
  manualOverride = { mode = mode, external = external, lid = lid }
  failures = 0
  lastTarget = nil
  currentMode = actualMode()

  if applying then
    publishStatus()
    return
  end

  if mode ~= currentMode then
    applyMode(mode)
  else
    publishStatus()
  end
end)

if not noctalia.commandExists("hyprctl") then
  publishStatus(tr("error.hyprctl_missing"))
else
  noctalia.setUpdateInterval(1000)
  evaluate()
end

function update()
  evaluate()
end

function onOutputsChanged()
  evaluate()
end

function onConfigChanged()
  evaluate()
end

local MODES = { "extend", "external", "internal", "mirror" }

local function modeEnabled(mode)
  return mode == "internal" or external ~= ""
end

local function modeIndex(mode)
  for i, m in ipairs(MODES) do
    if m == mode then return i end
  end
  return 1
end

-- SUPER+P can't reach the panel (the host rejects Super chords in
-- capture_keys), so the keybind sends "next" here and the panel follows
-- "cursor". With the panel closed the first press only parks the cursor on
-- the mode in effect: a filled button on a mode the user is not in reads as
-- "you are here" and confuses. Walking starts from the second press on.
local function advanceCursor(delta)
  if noctalia.state.get("panelOpen") ~= true then
    noctalia.state.set("cursor", modeIndex(currentMode))
    return
  end

  local stored = noctalia.state.get("cursor")
  local i = type(stored) == "number" and MODES[stored] and stored or modeIndex(currentMode)
  for _ = 1, #MODES do
    i = ((i - 1 + delta) % #MODES) + 1
    if modeEnabled(MODES[i]) then
      noctalia.state.set("cursor", i)
      return
    end
  end
end

-- Lets `noctalia msg plugin raphael/hypr-displays:watch all <mode>` (or
-- `... request <mode>`) drive a manual switch from the terminal, exactly as
-- if the panel had published a request — useful for headless testing.
function onIpc(event, payload)
  if event == "next" then
    advanceCursor(1)
    return
  elseif event == "prev" then
    advanceCursor(-1)
    return
  end

  local mode = nil
  if event == "extend" or event == "external" or event == "internal" or event == "mirror" then
    mode = event
  elseif event == "request" then
    if type(payload) == "string" then
      mode = payload
    elseif type(payload) == "table" and type(payload.mode) == "string" then
      mode = payload.mode
    end
  end
  if mode then
    noctalia.state.set("request", { mode = mode, nonce = noctalia.nowMs() })
  end
end
