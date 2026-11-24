# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
[[ -x $HOME/.local/bin/manim ]] || step "uv tool install manim"
