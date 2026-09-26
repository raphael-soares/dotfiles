require("animations")
require("autostart")
require("look")
require("inputs")
require("keymaps")
require("monitors")
require("windowrules")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-- For Noctalia Color templates
require("noctalia").apply_theme()
require("borders")
