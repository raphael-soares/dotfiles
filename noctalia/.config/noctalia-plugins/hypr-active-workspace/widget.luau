--!nonstrict

local FORMAT: string = noctalia.getConfig("format") or "Workspace {name}"
local SHOW_GLYPH: boolean = noctalia.getConfig("show_glyph") == true
local GLYPH: string = noctalia.getConfig("glyph") or "layout-grid"

local RESYNC_MS = 60000
local SCROLL_COOLDOWN_MS = 150

local REFRESH_EVENTS = {
	workspace = true,
	workspacev2 = true,
	focusedmon = true,
	focusedmonv2 = true,
	moveworkspace = true,
	moveworkspacev2 = true,
	renameworkspace = true,
	monitoradded = true,
	monitoraddedv2 = true,
	monitorremoved = true,
	monitorremovedv2 = true,
	configreloaded = true,
}

local inFlight = false
local pending = false
local lastScrollMs = 0

local function shellQuote(str: string): string
	return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function outputName(): string?
	if barWidget.outputName == nil then
		return nil
	end
	local ok, name = pcall(barWidget.outputName)
	if ok and name ~= nil and name ~= "" then
		return name
	end
	return nil
end

local function pickMonitor(monitors: { any }): any
	local connector = outputName()
	if connector ~= nil then
		for _, m in ipairs(monitors) do
			if m.name == connector then
				return m
			end
		end
	end
	for _, m in ipairs(monitors) do
		if m.focused == true then
			return m
		end
	end
	return monitors[1]
end

local function render(ws: any)
	local id = tostring(ws.id)
	local name = (type(ws.name) == "string" and ws.name ~= "") and ws.name or id
	local text = string.gsub(FORMAT, "{(%a+)}", function(key)
		if key == "name" then
			return name
		elseif key == "id" then
			return id
		end
		return nil
	end)
	barWidget.setText(text)
	if SHOW_GLYPH then
		barWidget.setGlyph(GLYPH)
	end
end

local function refresh()
	if inFlight then
		pending = true
		return
	end
	inFlight = true

	local started = noctalia.runAsync("hyprctl -j monitors", function(res)
		inFlight = false
		if res.exitCode == 0 then
			local monitors = noctalia.json.decode(res.stdout)
			if type(monitors) == "table" then
				local m = pickMonitor(monitors)
				if m ~= nil and type(m.activeWorkspace) == "table" then
					render(m.activeWorkspace)
				end
			end
		end
		if pending then
			pending = false
			refresh()
		end
	end, 3000)

	if not started then
		inFlight = false
	end
end

local function startEventStream()
	if not noctalia.commandExists("socat") then
		return
	end
	local runtimeDir = noctalia.getenv("XDG_RUNTIME_DIR")
	local signature = noctalia.getenv("HYPRLAND_INSTANCE_SIGNATURE")
	if not runtimeDir or not signature then
		return
	end

	local socket = shellQuote(runtimeDir .. "/hypr/" .. signature .. "/.socket2.sock")
	local command = "while true; do while [ ! -S "
		.. socket
		.. " ]; do sleep 5; done; socat -u UNIX-CONNECT:"
		.. socket
		.. " - 2>&1; sleep 5; done"

	noctalia.runStream(command, function(line: string)
		local event = string.match(line, "^([%a%d_]+)>>")
		if event and REFRESH_EVENTS[event] then
			refresh()
		end
	end)
end

refresh()
startEventStream()

function update()
	noctalia.setUpdateInterval(RESYNC_MS)
	refresh()
end

function onScroll(axis: string, steps: number, startsGesture: boolean)
	if steps == 0 then
		return
	end
	local now = noctalia.nowMs()
	if now - lastScrollMs < SCROLL_COOLDOWN_MS then
		return
	end
	lastScrollMs = now
	local target = (steps > 0) and "e+1" or "e-1"
	noctalia.runAsync("hyprctl dispatch 'hl.dsp.focus({ workspace = \"" .. target .. "\" })'")
end
