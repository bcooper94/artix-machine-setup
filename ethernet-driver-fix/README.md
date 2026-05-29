# Fixing RTL8125 2.5GbE Ethernet on Artix Linux

The RTL8125 2.5GbE controller (common on modern motherboards) is incorrectly
driven by the generic `r8169` kernel module on Artix. The `r8169` driver only
receives packets when in promiscuous mode, meaning normal network traffic is
silently dropped. The fix is to install Realtek's dedicated `r8125` driver and
blacklist `r8169`.

## Symptoms

- Ethernet interface is up and has an IP address but no connectivity
- `dmesg` shows `r8169` driving the device:
  ```
  r8169 0000:08:00.0 eth0: Link is Up - 2.5Gbps/Full
  ```
- ARP requests go out on `eth0` but no replies are received
- Packet captures only show traffic when promiscuous mode is active (e.g. during `tcpdump`)
- DHCP discovers are sent but no offer is received

## Affected Hardware

Realtek RTL8125 / RTL8125B / RTL8125BG 2.5GbE controllers, commonly found
integrated on motherboards from ASUS, ASRock, MSI, and Gigabyte. Confirm with:

```bash
lspci | grep Ethernet
# Should show: Realtek Semiconductor Co., Ltd. RTL8125 2.5GbE Controller
```

## Fix

**1. Install dependencies:**
```bash
sudo pacman -S linux-headers dkms
```

**2. Install the r8125 driver from the AUR:**
```bash
yay -S r8125-dkms
# or:
paru -S r8125-dkms
```

**3. Blacklist the r8169 module:**
```bash
echo "blacklist r8169" | sudo tee /etc/modprobe.d/r8169-blacklist.conf
```

**4. Rebuild initramfs:**
```bash
sudo mkinitcpio -P
```

**5. Reboot.**

**6. Verify the correct driver is loaded:**
```bash
lspci -k | grep -A 3 "RTL8125"
# Should show:
#   Kernel driver in use: r8125
```

## Additional Notes

- If both `wlan0` and `eth0` are on the same subnet, add the following to
  `/etc/sysctl.d/99-arp.conf` to prevent interfaces from answering ARP
  requests on each other's behalf:
  ```
  net.ipv4.conf.all.arp_ignore=1
  net.ipv4.conf.all.arp_announce=2
  ```

- If a static IP from a previous configuration keeps reasserting itself on
  `eth0`, check NetworkManager profiles:
  ```bash
  nmcli con show
  nmcli con mod "Wired connection 1" ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns ""
  nmcli con up "Wired connection 1"
  ```
