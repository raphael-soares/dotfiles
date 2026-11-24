# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_flatpaks
need_file hyprland/greetd/config.toml /etc/greetd/config.toml "" "s/@GREETER@/greeter/"
need_file laptop/greetd/pam /etc/pam.d/greetd
