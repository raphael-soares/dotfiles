local tr = noctalia.tr

local MODES = { "extend", "external", "internal", "mirror" }
local GLYPHS = { "layout-columns", "device-desktop", "device-laptop", "copy" }
local CLICKS = { "onExtendClicked", "onExternalClicked", "onInternalClicked", "onMirrorClicked" }

local render
local cursor = 1

local function status()
  return noctalia.state.get("status") or {}
end

-- Only "internal" survives without an external output plugged in.
local function modeEnabled(mode, st)
  if mode == "internal" then return true end
  return (st.external or "") ~= ""
end

local function indexOf(mode)
  for i, m in ipairs(MODES) do
    if m == mode then return i end
  end
  return 1
end

local function setCursor(i)
  cursor = i
  noctalia.state.set("cursor", i)
end

local function moveCursor(delta)
  local st = status()
  local i = cursor
  for _ = 1, #MODES do
    i = ((i - 1 + delta) % #MODES) + 1
    if modeEnabled(MODES[i], st) then
      setCursor(i)
      render()
      return
    end
  end
end

local function requestMode(mode)
  noctalia.state.set("request", { mode = mode, nonce = noctalia.nowMs() })
  panel.close()
end

local function requestIndex(i)
  local mode = MODES[i]
  if mode and modeEnabled(mode, status()) then
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

function onMirrorClicked()
  requestIndex(4)
end

function onCloseClicked()
  panel.close()
end

render = function()
  local st = status()
  local mode = st.mode or ""
  local internal = st.internal or ""
  local external = st.external or ""
  local lid = st.lid or ""
  local auto = st.auto
  local hasExternal = external ~= ""

  local subtitleText
  if hasExternal then
    subtitleText = internal .. "  •  " .. external
  else
    subtitleText = tr("panel.no_external")
  end

  local footerText = auto and tr("panel.auto_on") or tr("panel.auto_off")
  if lid ~= "" then
    footerText = footerText .. "  •  " .. lid
  end

  -- Um único destaque forte: o cursor. O modo em vigor só fica contornado,
  -- com um check, pra não parecer uma segunda opção selecionada.
  local buttons = {}
  for i, m in ipairs(MODES) do
    local isCursor = cursor == i
    local isActive = mode == m
    buttons[i] = ui.button({
      text = i .. ". " .. tr("panel." .. m) .. (isActive and "  ✓" or ""),
      glyph = GLYPHS[i],
      contentAlign = "start",
      controlSize = "lg",
      selected = isCursor,
      variant = isCursor and "primary" or (isActive and "outline" or "default"),
      enabled = modeEnabled(m, st),
      onClick = CLICKS[i],
    })
  end

  panel.render(ui.column({ gap = 8, flexGrow = 1 }, {
    ui.row({ align = "center", gap = 8 }, {
      ui.label({ text = tr("panel.title"), fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "close", onClick = "onCloseClicked" }),
    }),
    ui.label({ text = subtitleText, fontSize = 12, color = "on_surface_variant" }),
    ui.column({ gap = 8 }, buttons),
    ui.label({ text = footerText, fontSize = 11, color = "on_surface_variant" }),
  }))
end

function onOpen(_context)
  local stored = noctalia.state.get("cursor")
  if type(stored) == "number" and MODES[stored] then
    cursor = stored
  else
    setCursor(indexOf(status().mode or ""))
  end
  noctalia.state.set("panelOpen", true)
  render()
end

function onClose()
  noctalia.state.set("panelOpen", false)
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
  elseif chord == "4" then
    requestIndex(4)
  end
end

noctalia.state.watch("status", function()
  render()
end)

-- SUPER+P can't be captured here (the host rejects Super chords), so the
-- keybind drives the highlight through the service, which writes "cursor".
noctalia.state.watch("cursor", function(value)
  if type(value) == "number" and MODES[value] then
    cursor = value
    render()
  end
end)
