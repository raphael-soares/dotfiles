local M = {}
M.terminal = "if tmux list-clients 2>/dev/null | grep -q .; then exec kitty; else exec kitty ~/.config/tmux/tmux-default.sh; fi"
return M
