#!/usr/bin/env bash
# Colors by ANSI index only (0-15, -1 = terminal default): they follow the terminal theme.

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
