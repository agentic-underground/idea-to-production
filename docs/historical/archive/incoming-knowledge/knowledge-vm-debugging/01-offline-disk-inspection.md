# 01 — Offline Disk Inspection (libguestfs)

> **Purpose:** Read a guest VM's filesystem without booting it. Confirm what
> cloud-init wrote, read logs, inspect configuration — all without SSH or credentials.

Reference: [libguestfs API](https://libguestfs.org/guestfs.3.html)

---

## Why offline inspection

When a guest is unreachable, the thing you most need to read — `/var/log/cloud-init-output.log`,
`/etc/netplan/`, `/etc/apt/` — is locked inside the disk image. libguestfs lets you
read it directly from the host, no guest cooperation required.

> **GUARDRAIL:** The VM must be shut off (or you must pass `--ro`) before running
> libguestfs tools against its disk image. Running libguestfs against a running VM's
> disk in read-write mode causes **filesystem corruption**. Use `virsh shutdown <vm>`
> first, or always pass `--ro` / `--add --ro`.

---

## Installation

```bash
# Debian/Ubuntu
sudo apt install libguestfs-tools

# Fedora/RHEL
sudo dnf install libguestfs-tools
```

---

## The canonical tools

### `virt-cat` — print a single file

```bash
virt-cat -a /path/to/disk.qcow2 /etc/netplan/50-cloud-init.yaml
virt-cat -d <vm-name> /var/log/cloud-init-output.log
```

`-a` takes a disk image path. `-d` takes a libvirt domain name (looks up the disk
image from the domain XML automatically). Use `-d` when you have a running domain
definition; use `-a` for raw images.

### `virt-ls` — list directory contents

```bash
virt-ls -a /path/to/disk.qcow2 /etc/apt/
virt-ls -l -d <vm-name> /var/log/   # long listing with permissions and sizes
```

### `guestfish` — interactive shell

For exploring freely or reading multiple files in one session:

```bash
guestfish --ro -d <vm-name>

# Inside the shell:
><fs> run
><fs> list-filesystems
><fs> mount /dev/sda1 /
><fs> cat /etc/os-release
><fs> cat /var/log/cloud-init-output.log
><fs> ls /etc/apt/apt.conf.d/
><fs> cat /etc/apt/apt.conf.d/01proxy
><fs> exit
```

> **IMPORTANT — THE ONLY WAY:** Always open guestfish with `--ro` unless you
> specifically intend to repair the disk. Read-only is the safe default for diagnosis.

---

## What to read and why

### `/var/log/cloud-init-output.log`

The most valuable file. Contains the stdout/stderr of every cloud-init module,
including every `apt-get` command. Failed package installs are visible here verbatim.

Key patterns to look for:

| Pattern in log | What it means |
|---|---|
| `Could not connect to proxy` | The apt proxy address is wrong or unreachable |
| `E: Unable to locate package qemu-guest-agent` | Package not found (wrong suite, missing repo) |
| `E: Failed to fetch http://…` followed by `Connection refused` | Proxy host exists but port is wrong |
| `E: Failed to fetch http://…` followed by `Could not resolve` | DNS failure or wrong proxy hostname |
| `Traceback` or `ImportError` | cloud-init Python error — usually datasource config issue |
| `finished at` with no errors | cloud-init completed; if VM still unreachable, look at networking |

### `/etc/netplan/*.yaml` (Ubuntu) or `/etc/network/interfaces` (Debian)

Confirms what cloud-init wrote for network configuration. For bridged VMs, verify:
- The correct interface name (`ens3`, `eth0`, etc.)
- DHCP enabled (`dhcp4: true`)
- No conflicting static configuration

### `/etc/apt/apt.conf.d/`

Cloud-init may write a proxy configuration here (commonly `01proxy` or `proxy.conf`).

```bash
virt-ls -d <vm-name> /etc/apt/apt.conf.d/
virt-cat -d <vm-name> /etc/apt/apt.conf.d/01proxy
```

A non-routable address here (e.g. a placeholder IP, `169.254.x.x`, or a private range
that is not reachable from this segment) will silently cause every `apt` command to fail.

> **WORKED EXAMPLE:** In the centerpiece incident (see `06-symptom-to-cause-ledger.md`),
> `virt-cat -d <vm> /etc/apt/apt.conf.d/01proxy` revealed
> `Acquire::http::Proxy "http://203.0.113.1:3142";` — a documentation-range address
> (RFC 5737 TEST-NET) that was never reachable on the actual network segment. Every
> `apt-get install` failed silently. `qemu-guest-agent` and `avahi-daemon` were never
> installed.

### `/var/log/cloud-init.log`

More verbose than `cloud-init-output.log`. Contains per-module lifecycle events.
Useful for confirming which modules ran and which were skipped.

### `/etc/cloud/cloud.cfg` and `/etc/cloud/cloud.cfg.d/`

The cloud-init configuration baked into the image. Shows which modules are enabled,
what the default user is, and whether `qemu-guest-agent` is in the package list.

---

## Multi-disk / LVM guests

If `list-filesystems` shows LVM volumes:

```bash
><fs> run
><fs> list-filesystems
# Returns e.g. /dev/ubuntu-vg/ubuntu-lv: ext4
><fs> mount /dev/ubuntu-vg/ubuntu-lv /
><fs> ls /
```

---

## Read-only confirmation

When using `virt-cat` or `virt-ls` with `-d`, libguestfs honours the domain's disk
read-only setting. For an extra safety layer with raw image paths, use:

```bash
virt-cat --add disk.qcow2:ro /path/to/file
```

> **ANTI-PATTERN (DO NOT):** Do not run `guestfish` without `--ro` against a VM that
> might still be running (even if `virsh list` shows it stopped — confirm with
> `virsh domstate`). Concurrent access corrupts qcow2 metadata.

---

Continue to [`02-serial-console-triage.md`](02-serial-console-triage.md).
