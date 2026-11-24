--!nonstrict

-- State files written by hypr/remote.lua (viewing, peer) and bin/remote-serving (serving).
local DIR = noctalia.getenv("XDG_RUNTIME_DIR") .. "/remote/"

local function peer(): string
	local name = noctalia.readFile(DIR .. "peer")
	return type(name) == "string" and noctalia.string.trim(name) or "?"
end

local function update_widget()
	local serving = noctalia.fileExists(DIR .. "serving")
	local viewing = noctalia.fileExists(DIR .. "viewing")
	if serving or viewing then
		local key = serving and "tooltip.serving" or "tooltip.viewing"
		barWidget.setGlyph(serving and "sun" or "moon")
		barWidget.setTooltip((string.gsub(noctalia.tr(key), "{peer}", peer())))
	end
	barWidget.setVisible(serving or viewing)
end

update_widget()

function update()
	noctalia.setUpdateInterval(1000)
	update_widget()
end

function onClick()
	noctalia.togglePanel("raphael/hypr-remote:control")
end
