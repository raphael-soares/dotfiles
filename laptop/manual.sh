# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_flatpaks
# The greeter account is greetd on Fedora and greeter on Arch.
greeter=greeter
[[ $DISTRO == fedora ]] && greeter=greetd
need_file hyprland/greetd/config.toml /etc/greetd/config.toml "" "s/@GREETER@/$greeter/"
need_file laptop/greetd/pam /etc/pam.d/greetd
