--!nonstrict

local tr = noctalia.tr
local DIR = noctalia.getenv("XDG_RUNTIME_DIR") .. "/remote/"

local function side(): string
	if noctalia.fileExists(DIR .. "serving") then
		return "serving"
	elseif noctalia.fileExists(DIR .. "viewing") then
		return "viewing"
	end
	return "idle"
end

local function peer(): string
	local name = noctalia.readFile(DIR .. "peer")
	return type(name) == "string" and noctalia.string.trim(name) or "?"
end

local function text(key: string): string
	return (string.gsub(tr(key), "{peer}", peer()))
end

local function run(action: string)
	panel.close()
	noctalia.runAsync({ "remote-control", action }, function(result)
		if not result or result.exitCode ~= 0 then
			local detail = result and noctalia.string.trim((result.stderr or "") .. (result.stdout or "")) or ""
			noctalia.notifyError(tr("notify.title"), detail)
		end
	end, 20000)
end

function onShowClicked()
	run("show")
end

function onSwapClicked()
	run("swap")
end

function onStopClicked()
	run("stop")
end

function onCloseClicked()
	panel.close()
end

local shown = ""

local function render()
	local s = side()
	shown = s
	local buttons = {}
	if s == "viewing" then
		table.insert(buttons, ui.button({ text = text("panel.show"), glyph = "eye", contentAlign = "start", controlSize = "lg", onClick = "onShowClicked" }))
		table.insert(buttons, ui.button({ text = text("panel.swap_to_serving"), glyph = "arrows-exchange", contentAlign = "start", controlSize = "lg", onClick = "onSwapClicked" }))
		table.insert(buttons, ui.button({ text = text("panel.stop_viewing"), glyph = "plug-connected-x", contentAlign = "start", controlSize = "lg", variant = "destructive", onClick = "onStopClicked" }))
	elseif s == "serving" then
		table.insert(buttons, ui.button({ text = text("panel.swap_to_viewing"), glyph = "arrows-exchange", contentAlign = "start", controlSize = "lg", onClick = "onSwapClicked" }))
		table.insert(buttons, ui.button({ text = text("panel.stop_serving"), glyph = "plug-connected-x", contentAlign = "start", controlSize = "lg", variant = "destructive", onClick = "onStopClicked" }))
	end
	panel.render(ui.column({ gap = 8, flexGrow = 1 }, {
		ui.row({ align = "center", gap = 8 }, {
			ui.label({ text = text("panel." .. s), fontSize = 14, fontWeight = "bold", color = "primary", flexGrow = 1 }),
			ui.button({ glyph = "close", onClick = "onCloseClicked" }),
		}),
		ui.column({ gap = 8 }, buttons),
	}))
end

function onOpen(_context)
	panel.setWantsSecondTicks(true)
	render()
end

function update()
	if side() ~= shown then
		render()
	end
end
