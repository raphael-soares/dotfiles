local TILE_WIDTH = 96
local TILE_HEIGHT = 100
local DOUBLE_CLICK_MS = 400

local items = {}
local cells = {}
local hovered = ""
local selected = ""
local picked = ""
local arranging = false
local lastClickKey = ""
local lastClickMs = 0
local scannedNames = nil
local scanning = false

local function setting(key, default)
  local value = noctalia.getConfig(key)
  if value == nil then
    return default
  end
  return value
end

local function directory()
  return noctalia.expandPath(setting("directory", "~/Desktop"))
end

local function iconSize()
  return setting("icon_size", 48)
end

local function layoutPath()
  local dir = noctalia.pluginDataDir()
  return dir and dir .. "/layout.tsv" or nil
end

-- One "cell<TAB>name" line per item; cells count down each column, then across.
local function loadLayout()
  local layout = {}
  local path = layoutPath()
  local content = path and noctalia.readFile(path)
  if content then
    for line in content:gmatch("[^\n]+") do
      local cell, name = line:match("^(%d+)\t(.+)$")
      if cell then
        layout[name] = tonumber(cell)
      end
    end
  end
  return layout
end

local function saveLayout()
  local path = layoutPath()
  if not path then
    return
  end
  local lines = {}
  for cell, item in pairs(cells) do
    table.insert(lines, string.format("%d\t%s", cell, item.key))
  end
  table.sort(lines)
  noctalia.writeFile(path, table.concat(lines, "\n") .. "\n")
end

local function resolveIcon(names)
  for _, name in ipairs(names) do
    local path = noctalia.appIconPath(name, iconSize())
    if path then
      return path
    end
  end
  return noctalia.appIconPath("text-x-generic", iconSize())
end

local function parseDesktopEntry(path)
  local content = noctalia.readFile(path)
  if not content then
    return nil
  end
  local lang = noctalia.getSetting("shell.lang")
  local localizedKey = lang and lang ~= "" and string.format("Name[%s]", lang) or nil
  local inEntry = false
  local name, localizedName, icon
  for line in content:gmatch("[^\r\n]+") do
    local section = line:match("^%s*%[(.-)%]%s*$")
    if section then
      if inEntry then
        break
      end
      inEntry = section == "Desktop Entry"
    elseif inEntry then
      local key, value = line:match("^([^=]+)=(.*)$")
      if key == "Name" then
        name = value
      elseif localizedKey and key == localizedKey then
        localizedName = value
      elseif key == "Icon" then
        icon = value
      end
    end
  end
  return { name = localizedName or name, icon = icon }
end

local function byKind(a, b)
  if a.isDir ~= b.isDir then
    return a.isDir
  end
  return a.label:lower() < b.label:lower()
end

-- gio knows the themed icon of every type and the thumbnail Nautilus already made;
-- one call per scan answers for all non-launcher files at once.
local function fillFileIcons(files, done)
  if #files == 0 then
    done()
    return
  end
  local argv = { "gio", "info", "-a", "standard::icon,thumbnail::path" }
  local byPath = {}
  for _, item in ipairs(files) do
    table.insert(argv, item.path)
    byPath[item.path] = item
  end
  noctalia.runAsync(argv, function(result)
    local current = nil
    for line in result.stdout:gmatch("[^\n]+") do
      local path = line:match("^local path: (.+)$")
      if path then
        current = byPath[path]
      elseif current then
        local icons = line:match("^%s+standard::icon: (.+)$")
        local thumb = line:match("^%s+thumbnail::path: (.+)$")
        if icons then
          local names = {}
          for name in icons:gmatch("[^,%s]+") do
            table.insert(names, name)
          end
          current.icon = resolveIcon(names)
        elseif thumb then
          current.thumbnail = thumb
        end
      end
    end
    done()
  end)
end

