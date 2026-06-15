# 06 — Symptom-to-Cause Ledger

> **Purpose:** A reference ledger of symptom → cause → fix entries for VM
> unreachability problems. The centerpiece worked example documents the complete,
> real failure chain that motivated this package.

---

## How to read this ledger

Each entry follows the pattern:

- **Symptom** — what the operator observes
- **Cause** — what actually produced the symptom
- **Fix** — the specific corrective action
- **Do not** — the wrong reflex to avoid

---

## Centerpiece: the invisible bridged VM

> **WORKED EXAMPLE:** This is the incident that grounded this entire knowledge package.
> Every tool and technique in documents `01`–`05` was used in diagnosing it. Read this
> worked example before treating it as a reference — the causal chain is subtle and
> each link appears to be a different problem.

### Presenting symptoms

- `virsh list --all` shows the VM as `running`
- `virsh domifaddr <vm>` (default `--source lease`) returns no output
- `ping <vm>.local` fails — `Name or service not known`
- `ssh user@<vm>.local` fails
- `virsh domifaddr <vm> --source agent` returns: `error: Guest agent is not responding`

### What looks like the problem

The agent error makes it look like the guest NIC is broken, or QEMU's guest agent
channel is misconfigured, or the guest crashed silently.

### What the serial console showed

```bash
PTY=$(virsh ttyconsole <vm>)
cat $PTY
```

Output (tail):

```
[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Graphical Interface.

Debian GNU/Linux 13 <vm-hostname> ttyS0

<vm-hostname> login:
```

**The guest booted cleanly to a login prompt.** It was not broken. It was waiting.

### What packet capture showed

```bash
sudo tcpdump -ni br0 -e "ether host 52:54:00:ab:cd:ef and (port 67 or port 68)"
```

DHCP exchange was visible and complete. The DHCP server assigned an IP. The guest had
been reachable at that IP since boot. It was never "down."

### What offline disk inspection revealed

```bash
virsh shutdown <vm>
virt-cat -d <vm> /var/log/cloud-init-output.log | grep -E "(ERROR|E:|apt-get|proxy)"
```

Key lines from the log:

```
Err:1 http://HTTPS///deb.debian.org/debian bookworm InRelease
  Could not connect to 203.0.113.1:3142 (203.0.113.1). - connect (111: Connection refused)
...
E: Failed to fetch http://HTTPS///deb.debian.org/debian/dists/bookworm/InRelease
   Could not connect to 203.0.113.1:3142
...
WARNING: apt-get failed. 0 packages installed.
```

And from `/etc/apt/apt.conf.d/01proxy`:

```
Acquire::http::Proxy "http://203.0.113.1:3142";
```

`203.0.113.1` is from the RFC 5737 TEST-NET-3 documentation range. It was a
**placeholder** committed to the provisioning defaults. It was never a reachable host
on the actual network segment.

### The complete causal chain

```
Committed provisioning default contained a placeholder proxy address (203.0.113.1)
  ↓
cloud-init wrote that address to /etc/apt/apt.conf.d/01proxy
  ↓
Every apt-get call in cloud-init attempted to reach 203.0.113.1:3142
  ↓
Connection refused (no host at that address on this segment)
  ↓
All package installs failed silently — cloud-init continued but installed 0 packages
  ↓
qemu-guest-agent was NOT installed → virsh domifaddr --source agent fails
  ↓
avahi-daemon was NOT installed → <vm>.local does not resolve
  ↓
The VM is reachable by IP (DHCP worked; network stack needs no agent)
but invisible by every hostname/agent-based discovery mechanism
```

### The fix

1. **Immediate:** pass the real, reachable apt proxy address in the provisioning
   configuration (as an environment-specific override, not a committed default).
2. **Structural:** keep environment-specific values — proxy addresses, network
   coordinates, any address that varies by deployment segment — in a gitignored
   overlay (`.env`, a local vars file, a vault secret). Never commit a placeholder
   that a provisioning tool will treat as real. See 12-factor Config — externalize all
   environment-specific configuration.
