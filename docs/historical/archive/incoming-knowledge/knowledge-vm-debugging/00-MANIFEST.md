# 00 — MANIFEST

> **Purpose:** The charter of the `VM-DEBUGGING` knowledge package. Mission, scope,
> prime directives, and the glossary that makes the rest of the package unambiguous.
>
> **TL;DR:** A libvirt VM that shows `running` but is unreachable is not necessarily
> broken — it may be invisible because the tools you are using cannot find it. Diagnose
> before you destroy and reprovision. The prime directive: **"the VM is live but
> invisible" ≠ "the VM is broken"**.

---

## 1. Mission

This package exists to answer one question reliably:

> **Why can't I reach this VM, and what do I do about it?**

It gives operators and agents a complete, ordered toolkit — serial console, offline
disk inspection, packet capture, IP-discovery fallbacks — that reaches a root cause
without SSH access, without credentials, and without guesswork.

The success condition is: **a confirmed root cause with a fix, not a reprovisioning
reflex**.

---

## 2. Scope

**In scope:**

- libvirt/QEMU guests on Linux hosts (bridged or NAT networking)
- cloud-init provisioned guests (NoCloud, ConfigDrive, or similar datasources)
- Situations where the guest appears to be running but is unreachable (no SSH, no IP,
  no mDNS, no ping)
- Read-only offline inspection of guest filesystems

**Out of scope:**

- Bare-metal (PXE) provisioning failures
- Containerized workloads (Docker, Podman, LXC)
- Hypervisors other than libvirt/QEMU (VMware, Hyper-V, VirtualBox)
- Networking faults that are not related to guest provisioning

---

## 3. Prime directives (non-negotiable)

> **IMPORTANT — THE ONLY WAY:** These directives override the reflex to reprovision.
> They are the reason this package exists.

1. **Diagnose before you destroy.** A VM that shows `running` has state worth reading.
   The serial console, the offline disk, and the ARP table all carry evidence. Collect
   it before reprovisioning — or you erase the root cause.

2. **"Live but invisible" is not "broken".** `virsh domifaddr` returning nothing means
   the discovery mechanism failed, not necessarily that the guest failed. Distinguish
   the two before acting.

3. **Infrastructure is guilty until proven innocent.** When a freshly provisioned VM is
   unreachable, check the provisioning inputs (proxy addresses, network config, cloud-init
   seeds) before blaming the guest OS. See 12-factor Config — externalize all
   environment-specific values; never bake non-routable placeholders into committed
   defaults.

4. **Read-only first.** All offline inspection tools default to or support `--ro`
   (read-only) mode. Use it. You are diagnosing, not repairing. Writes to a running
   guest's disk image cause corruption.

5. **Confirm boot state before interpreting absence.** "No IP" means different things
   depending on whether the guest reached the login prompt, is stuck in a boot loop, or
   never started. Confirm with the serial console before drawing conclusions.

---

## 4. The core insight

> **GUARDRAIL:** Every IP-discovery mechanism for a bridged VM depends on software
> **inside the guest** running correctly. If that software failed to install (because
> cloud-init's apt commands failed), every discovery tool will report nothing — not
> because the guest is unreachable, but because the discovery agent is missing.

This is the trap: you look for the VM with the tools designed to find it, they return
nothing, and you conclude the VM is broken. The VM may be perfectly healthy and waiting
at a login prompt. The tools you used simply could not find it because the bridge
between "running guest" and "discoverable guest" (qemu-guest-agent, avahi-daemon) was
never installed.

---

## 5. Glossary

| Term | Meaning |
|---|---|
| **Bridge** | A Linux virtual network bridge (e.g. `br0`, `virbr0`) connecting the guest's virtual NIC to the host's physical or virtual network. |
| **cloud-init** | The standard multi-distribution package for early-boot guest initialization. Reads user-data/network-config from a datasource and configures the guest. See [NoCloud datasource docs](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html). |
| **domifaddr** | `virsh domifaddr <vm>` — queries a guest's interface addresses via one of several sources. Source matters: `lease`, `agent`, `arp`. See [virsh manpage](https://www.libvirt.org/manpages/virsh.html#domifaddr). |
| **guestfish** | Interactive shell for libguestfs — can read/write a guest filesystem offline. See [libguestfs API](https://libguestfs.org/guestfs.3.html). |
| **libguestfs** | A library and toolset for accessing and modifying guest disk images without booting the guest. Canonical tools: `virt-cat`, `virt-ls`, `guestfish`. |
| **mDNS / .local** | Multicast DNS. Guests publish their hostname on the LAN via `avahi-daemon`. If avahi is not running, `<host>.local` does not resolve. |
| **NoCloud datasource** | A cloud-init datasource that reads user-data and network-config from a local ISO or filesystem — used for VMs that don't run in a cloud. |
| **qemu-guest-agent** | A daemon running inside the guest that lets the host query guest state (IP addresses, filesystem info, etc.) via a virtio channel. Required for `virsh domifaddr --source agent`. |
| **serial console** | A PTY exposed by QEMU for the guest's serial port. Carries kernel boot messages, GRUB output, and login prompts. Accessible without network. |
| **vnet** | A virtual network interface on the host (e.g. `vnet0`) that connects one guest NIC to a bridge. Presence = guest NIC is attached to the bridge. |
