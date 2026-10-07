hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,

    snap = {
      enabled = true,
    },
  },

  decoration = {
    rounding = 12,
    rounding_power = 2.5,

    dim_inactive = true,
    dim_strength = 0.08,
    dim_special = 0.3,

    shadow = {
      enabled = true,
      range = 28,
      render_power = 4,
      offset = { 0, 6 },
      color = "0x59000000",
      color_inactive = "0x33000000",
    },

    blur = { enabled = false },
  },

  misc = {
    disable_splash_rendering = true,
    disable_hyprland_logo = true,
    focus_on_activate = true,
    anr_missed_pings = 3,
    middle_click_paste = false,
    -- Noctalia é o lockscreen; se ele cair bloqueado, reiniciá-lo recupera a sessão.
    allow_session_lock_restore = true,
  },

  cursor = {
    warp_on_change_workspace = 1,
    hide_on_key_press = true,
  },

  binds = {
    hide_special_on_workspace_change = true,
  },

  ecosystem = {
    no_update_news = true,
  },
})

hl.config({
  dwindle = {
    preserve_split = true,
    force_split = 2,
  },
})
