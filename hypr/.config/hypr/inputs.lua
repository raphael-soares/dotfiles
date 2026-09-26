hl.config({
  input = {
    kb_layout = "us,br",
    kb_variant = "",
    kb_model = "",
    kb_options = "caps:swapescape,grp:win_space_toggle",
    kb_rules = "",

    follow_mouse = 1,

    sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})