3. **Verification:** after reprovisioning with the correct proxy address, confirm:
   - `virsh domifaddr <vm> --source agent` returns an IP
   - `ping <vm>.local` resolves
   - `virt-cat -d <vm> /var/log/cloud-init-output.log` shows no apt failures

> **ANTI-PATTERN (DO NOT):** Do not reprovision without first reading
> `cloud-init-output.log` offline. Reprovisioning with the same broken config
> reproduces the same failure. The log is always the first read.

---

## Reference entries

### E1 — `virsh domifaddr` returns nothing on a bridged VM

**Symptom:** `virsh domifaddr <vm>` produces no output.  
**Cause:** The default `--source lease` only queries libvirt's internal dnsmasq, which
has no visibility into LAN DHCP leases.  
**Fix:** Use `--source agent`, `--source arp`, or `ip neigh show | grep <mac>`.  
**See:** `04-guest-agent-and-ip-discovery.md`

---

### E2 — `<vm>.local` does not resolve

**Symptom:** `ping <vm>.local` → `Name or service not known`.  
**Cause (primary):** `avahi-daemon` is not installed or not running in the guest.  
**Cause (secondary):** The host does not have `avahi-resolve` / `nss-mdns` configured.  
**Fix:** Ensure `avahi-daemon` is in the cloud-init packages list; use its correct name
for the distro. Verify from host: `avahi-browse -a` should list the guest.

---

### E3 — guest agent error: "not connected"

**Symptom:** `virsh domifaddr <vm> --source agent` → `error: Guest agent is not responding`.  
**Cause (A):** `qemu-guest-agent` was not installed in the guest.  
**Cause (B):** The domain XML does not contain the `org.qemu.guest_agent.0` virtio channel.  
**Fix (A):** Add `qemu-guest-agent` to cloud-init packages; ensure apt succeeds.  
**Fix (B):** Add the channel device to the domain XML and restart the guest.

---

### E4 — GRUB/UEFI boot loop on a cloud image

**Symptom:** Serial console shows repeating GRUB or UEFI shell output; VM never boots.  
**Cause:** Debian `genericcloud` qcow2 images require UEFI (OVMF). A BIOS-mode domain
definition causes an immediate boot loop.  
**Fix:** Redefine the domain with `<loader readonly='yes' type='pflash'>` pointing to
the OVMF firmware path.  
**See:** `02-serial-console-triage.md`, and the `d13-cloud-image-uefi` knowledge note.

---

### E5 — apt fails with "Connection refused" to proxy

**Symptom:** `cloud-init-output.log` shows `Could not connect to <proxy-ip>:<port>`.  
**Cause:** The proxy address in `/etc/apt/apt.conf.d/` is wrong (placeholder, wrong
segment, service not running).  
**Fix:** Provide the real proxy address for this network segment. Verify the proxy
service is running and the port is open: `curl -x http://<proxy>:<port> http://deb.debian.org/`.  
**See:** resilient-external-apis protocol — treat the proxy as an external dependency;
assert its reachability in provisioning preflight before proceeding.

---

### E6 — cloud-init completes but packages not installed

**Symptom:** `cloud-init-output.log` ends with `finished at` but `WARNING: 0 packages installed`.  
**Cause:** apt failed (proxy, DNS, mirror) and cloud-init continued anyway (non-fatal).  
**Fix:** Fix the upstream cause (E5 above); reprovision. Do not treat "cloud-init finished"
as "cloud-init succeeded" — check the log for apt errors explicitly.

> **ANTI-PATTERN (DO NOT):** Do not treat a zero-error exit from `virsh start` or
> "cloud-init finished" as evidence that provisioning succeeded. Cloud-init does not
> fail the boot on apt errors. Always read `cloud-init-output.log`.
