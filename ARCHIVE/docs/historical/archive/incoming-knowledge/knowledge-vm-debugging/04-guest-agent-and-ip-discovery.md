# 04 — Guest Agent and IP Discovery

> **Purpose:** Understand why `virsh domifaddr` fails on bridged VMs, and what
> alternative discovery mechanisms exist when the guest agent is not available.

Reference: [virsh domifaddr](https://www.libvirt.org/manpages/virsh.html#domifaddr)

---

## The key fact

> **IMPORTANT — THE ONLY WAY:** `virsh domifaddr --source lease` queries the
> **libvirt-managed dnsmasq** DHCP lease table. This only works for guests on a
> **libvirt NAT network** (`virbr0`). A **bridged VM** leases from the **LAN DHCP
> server** — libvirt has no visibility into those leases. `--source lease` will return
> nothing for a bridged guest, regardless of whether it has an IP.

This is the most common reason `virsh domifaddr` appears to fail: the operator runs
the default command (which uses the `lease` source), sees no output, and concludes the
guest has no IP. The guest may have had an IP for hours.

---

## The three sources explained

```bash
virsh domifaddr <vm-name> --source lease    # default: libvirt dnsmasq only
virsh domifaddr <vm-name> --source agent    # queries qemu-guest-agent inside guest
virsh domifaddr <vm-name> --source arp      # queries the host ARP cache
```

| Source | What it queries | Works for bridged VMs? | Requires |
|--------|----------------|------------------------|----------|
| `lease` | libvirt's internal dnsmasq | **No** — only for NAT networks | Nothing extra |
| `agent` | qemu-guest-agent inside the guest | **Yes** | `qemu-guest-agent` installed and running in guest |
| `arp` | Host kernel ARP cache | **Yes, if guest communicated recently** | Guest has sent any IP packet |

---

## Using `--source agent`

```bash
virsh domifaddr <vm-name> --source agent
```

Returns all interfaces the guest reports, including their IP addresses. This is the
authoritative answer — it comes from inside the guest.

> **GUARDRAIL:** `--source agent` requires `qemu-guest-agent` to be installed and
> running **inside the guest**. If cloud-init failed to install it (e.g. because the
> apt proxy was unreachable), this command returns an error:
> `error: Guest agent is not responding: QEMU guest agent is not connected`.
> That error is itself diagnostic — it confirms the agent is missing.

To check whether the agent channel exists in the domain definition:

```bash
virsh dumpxml <vm-name> | grep -A3 'channel'
```

A properly configured guest agent channel shows:

```xml
<channel type='unix'>
  <target type='virtio' name='org.qemu.guest_agent.0'/>
</channel>
```

If this is absent from the domain XML, add it and restart the guest.

---

## Using `--source arp`

```bash
virsh domifaddr <vm-name> --source arp
```

Queries the host kernel's ARP cache for entries matching the guest's MAC address.

**Limitations:**
- The guest must have sent at least one IP packet to the host (or to something on the
  same broadcast domain) recently.
- ARP entries expire (typically 60–300 seconds of inactivity). A guest that booted,
  sent one DHCP exchange, and then went quiet may have an expired ARP entry.

---

## Direct ARP table query

When `virsh domifaddr` is unavailable or returns nothing, query the ARP table directly:

```bash
ip neigh show | grep <mac-address>
```

Example:

```bash
ip neigh show | grep "52:54:00:ab:cd:ef"
# 192.168.1.47 dev br0 lladdr 52:54:00:ab:cd:ef REACHABLE
```

The IP address precedes the `dev` keyword. `REACHABLE` means the entry is fresh.
`STALE` means it has not been confirmed recently but may still be valid.

Force an ARP refresh by sending traffic toward the expected subnet:

```bash
arping -c 3 -I <bridge> <suspected-ip>
# or, if you know the subnet:
nmap -sn 192.168.1.0/24 --exclude 192.168.1.1  # ping sweep to populate ARP cache
```

---

## mDNS / `.local` discovery

If `avahi-daemon` is installed and running inside the guest, the guest publishes its
hostname via mDNS. Resolve it with:

```bash
avahi-resolve -n <hostname>.local
# or
resolvectl query <hostname>.local
```

> **GUARDRAIL:** mDNS requires `avahi-daemon` to be installed in the guest. If
> cloud-init's apt step failed, `avahi-daemon` was not installed, and `.local`
> resolution will not work — the same root cause that breaks `--source agent`.

---

## Decision matrix: which discovery method to try

```
Is this a NAT (virbr0) or bridged (br0/custom) network?
│
├── NAT → virsh domifaddr --source lease  (usually works)
│
└── Bridged →
    ├── Try: virsh domifaddr --source agent
    │   ├── Returns IP → done
    │   └── Error "agent not connected" → agent not installed; try next
    ├── Try: virsh domifaddr --source arp
    │   ├── Returns IP → done
    │   └── Returns nothing → ARP cache expired; try next
    ├── Try: ip neigh show | grep <mac>
    │   ├── Returns IP → done
    │   └── Returns nothing → guest may not have communicated recently
    └── Try: packet capture (03) to confirm DHCP exchange happened
        ├── DHCP seen → IP was assigned; check DHCP server leases directly
        └── No DHCP → guest not transmitting; check boot state (02)
```

---

## Checking the DHCP server's lease table directly

If you control the DHCP server (e.g. a router or a dnsmasq instance):

```bash
# dnsmasq lease file (common location):
cat /var/lib/misc/dnsmasq.leases
# or
grep <mac> /var/lib/misc/dnsmasq.leases
```

The lease file contains: expiry timestamp, MAC, IP, hostname, client-id.

---

> **WORKED EXAMPLE:** In the centerpiece incident, `virsh domifaddr --source lease`
> returned nothing (bridged VM, not NAT). `--source agent` returned the "not connected"
> error, confirming `qemu-guest-agent` was absent. `ip neigh show | grep <mac>` also
> returned nothing because the guest had only done DHCP and sent no further IP traffic
> to the host. The DHCP server's lease table held the IP. Correlating the MAC (from
> `virsh domiflist`) with the DHCP leases was the only reliable path to the address.

---

Continue to [`05-runbook.md`](05-runbook.md).
