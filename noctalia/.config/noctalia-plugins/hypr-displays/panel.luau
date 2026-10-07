local tr = noctalia.tr

local MODES = { "extend", "external", "internal" }
local GLYPHS = { "layout-columns", "device-desktop", "device-laptop" }
local CLICKS = { "onExtendClicked", "onExternalClicked", "onInternalClicked" }

local render
local cursor = 1
local st = { mode = "extend", internal = "", external = "", lidClosed = false }

local function trim(s)
  return noctalia.string.trim(s or "")
end

local function readMode()
  local dir = noctalia.getenv("XDG_RUNTIME_DIR")
  if not dir then return "extend" end
  local content = noctalia.readFile(dir .. "/hypr-display-mode")
  local mode = type(content) == "string" and trim(content) or ""
  for _, m in ipairs(MODES) do
    if m == mode then return mode end
  end
  return "extend"
end

local function detectOutputs()
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

  local internal, external = "", ""
  for _, name in ipairs(names) do
    if internal == "" and (name:sub(1, 3) == "eDP" or name:sub(1, 4) == "LVDS") then
      internal = name
    end
  end
  for _, name in ipairs(names) do
    if name ~= internal and external == "" then
      external = name
    end
  end
  return internal, external
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

local function readFacts()
  local internal, external = detectOutputs()
  return {
    mode = readMode(),
    internal = internal,
    external = external,
    lidClosed = readLid() == "closed",
  }
end

local function modeEnabled(mode)
  if mode == "internal" then return not st.lidClosed end
  return st.external ~= ""
end

local function indexOf(mode)
  for i, m in ipairs(MODES) do
    if m == mode then return i end
  end
  return 1
end

local function moveCursor(delta)
  local i = cursor
  for _ = 1, #MODES do
    i = ((i - 1 + delta) % #MODES) + 1
    if modeEnabled(MODES[i]) then
      cursor = i
      render()
      return
    end
  end
end

local function requestMode(mode)
  noctalia.runAsync({ "hyprctl", "eval", 'require("monitors").set("' .. mode .. '")' }, function(result)
    if not result or result.exitCode ~= 0 then
      local detail = result and trim((result.stdout or "") .. (result.stderr or "")) or ""
      if detail == "" then detail = tr("error.apply_failed") end
      noctalia.notifyError(tr("notify.title"), detail)
    end
  end)
  panel.close()
end

local function requestIndex(i)
  local mode = MODES[i]
  if mode and modeEnabled(mode) then
    requestMode(mode)
  end
end

function onExtendClicked()
  requestIndex(1)
end

function onExternalClicked()
  requestIndex(2)
end

function onInternalClicked()
  requestIndex(3)
end

function onCloseClicked()
  panel.close()
end

render = function()
  local subtitleText
  if st.external ~= "" then
    subtitleText = st.internal .. "  •  " .. st.external
  else
    subtitleText = tr("panel.no_external")
  end

  -- Um único destaque forte: o cursor. O modo em vigor só fica contornado,
  -- com um check, pra não parecer uma segunda opção selecionada.
  local buttons = {}
  for i, m in ipairs(MODES) do
    local isCursor = cursor == i
    local isActive = st.mode == m
    buttons[i] = ui.button({
      text = i .. ". " .. tr("panel." .. m) .. (isActive and "  ✓" or ""),
      glyph = GLYPHS[i],
      contentAlign = "start",
      controlSize = "lg",
      selected = isCursor,
      variant = isCursor and "primary" or (isActive and "outline" or "default"),
      enabled = modeEnabled(m),
      onClick = CLICKS[i],
    })
  end

  local children = {
    ui.row({ align = "center", gap = 8 }, {
      ui.label({ text = tr("panel.title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "close", onClick = "onCloseClicked" }),
    }),
    ui.label({ text = subtitleText, fontSize = 12, color = "on_surface_variant" }),
    ui.column({ gap = 8 }, buttons),
  }
  if st.lidClosed then
    table.insert(children, ui.label({ text = tr("panel.lid_closed"), fontSize = 11, color = "on_surface_variant" }))
  end

  panel.render(ui.column({ gap = 8, flexGrow = 1 }, children))
end

function onOpen(_context)
  st = readFacts()
  cursor = indexOf(st.mode)
  render()
end

-- SUPER+P can't be captured here (the host rejects Super chords), so the
-- keybind sends "next" over IPC.
function onIpc(event)
  if event == "next" then
    moveCursor(1)
  elseif event == "prev" then
    moveCursor(-1)
  end
end

function onKey(chord, pressed)
  if pressed ~= true then return end
  if chord == "Up" then
    moveCursor(-1)
  elseif chord == "Down" then
    moveCursor(1)
  elseif chord == "Return" or chord == "KP_Enter" then
    requestIndex(cursor)
  elseif chord == "1" then
    requestIndex(1)
  elseif chord == "2" then
    requestIndex(2)
  elseif chord == "3" then
    requestIndex(3)
  end
end
