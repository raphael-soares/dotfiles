# Remote toggle: fast switch while streaming

## Why

`SUPER + grave` probes the desktop over the network on every press, even when
Moonlight is already streaming. With the stream open, Sunshine is slow to
accept a new connection on 47989: in 15 probes over Wi-Fi, 13 answered in 40
to 584 ms and 2 hit the 1 s timeout (ping averaged 15 ms). About one switch in
seven shows a false "Desktop is off", and every successful switch waits on the
network and flashes "Checking if the desktop is on...".

## Goals

- Switching to the desktop while Moonlight is open is immediate, with no
  notification and no false error, however often the owner alternates.
- Opening the stream from scratch keeps telling "off" apart from "on but not
  streaming".

Non-goal: the IPv6-first resolution of `fedora.local`, notification styling.

## Approaches

| Approach | Trade-off |
|---|---|
| Skip the probe when a Moonlight window exists (picked) | The stream window existing proves the link; a dropped stream closes the window, which `window_close` already handles |
| Only raise the probe timeout | Fewer false errors, but every switch still waits on the network and notifies |
| Drop the probe, let Moonlight fail | Moonlight's error screen is worse and "off" vs "no monitor" is lost |

## Design

- `remote_state.lua`: `M.toggle(state, current_ws, stream_alive)`. Outside the
  stream workspace with `stream_alive`: remember the origin and return go to
  the stream workspace, focus Moonlight, enter the `remote` submap. Without
  it: probe as before.
- `remote.lua`: the toggle passes `stream_running()`. The probe keeps its
  `pgrep`, which covers a Moonlight launched a moment ago with no window yet.
- Probe timeout per port goes from 1 s to 2 s (my call): worst case 4 s, under
  the existing 5 s safety timer. All measured failures happened while
  streaming, which no longer probes.
- `tests/remote_state.lua` covers the direct switch; `docs/remote-desktop.md`
  notes that the switch is immediate while streaming.
