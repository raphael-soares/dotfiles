hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
  },

  decoration = {
    rounding = 1,
    rounding_power = 3,

    shadow = {
      enabled = true,
      range = 28,
      render_power = 4,
      offset = { 0, 6 },
      color = "0x59000000",
      color_inactive = "0x33000000",
    },

    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      new_optimizations = true,
      noise = 0.02,
      contrast = 1,
      brightness = 0.9,
      vibrancy = 0.1696,
      popups = true,
    },
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },

  cursor = {
    warp_on_change_workspace = 1,
  },

  binds = {
    hide_special_on_workspace_change = true,
  },
})

hl.config({
  dwindle = {
    preserve_split = true,
    force_split = 2,
  },
})
