# Screenshots with Flameshot

## Why

The `hypr-shots` Noctalia plugin opened its picker before capturing. The panel took
the keyboard, so popups, menus and tooltips that depend on the mouse closed before
the shot, and nothing froze at the moment Print was pressed. The owner liked how
Plasma (Spectacle) handled it: capture at once, then select and draw on the frozen
image.

## Goals

- Print captures immediately, popups included, and shows the frozen image.
- Keep what the plugin did: area, whole monitor, window, annotate, copy, save, both.
- Same on both machines.

## Approaches

- **Spectacle:** asks KWin for the shot through an interface only KWin has; under
  Hyprland it falls back to the generic portal, where region selection is missing.
- **Noctalia's native screenshot:** freezes too and needs no app, but its editing is
  simpler than Flameshot's.
- **Flameshot (chosen by the owner):** captures the monitor at once through the
  portal, then selection, drawing, copy and save happen on the frozen image.

## Design

- `bin/screenshot [window]` runs `flameshot screen --number N --edit` for the focused
  monitor. N is the output's position in Wayland's announcement order, which is how
  Flameshot numbers screens; Hyprland's ids differ after a replug (measured with
  headless outputs). With `window`, `--region` preselects the focused window.
- Print: area or whole monitor (Ctrl+A). ALT+Print: window. Ctrl+C copies and also
  saves (`saveAfterCopy`), Ctrl+S saves, to `~/Pictures/Screenshots`.
- Flameshot's config is a Noctalia template, so its buttons follow the palette.
- The capture window is fullscreen, otherwise the bar stays on top of it.
- Flameshot's daemon starts with the session, without a tray icon.
- The plugin, `slurp`, `hyprshot`, `satty` and nett00n's copr (satty only) go away.
  `grim` stays as Flameshot's dependency on Fedora.

## Left out

- Arch has no removal list, so the old tools stay installed there until removed by hand.
