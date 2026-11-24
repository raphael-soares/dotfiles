need_packages
# Without an authorized key sshd would take passwords on any network the laptop joins.
if [[ -s $HOME/.ssh/authorized_keys ]]; then
  need_file sshd/50-key-only.conf /etc/ssh/sshd_config.d/50-key-only.conf "sudo systemctl reload sshd"
  need_enabled sshd avahi-daemon
else
  note "add ~/.ssh/keys/personal.pub to ~/.ssh/authorized_keys, then run this again"
  need_enabled avahi-daemon
fi
need_firewall --add-service=ssh --add-service=mdns