local function cellCount()
  local rows = setting("rows", 8)
  local count = rows * setting("columns", 6)
  if #items > count then
    count = math.ceil(#items / rows) * rows
  end
  return count
end

local function placeItems()
  local layout = loadLayout()
  local total = cellCount()
  cells = {}
  local unplaced = {}
  for _, item in ipairs(items) do
    local cell = layout[item.key]
    if cell and cell <= total and not cells[cell] then
      cells[cell] = item
    else
      table.insert(unplaced, item)
    end
  end
  local cell = 1
  for _, item in ipairs(unplaced) do
    while cells[cell] do
      cell += 1
    end
    cells[cell] = item
  end
  if #unplaced > 0 then
    saveLayout()
  end
end

local render

local function visibleNames()
  local names = {}
  for _, name in ipairs(noctalia.listDir(directory()) or {}) do
    if name:sub(1, 1) ~= "." then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return names
end

local function scan(names, signature)
  scanning = true
  local dir = directory()
  local found = {}
  local files = {}
  for _, name in ipairs(names) do
    local path = dir .. "/" .. name
    local info = noctalia.fileInfo(path)
    if info then
      local item = { key = name, path = path, isDir = info.isDir, label = name }
      if not info.isDir and name:match("%.desktop$") then
        local entry = parseDesktopEntry(path)
        item.launcher = true
        if entry then
          item.label = entry.name or name
          item.icon = resolveIcon({ entry.icon or "", "application-x-executable" })
        end
      else
        table.insert(files, item)
      end
      table.insert(found, item)
    end
  end
  table.sort(found, byKind)
  fillFileIcons(files, function()
    items = found
    placeItems()
    scannedNames = signature
    scanning = false
    render()
  end)
end

local function open(item)
  if item.launcher then
    noctalia.runAsync({ "gio", "launch", item.path })
  else
    noctalia.openPath(item.path)
  end
end

local function cellOf(key)
  for cell, item in pairs(cells) do
    if item.key == key then
      return cell
    end
  end
  return nil
end

-- Desktop widgets get no drag events, so arranging is two clicks: pick an item, then
-- click the cell it goes to. An occupied target swaps the two.
local function dropOn(cell)
  local from = cellOf(picked)
  if from and from ~= cell then
    cells[from], cells[cell] = cells[cell], cells[from]
    saveLayout()
  end
  picked = ""
end

-- Noctalia reports single clicks only: the first click selects, a second one on the
-- same item within DOUBLE_CLICK_MS opens it.
local function clickItem(item, cell)
  if arranging then
    if picked == "" then
      picked = item.key
    elseif picked == item.key then
      picked = ""
    else
      dropOn(cell)
    end
    render()
    return
  end
  local now = noctalia.nowMs()
  if lastClickKey == item.key and now - lastClickMs <= DOUBLE_CLICK_MS then
    lastClickKey = ""
    open(item)
  else
    lastClickKey = item.key
    lastClickMs = now
  end
  selected = item.key
  render()
end

local function setHover(key, state)
  if state == "true" then
    hovered = key
  elseif hovered == key then
    hovered = ""
  end
  render()
end

local function tileFill(key)
  if picked == key or (not arranging and selected == key) then
    return "primary/0.35"
  elseif hovered == key then
    return "on_surface/0.12"
  end
  return nil
end

local function itemTile(item, cell)
  local size = iconSize()
  return ui.column({
    key = "item:" .. item.key,
    width = TILE_WIDTH,
    minWidth = TILE_WIDTH,
    minHeight = TILE_HEIGHT,
    padding = 6,
    gap = 4,
    radius = 10,
    align = "center",
    fill = tileFill(item.key),
    border = arranging and "on_surface/0.25" or nil,
    borderWidth = arranging and 1 or 0,
    onClick = function() clickItem(item, cell) end,
    onHover = function(state) setHover(item.key, state) end,
  }, {
    ui.image({
      path = item.thumbnail or item.icon or "",
      width = size,
      height = size,
      fit = "contain",
      radius = item.thumbnail and 4 or 0,
    }),
    ui.label({
      text = item.label,
      fontSize = 12,
      color = "#ffffff",
      shadow = true,
      maxWidth = TILE_WIDTH - 8,
      maxLines = 2,
      textAlign = "center",
    }),
  })
end

local function emptyTile(cell)
  local key = "cell:" .. cell
  local target = arranging and picked ~= ""
  return ui.column({
    key = key,
    width = TILE_WIDTH,
    minWidth = TILE_WIDTH,
    minHeight = TILE_HEIGHT,
    radius = 10,
    fill = target and hovered == key and "primary/0.2" or nil,
    border = target and "on_surface/0.15" or nil,
    borderWidth = target and 1 or 0,
    onClick = target and function()
      dropOn(cell)
      render()
    end or nil,
    onHover = target and function(state) setHover(key, state) end or nil,
  }, {})
end

local function toggleArranging()
  arranging = not arranging
  picked = ""
  render()
end

render = function()
  local rows = setting("rows", 8)
  local columns = {}
  local column = {}
  for cell = 1, cellCount() do
    local item = cells[cell]
    table.insert(column, item and itemTile(item, cell) or emptyTile(cell))
    if #column == rows then
      table.insert(columns, ui.column({ gap = 4, align = "start" }, column))
      column = {}
    end
  end
  desktopWidget.render(ui.column({ gap = 4, align = "start" }, {
    ui.row({ gap = 4, align = "start" }, columns),
    ui.button({
      glyph = arranging and "check" or "layout-grid",
      variant = arranging and "primary" or "ghost",
      controlSize = "sm",
      onClick = toggleArranging,
    }),
  }))
end

function update()
  if scanning then
    return
  end
  local names = visibleNames()
  local signature = table.concat(names, "\n")
  if signature ~= scannedNames then
    scan(names, signature)
  end
end

function onConfigChanged()
  scannedNames = nil
  update()
end

noctalia.setUpdateInterval(2000)
