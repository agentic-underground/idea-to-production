# 02 — Serial Console Triage

> **Purpose:** Determine the guest's boot state — booted, boot-looping, or stuck —
> using the raw serial console, without SSH, without credentials, and without a
> graphical console.

---

## Why the serial console

SSH requires the guest to be fully booted and network-accessible. The serial console
requires neither. It carries kernel messages, GRUB output, systemd boot progress, and
the login prompt — everything you need to confirm whether the guest booted at all.

> **GUARDRAIL:** Reading the serial console gives you **boot state**, not SSH access.
> You can observe whether the guest reached a login prompt; you cannot log in unless
> you have credentials (or the image has a known default user). That is enough to
> distinguish "booted but unreachable" from "never finished booting" — which is the
> question that matters here.

---

## Finding the serial console PTY

```bash
virsh ttyconsole <vm-name>
```

Returns the path to the PTY device, e.g.:

```
/dev/pts/3
```

This PTY is live: the guest's serial output is continuously written to it.

---

## Reading it

```bash
# One-shot read of whatever is currently buffered:
cat /dev/pts/3

# Or attach with a terminal multiplexer for a live stream:
screen /dev/pts/3
# Detach with Ctrl-A, then k (kill window) or Ctrl-A d (detach)

# Alternatively, with minicom or picocom if installed:
picocom /dev/pts/3
```

> **IMPORTANT — THE ONLY WAY:** Use `cat <pty>` for a quick read of buffered output.
> Use `screen` or `picocom` only if you need to interact (send keystrokes) or watch
> live. For diagnosis, `cat` is usually sufficient — the boot messages are buffered in
> the PTY.

---

## Interpreting what you see

### Signature: clean boot — login prompt present

```
Debian GNU/Linux 13 <hostname> ttyS0

<hostname> login:
```

The guest reached multi-user target. It is **booted and waiting**. If it is unreachable
over the network despite this, the problem is in networking or discovery, not the boot
sequence. Proceed to [`04-guest-agent-and-ip-discovery.md`](04-guest-agent-and-ip-discovery.md).

### Signature: boot loop — GRUB or UEFI cycling

Repeated sequences like:

```
GRUB loading...
Welcome to GRUB!
error: no suitable video mode found.
Booting in blind mode
...
SeaBIOS (version ...)
```

or UEFI:

```
UEFI Interactive Shell v2.2
...
Press ESC in 5 seconds to skip startup.nsh...
```

repeating endlessly means the bootloader cannot find a valid boot entry, or the kernel
panics immediately and QEMU resets. This is a **firmware/boot configuration problem**,
not a networking problem.

> **GUARDRAIL:** A Debian genericcloud `.qcow2` image requires UEFI (`OVMF`). If the
> domain is defined with BIOS firmware (`<loader type='rom'>`), the image will boot-loop
> at the GRUB/SeaBIOS stage indefinitely. The fix is to redefine the domain with
> `<loader readonly='yes' type='pflash'>` pointing to the OVMF firmware. See the
> `d13-cloud-image-uefi` knowledge note.

### Signature: kernel panic or initrd failure

```
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
```

The kernel booted but could not find the root filesystem. Common causes: wrong disk
bus type in the domain XML (e.g. `virtio` vs `sata`), missing virtio modules in the
initrd, or a damaged image.

### Signature: cloud-init running but slow

```
[  OK  ] Started cloud-init - One-time boot configuration.
...
cloud-init[1234]: 2026-06-08 12:34:56,789 - handlers.py[WARNING]: ...
```

Cloud-init is running. If it is stuck here for many minutes without progressing, it
may be blocked on a package install that is timing out (e.g. waiting for a proxy that
is not responding). This is consistent with the centerpiece worked example — the apt
proxy was unreachable, so every `apt-get` call hung until its timeout.

### Signature: blank / no output

If `cat <pty>` returns immediately with no output, either:
1. The guest has been running for a while and the PTY buffer has scrolled past the boot
   messages (normal — the buffer is finite).
2. The guest has not started writing to the serial port yet.
3. The domain is defined without a serial console device.

Check:
```bash
virsh dumpxml <vm-name> | grep -A3 '<serial'
```

A properly configured serial console shows `<serial type='pty'>` with a `<target
port='0'/>`. If absent, add it to the domain XML and restart the guest.

---

## Interacting via the console (last resort)

If you have credentials (or the image uses a known default user) and need to run
commands without SSH:

```bash
virsh console <vm-name>
# Escape sequence: Ctrl-]
```

`virsh console` connects stdin/stdout to the serial console. You can log in and run
commands. Use this only when offline disk inspection is insufficient — reading the
disk is safer and leaves no trace.

> **ANTI-PATTERN (DO NOT):** Do not use `virsh console` as a substitute for fixing
> the underlying networking or discovery problem. Console access is a diagnostic bridge,
> not a permanent operating mode. A VM you can only reach via console is a VM that
> needs its provisioning repaired.

---

Continue to [`03-packet-capture.md`](03-packet-capture.md).
