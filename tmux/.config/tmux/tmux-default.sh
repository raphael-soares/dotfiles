#!/usr/bin/env bash

tmux has-session -t default 2>/dev/null || tmux new-session -d -s default
tmux attach-session -t default
