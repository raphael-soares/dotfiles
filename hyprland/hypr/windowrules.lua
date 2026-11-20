hl.window_rule({
  name = "all-windows",
  match = { class = ".*" },
  suppress_event = "maximize",
  idle_inhibit = "fullscreen",
})

hl.window_rule({
  -- With follow_mouse, JetBrains popups and autocomplete close when the mouse moves outside.
  name = "jetbrains-no-follow-mouse",
  match = { class = "^(jetbrains-.*)$" },
  no_follow_mouse = true,
})

hl.window_rule({
  -- The portal only opens dialogs: file picker, screen sharing, permissions.
  name = "portal-dialogs",
  match = { class = "^(xdg-desktop-portal-gtk)$" },
  float = true,
  center = true,
  size = { 900, 600 },
})

hl.window_rule({
  -- The "someone is sharing your screen" bar from Chromium/Meet/Zoom.
  name = "hide-sharing-indicator",
  match = { title = ".*is sharing (your screen|a window).*" },
  workspace = "special silent",
})

hl.window_rule({
  match = { class = "dev.noctalia.Noctalia" },
  float = true,
  size = { 1080, 920 },
})

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },

  no_focus = true,
})

hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },

  move = "20 monitor_h-120",
  float = true,
})

hl.window_rule({
  name = "pip-float",
  match = { title = "(Picture.?in.?[Pp]icture)" },
  float = true,
  pin = true,
  size = { 600, 338 },
  keep_aspect_ratio = true,
  border_size = 0,
  opacity = "1 1",
  move = "monitor_w-window_w-40 monitor_h*0.04",
})

hl.window_rule({
  name = "spotify-workspace",
  match = { class = "^spotifast$" },
  workspace = "9 silent",
})

hl.layer_rule({
  -- Noctalia animates its own panels; Hyprland's fade on top doubled the effect.
  name = "shell-motion",
  match = { namespace = "^noctalia-" },
  no_anim = true,
})

hl.layer_rule({
  -- Notification and OSD show only for you, never in screen sharing.
  name = "shell-private",
  match = { namespace = "^noctalia-(notification|osd)" },
  no_screen_share = true,
})

hl.window_rule({
  name = "utility-float",
  match = { class = "^(org\\.gnome\\.Calculator|org\\.pulseaudio\\.pavucontrol)$" },
  float = true,
  center = true,
})

hl.window_rule({
  name = "pavucontrol-size",
  match = { class = "^org\\.pulseaudio\\.pavucontrol$" },
  size = { 900, 600 },
})
