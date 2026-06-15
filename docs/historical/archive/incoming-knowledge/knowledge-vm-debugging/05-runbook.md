# 05 — Runbook: VM Unreachable → Root Cause

> **Purpose:** An ordered decision tree to follow when a libvirt VM is unreachable.
> Follow each step in sequence; each branch either resolves the incident or points to
> the next diagnostic layer. Do not skip steps — the earlier checks prevent misreading
> the later ones.

---

## Before you start

Gather these facts once; they are needed throughout:

```bash
VM=<domain-name>
BRIDGE=$(virsh domiflist $VM | awk 'NR>2 && $1 != "" {print $3; exit}')
MAC=$(virsh domiflist $VM | awk 'NR>2 && $1 != "" {print $5; exit}')

echo "VM=$VM  BRIDGE=$BRIDGE  MAC=$MAC"
```

---

## Step 1 — Is the domain running?

```bash
virsh domstate $VM
```

- **`running`** → proceed to Step 2.
- **`shut off`** → start it: `virsh start $VM`, then return to Step 1.
- **`paused`** → resume it: `virsh resume $VM`, then return to Step 1.
- **`crashed`** → check `virsh dominfo $VM` and `/var/log/libvirt/qemu/$VM.log` for
  a QEMU error. This is a host-side problem (missing device, out of memory, firmware
  misconfiguration).

---

## Step 2 — Is the virtual NIC on the bridge?

```bash
ip link show master $BRIDGE
```

Expect to see `vnet<N>` in the output.

- **Present** → proceed to Step 3.
- **Absent** → the guest NIC is not bridged. Check the domain XML:
  `virsh dumpxml $VM | grep -A5 'interface'`. Verify `<source bridge='$BRIDGE'/>`.
  If wrong, `virsh edit $VM`, correct the bridge name, and `virsh reboot $VM`.

> **GUARDRAIL:** IP forwarding must be enabled on the host for routed traffic to reach
> the guest from other hosts. Check: `sysctl net.ipv4.ip_forward`. Should be `1`.
> If `0`: `sysctl -w net.ipv4.ip_forward=1` (persist in `/etc/sysctl.d/`).

---

## Step 3 — Is the guest transmitting? (packet capture)

```bash
sudo tcpdump -ni $BRIDGE -e "ether host $MAC and (port 67 or port 68)" -c 10 --timeout 30
```

- **DHCP packets seen** → the guest NIC is healthy. Note whether the server replied.
  Proceed to Step 4.
- **No packets after 30 seconds** → the guest is not transmitting DHCP. Check boot
  state (Step 3a).

### Step 3a — Check boot state via serial console

```bash
PTY=$(virsh ttyconsole $VM)
cat $PTY
```

- **Login prompt visible** → the guest booted. It may be configured with a static IP
  or DHCP already completed. Proceed to Step 4.
- **cloud-init output, no login prompt** → boot in progress. Wait 2–5 minutes; cloud-init
  package installs can be slow. If stuck for >10 minutes, suspect a blocked apt proxy.
- **GRUB/UEFI boot loop** → firmware mismatch. See the UEFI/BIOS note in
  `02-serial-console-triage.md`. Stop here and fix the domain definition.
- **Kernel panic** → image or disk bus problem. Check `virsh dumpxml $VM | grep disk`.

---

## Step 4 — Find the guest's IP address

Try each method in order; stop at the first success:

```bash
# Method A: guest agent (requires qemu-guest-agent inside the guest)
virsh domifaddr $VM --source agent

# Method B: host ARP cache
virsh domifaddr $VM --source arp
# or equivalently:
ip neigh show | grep $MAC

# Method C: DHCP server lease table (location varies by DHCP server)
grep $MAC /var/lib/misc/dnsmasq.leases 2>/dev/null
```

- **IP found by Method A** → `qemu-guest-agent` is running. If the VM is still
  unreachable by hostname, mDNS (`avahi-daemon`) may be missing. Try
  `ssh user@<ip>` directly.
- **IP found by Method B or C, but not A** → `qemu-guest-agent` is not running. The
  guest probably has an IP; try `ssh user@<ip>`. Then inspect the guest offline
  (Step 5) to understand why the agent is missing.
- **No IP found by any method** → the guest either never got a DHCP lease or the lease
  expired. Proceed to Step 5 to read the guest offline.

---

## Step 5 — Read the guest offline (libguestfs)

> **GUARDRAIL:** Shut the VM down before mounting its disk read-write. For read-only
> inspection, `--ro` is safe while the VM is running, but stopping it first is safer.

```bash
virsh shutdown $VM
# Wait for: virsh domstate $VM → shut off
```

Read the cloud-init log:

```bash
virt-cat -d $VM /var/log/cloud-init-output.log | tail -100
```

Read the apt proxy config:

```bash
virt-ls -d $VM /etc/apt/apt.conf.d/
virt-cat -d $VM /etc/apt/apt.conf.d/01proxy 2>/dev/null || echo "(no 01proxy file)"
```

Read the network config:

```bash
virt-cat -d $VM /etc/netplan/50-cloud-init.yaml 2>/dev/null \
  || virt-cat -d $VM /etc/network/interfaces
```

---

## Step 6 — Root-cause checklist

Work through this in order. **Proxy reachability is first** — it is the most common
cause of a guest that boots but has no discovery agent:

| # | Check | How to verify | Fix |
|---|-------|---------------|-----|
| 1 | **Apt proxy address is routable from the guest's segment** | `virt-cat -d $VM /etc/apt/apt.conf.d/01proxy`; verify IP is on the same or reachable segment | Pass the real, reachable proxy address in cloud-init user-data; never commit a placeholder. See 12-factor Config. |
| 2 | **Proxy service is running and reachable** | From host: `curl -s -o /dev/null -w '%{http_code}' -x http://<proxy>:<port> http://deb.debian.org/debian/dists/stable/Release` → expect 200 | Start the proxy service; fix firewall rules |
| 3 | **cloud-init package list includes qemu-guest-agent** | `virt-cat -d $VM /etc/cloud/cloud.cfg` | Add `qemu-guest-agent` to the packages list in user-data |
| 4 | **cloud-init package list includes avahi-daemon** | Same as above | Add `avahi-daemon` to packages |
| 5 | **DHCP lease assigned** | DHCP server lease table | Check DHCP server config; verify guest is in the right VLAN |
| 6 | **Domain XML has guest agent channel** | `virsh dumpxml $VM \| grep -A3 channel` | Add `<channel type='unix'>` with `name='org.qemu.guest_agent.0'` |

---

## After finding the root cause

Fix the underlying input (cloud-init user-data, provisioning variables, proxy config)
**before** reprovisioning. A reprovision without fixing the input reproduces the same
failure.

See [`06-symptom-to-cause-ledger.md`](06-symptom-to-cause-ledger.md) for the full
worked example of the most common failure path.
