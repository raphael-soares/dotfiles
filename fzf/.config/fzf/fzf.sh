#!/usr/bin/env bash
# Cores so por indice ANSI (0-15, -1 = padrao do terminal): seguem o tema do alacritty.

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
