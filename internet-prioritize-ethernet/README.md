# Prioritizing Ethernet Over WiFi on Artix Linux

By default, NetworkManager may assign a lower route metric to WiFi than
Ethernet, causing internet traffic to prefer WiFi even when Ethernet is
connected. This guide sets Ethernet as the preferred interface while keeping
WiFi as an automatic fallback.

## Confirm the Problem

Check your current default routes:

```bash
ip route | grep default
```

If `dev wlan0` has a lower metric than `dev eth0`, WiFi is being preferred:

```
default via 192.168.0.1 dev wlan0 metric 600   # lower = preferred
default via 192.168.0.1 dev eth0  metric 1002  # higher = deprioritized
```

## Fix — Assign a Static IP to Ethernet

Using a static IP is the most reliable approach, as it avoids DHCP metric
conflicts and ensures a single clean default route for Ethernet.

**1. Find your current Ethernet connection name:**
```bash
nmcli con show | grep ethernet
```

**2. Set a static IP with a lower metric than WiFi:**
```bash
nmcli con mod "Wired connection 1" \
  ipv4.method manual \
  ipv4.addresses "192.168.0.147/24" \
  ipv4.gateway "192.168.0.1" \
  ipv4.dns "192.168.0.1" \
  ipv4.route-metric 100
nmcli con down "Wired connection 1" && nmcli con up "Wired connection 1"
```

Replace `192.168.0.147` with your desired IP. Use any metric below your
WiFi's metric (typically 600) — 100 is a safe choice.

**3. Reserve the static IP on your router** to prevent other devices from
being assigned the same address (look for DHCP Reservation or Address
Binding in your router's admin page).

## Verify

```bash
ip route | grep default
```

Ethernet should now appear first with the lower metric:

```
default via 192.168.0.1 dev eth0  metric 100  # preferred
default via 192.168.0.1 dev wlan0 metric 600  # fallback
```

Confirm internet traffic uses Ethernet:

```bash
ip route get 8.8.8.8
# Should show: 8.8.8.8 via 192.168.0.1 dev eth0 src 192.168.0.147
```

## Notes

- WiFi remains active as an automatic fallback if Ethernet goes down.
- If you later connect the Ethernet port to a different subnet (e.g. a NAS
  on 192.168.50.x), remember to update the static config or temporarily
  switch back to DHCP:
  ```bash
  nmcli con mod "Wired connection 1" ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns ""
  nmcli con up "Wired connection 1"
  ```
- To prevent WiFi from answering ARP requests on behalf of Ethernet (and
  vice versa) when both interfaces share the same subnet, add to
  `/etc/sysctl.d/99-arp.conf`:
  ```
  net.ipv4.conf.all.arp_ignore=1
  net.ipv4.conf.all.arp_announce=2
  ```
