local tr = noctalia.tr

local PLUGIN = "raphael/hypr-shots:menu"

local render
local view = "capture"
local shot = ""
local outputs = {}
local cursor = 1

local function shotDirectory()
  local dir = noctalia.getSetting("shell.screenshot.directory")
  if type(dir) == "string" and dir ~= "" then
    return dir
  end
  return "$HOME/Pictures"
end

local function tempPath()
  return "/tmp/hypr-shots/" .. tostring(noctalia.nowMs()) .. ".png"
end

-- O painel é uma layer: some antes do disparo, senão entra na foto. A captura
-- não salva nem copia nada, só deixa o PNG no /tmp; o destino é a segunda tela.
local function capture(command)
  local path = tempPath()
  panel.close()
  noctalia.runAsync(string.format(
    "sleep 0.25; mkdir -p /tmp/hypr-shots; find /tmp/hypr-shots -type f -mmin +120 -delete; "
      .. "%s && noctalia msg panel-open %s '%s'",
    string.format(command, path),
    PLUGIN,
    path
  ))
end

local function captureRegion()
  capture("g=$(slurp -d) && grim -g \"$g\" '%s'")
end

local function captureWindow()
  capture("hyprshot -s -m window -r > '%s'")
end

local function captureOutput(name)
  capture("grim -o " .. name .. " '%s'")
end

local function deliver(build)
  local path = shot
  panel.close()
  noctalia.runAsync(build(path, shotDirectory()) .. string.format("; rm -f '%s'", path))
end

local function saveCommand(path, dir)
  return string.format("mkdir -p \"%s\" && cp '%s' \"%s/$(date +Screenshot_%%Y%%m%%d_%%H%%M%%S).png\"", dir, path, dir)
end

local function copyCommand(path)
  return string.format("wl-copy --type image/png < '%s'", path)
end

local CAPTURE_ITEMS = {
  { key = "region", glyph = "crop", run = captureRegion },
  { key = "display", glyph = "device-desktop", run = function()
    outputs = noctalia.outputs() or {}
    if #outputs < 2 then
      local only = outputs[1]
      captureOutput(only and only.name or "")
      return
    end
    view = "outputs"
    cursor = 1
    render()
  end },
  { key = "window", glyph = "app-window", run = captureWindow },
}

local DELIVER_ITEMS = {
  { key = "save", glyph = "device-floppy", run = function()
    deliver(function(path, dir) return saveCommand(path, dir) end)
  end },
  { key = "copy", glyph = "clipboard-copy", run = function()
    deliver(function(path) return copyCommand(path) end)
  end },
  { key = "both", glyph = "copy", run = function()
    deliver(function(path, dir) return copyCommand(path) .. " && " .. saveCommand(path, dir) end)
  end },
}

local function items()
  if view == "deliver" then return DELIVER_ITEMS end
  if view == "outputs" then return outputs end
  return CAPTURE_ITEMS
end

local function activate(i)
  local list = items()
  local item = list[i]
  if not item then return end
  if view == "outputs" then
    captureOutput(item.name)
  else
    item.run()
  end
end

local function moveCursor(delta)
  local n = #items()
  if n == 0 then return end
  cursor = ((cursor - 1 + delta) % n) + 1
  render()
end

function onItem1() activate(1) end
function onItem2() activate(2) end
function onItem3() activate(3) end
function onItem4() activate(4) end

function onCloseClicked()
  panel.close()
end

function onBackClicked()
  view = "capture"
  cursor = 1
  render()
end

local CLICKS = { "onItem1", "onItem2", "onItem3", "onItem4" }

render = function()
  local list = items()
  local buttons = {}

  for i, item in ipairs(list) do
    local label
    if view == "outputs" then
      label = item.name .. "  " .. math.floor(item.width or 0) .. "x" .. math.floor(item.height or 0)
    else
      label = tr("panel." .. item.key)
    end
    buttons[i] = ui.button({
      text = label,
      glyph = view == "outputs" and "device-desktop" or item.glyph,
      contentAlign = "start",
      controlSize = "lg",
      selected = cursor == i,
      variant = cursor == i and "primary" or "default",
      onClick = CLICKS[i],
    })
  end

  local title = tr("panel.title")
  if view == "outputs" then
    title = tr("panel.display")
  elseif view == "deliver" then
    title = tr("panel.deliver_title")
  end

  local children = {
    ui.row({ align = "center", gap = 8 }, {
      ui.label({ text = title, fontSize = 16, fontWeight = "bold", color = "primary", flexGrow = 1 }),
      ui.button({ glyph = "close", onClick = "onCloseClicked" }),
    }),
  }

  children[#children + 1] = ui.column({ gap = 8 }, buttons)

  panel.render(ui.column({ gap = 8, flexGrow = 1 }, children))
end

function onOpen(context)
  cursor = 1
  if type(context) == "string" and context ~= "" then
    shot = context
    view = "deliver"
  else
    shot = ""
    view = "capture"
  end
  render()
end

function onKey(chord, pressed)
  if pressed ~= true then return end
  if chord == "Up" then
    moveCursor(-1)
  elseif chord == "Down" then
    moveCursor(1)
  elseif chord == "Left" then
    if view == "outputs" then onBackClicked() end
  elseif chord == "Return" or chord == "KP_Enter" then
    activate(cursor)
  end
end
