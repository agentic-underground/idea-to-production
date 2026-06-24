# 03 — Packet Capture on the Bridge

> **Purpose:** Verify whether the guest's NIC is actually transmitting packets —
> specifically DHCP requests — using `tcpdump` on the host bridge. Zero DHCP packets
> from the guest means it is either not booted, not configured for DHCP, or the
> virtual NIC is not attached to the bridge.

---

## Why packet capture

`virsh domifaddr` and `ip neigh` tell you what the host knows about the guest. They
say nothing about what the guest is actually sending. Packet capture on the bridge
answers a more fundamental question: **is the guest NIC transmitting anything at all?**

This is the layer-2 check. It comes before layer-3 (IP discovery) because a guest that
never sends DHCP will never get an address, and no discovery tool will find it.

---

## Prerequisites: identify the bridge and the guest MAC

### Find the bridge

```bash
virsh domiflist <vm-name>
```

Output example:

```
 Interface   Type     Source    Model    MAC
--------------------------------------------------------------
 vnet2       bridge   br0       virtio   52:54:00:ab:cd:ef
```

The `Source` column is the bridge name (`br0`, `virbr0`, etc.). The `Interface`
column is the `vnet` device on the host side of the tap.

Confirm the vnet is attached to the bridge:

```bash
ip link show master br0
# Should include vnet2 (or whatever the interface name is)
```

> **GUARDRAIL:** If the `vnet` device is absent from `ip link show master <bridge>`,
> the guest NIC is not connected to the bridge. No traffic will flow regardless of
> guest configuration. This happens when the domain is started before the bridge
> exists, or when the bridge name in the domain XML does not match an existing bridge.

### Get the guest MAC address

```bash
virsh domiflist <vm-name>
# MAC column, e.g. 52:54:00:ab:cd:ef
```

---

## The capture command

```bash
sudo tcpdump -ni <bridge> -e "ether host <mac> and (port 67 or port 68)"
```

- `-n` — no DNS lookups (faster, clearer output)
- `-i <bridge>` — capture on the bridge interface, not a physical NIC
- `-e` — print the Ethernet header (shows the source MAC, confirming it is your guest)
- `ether host <mac>` — filter to only this guest's MAC
- `port 67 or port 68` — DHCP server (67) and client (68) ports

**Example of a healthy DHCP exchange:**

```
12:34:56.789012 52:54:00:ab:cd:ef > ff:ff:ff:ff:ff:ff, ethertype IPv4 (0x0800), length 342:
    0.0.0.0.68 > 255.255.255.255.67: BOOTP/DHCP, Request from 52:54:00:ab:cd:ef, ...
12:34:56.791234 aa:bb:cc:dd:ee:ff > 52:54:00:ab:cd:ef, ethertype IPv4 (0x0800), length 342:
    192.168.1.1.67 > 255.255.255.255.68: BOOTP/DHCP, Reply, ...
```

Two lines: the guest sends a DISCOVER/REQUEST, the DHCP server replies with an OFFER/ACK.

---

## Interpreting the results

### Zero packets after 30 seconds

The guest is not transmitting DHCP. Possible causes, in order of likelihood:

1. **Guest has not booted yet.** Check the serial console (`02`). If the guest is still
   in cloud-init setup (which can take several minutes), wait.
2. **Guest NIC is not attached to the bridge.** Verify with `ip link show master <bridge>`.
3. **Guest is configured with a static IP, not DHCP.** Check `/etc/netplan/` or
   `/etc/network/interfaces` via offline inspection (`01`).
4. **Guest kernel does not have the virtio-net driver.** Unusual for modern distro
   images but possible with minimal kernels.

> **WORKED EXAMPLE:** During the centerpiece incident, the guest was booted but DHCP
> packets were visible on the bridge — the guest had a working NIC and was sending DHCP
> correctly. The DHCP server assigned an address. The problem was upstream of packet
> capture: the guest received its IP but was not discoverable because qemu-guest-agent
> was not installed (cloud-init's apt step failed). Packet capture confirmed the NIC
> was healthy and correctly pointed the investigation toward the agent layer.

### DHCP requests but no replies

The guest is transmitting but the DHCP server is not responding. Possible causes:

- The DHCP server is on a different VLAN and the bridge is not trunked to it
- The bridge is forwarding to an upstream switch that drops broadcasts
- For libvirt NAT networks (`virbr0`): the dnsmasq instance is not running
  (`sudo systemctl status libvirtd`)

### DHCP exchange completes but VM still unreachable

The guest got an IP. The problem is not networking at layer 2/3. Proceed to
[`04-guest-agent-and-ip-discovery.md`](04-guest-agent-and-ip-discovery.md) to find
the address and [`06-symptom-to-cause-ledger.md`](06-symptom-to-cause-ledger.md) for
why it may still be undiscoverable.

---

## Broader traffic capture (when DHCP is not the focus)

To see all traffic from the guest (useful for confirming outbound connectivity or
proxy attempts):

```bash
sudo tcpdump -ni <bridge> -e ether host <mac>
```

To confirm whether the guest is reaching the apt proxy:

```bash
sudo tcpdump -ni <bridge> ether host <mac> and host <proxy-ip> and port <proxy-port>
```

If the guest is running and apt is active, you will see TCP SYN packets to the proxy
address. If those SYNs get no response (SYN retransmits only), the proxy is unreachable
from the guest's perspective.

---

> **ANTI-PATTERN (DO NOT):** Do not capture on a physical NIC or a specific `vnetN`
> interface when you mean to capture all guest traffic. Capture on the **bridge** —
> that is where all connected guests' traffic is visible in one place.

---

Continue to [`04-guest-agent-and-ip-discovery.md`](04-guest-agent-and-ip-discovery.md).
