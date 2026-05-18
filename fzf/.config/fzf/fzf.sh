#!/usr/bin/env bash
# Shared fzf base config — source from .bashrc, scripts, etc.
# Colors: pure ANSI palette (0-15, -1=terminal default) — theme-agnostic.
#   -1 = terminal default   0-7 = normal ANSI   8-15 = bright ANSI
#   accent: 5/13 (magenta/purple), matches tmux colour5

export FZF_BASE_OPTS=$'
  --pointer=""
  --prompt="SEARCH: "
  --marker=""
  --separator=""
  --scrollbar=""
  --layout=reverse
  --border=sharp
  --padding=1
  --info=hidden
  --tmux center,40%,50%
  --bind=tab:down,shift-tab:up
  --color=hl:2:bold,hl+:10:bold
  --color=info:8,prompt:2:bold,pointer:2
  '
