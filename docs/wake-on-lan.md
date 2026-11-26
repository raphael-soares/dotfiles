# Wake on LAN

The desktop (`fedora`) never powers off: it suspends, and any device on the home
network wakes it with a magic packet over wifi. The MediaTek MT7922 card only
listens while suspended; from a real power-off, or after a power cut, the PC
comes back only through the power button.

What the `home` module sets:

- `home/networkmanager/wake-on-wlan.conf`: NetworkManager turns on
  wake-on-magic-packet for every wifi connection.
- `home/logind/power-key.conf`: the case's power button suspends.
- `home/noctalia/machine.toml`: the session menu offers suspend instead of
  shutdown, and so does the lock screen's power button.

Both `/etc` files are copied by hand; `.dotter/missing.sh` prints the commands.
Powering off on purpose is still `systemctl poweroff`.

## Waking it

Send the packet to the network's broadcast address, not to `192.168.1.250`:
while the PC sleeps, the router may forget which MAC holds that IP.

```bash
wakeonlan -i 192.168.1.255 b2:77:47:45:ac:b1
```

The MAC is the one NetworkManager generates for the home SSID
(`wifi.cloned-mac-address=stable-ssid`, Fedora's default), not the card's
burnt-in `90:74:ae:34:e8:32`. Check it with `ip link show wlp7s0`; it changes
if the SSID does.

`iw phy phy0 wowlan show` must list `magic-packet`.
