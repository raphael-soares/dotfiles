--!nonstrict

-- State files written by hypr/remote.lua (viewing) and bin/remote-serving (serving).
local STATE_DIR = noctalia.getenv("XDG_RUNTIME_DIR") .. "/remote/"

local function update_widget()
	local serving = noctalia.fileExists(STATE_DIR .. "serving")
	local viewing = noctalia.fileExists(STATE_DIR .. "viewing")
	if serving then
		barWidget.setGlyph("sun")
		barWidget.setTooltip("The other machine is watching this screen")
	elseif viewing then
		barWidget.setGlyph("moon")
		barWidget.setTooltip("Showing the other machine")
	end
	barWidget.setVisible(serving or viewing)
end

update_widget()

function update()
	noctalia.setUpdateInterval(1000)
	update_widget()
end
