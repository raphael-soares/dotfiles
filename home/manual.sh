# shellcheck shell=bash  # sourced by .dotter/missing.sh
need_packages
need_flatpaks
# The greeter account is greetd on Fedora and greeter on Arch.
greeter=greeter
[[ $DISTRO == fedora ]] && greeter=greetd
need_file hyprland/greetd/config.toml /etc/greetd/config.toml "" "s/@GREETER@/$greeter/"
# Fedora's own file: rpm leaves a stray copy in place, and the Arch one denies every login.
need_file home/greetd/pam /etc/pam.d/greetd
if [[ $(systemctl is-enabled greetd.service 2>/dev/null) != enabled ]]; then
  step "sudo systemctl enable --force greetd.service"
  note "reboot to log in through greetd"
fi
# The monitor shows the laptop most of the time and then stops answering on DP-1,
# leaving the session without a screen and Sunshine with nothing to stream. The kernel
# replays the LG's own EDID there (amdgpu loads from the initramfs, hence dracut).
# shellcheck disable=SC2154  # lines is missing.sh's list of printed steps
before=${#lines[@]}
need_file home/edid/lg-ultragear.bin /usr/lib/firmware/edid/lg-ultragear.bin
need_file home/dracut/edid.conf /etc/dracut.conf.d/edid.conf
((${#lines[@]} == before)) || step "sudo dracut -f --regenerate-all"
if ! grep -q 'drm.edid_firmware=DP-1' "$CMDLINE"; then
  step 'sudo grubby --update-kernel=ALL --args="drm.edid_firmware=DP-1:edid/lg-ultragear.bin video=DP-1:e"'
  note "reboot for the DP-1 EDID override"
fi
if have tuned-adm && [[ $(tuned-adm active 2>/dev/null) != *throughput-performance ]]; then
  step "sudo tuned-adm profile throughput-performance"
fi
