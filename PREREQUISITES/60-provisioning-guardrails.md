# 60 — Provisioning guardrails & anti-patterns (hard-won)

> **Purpose:** The symptom → cause → fix ledger for **machine provisioning** — the dead
> ends a provisioning agent hits when it builds a real dev box (especially a Debian
> cloud-image VM behind a caching apt proxy) so it never pays for them twice. Pairs with
> the [HANDOFF TO THE PROVISIONING AGENT](README.md) contract and the
> [`ansible/`](ansible/) fragments.

Markers match the marketplace convention: **GUARDRAIL** (prevents a known failure),
**ANTI-PATTERN (DO NOT)** (forbidden approach + why), **WORKED EXAMPLE** (a real,
shipped reference). When a marker and your instinct disagree, the marker wins — it was
written *after* the mistake.

> **Provenance:** distilled from building a libvirt **Debian-13 genericcloud** VM fleet
> (cloud-init + an HTTP-only `apt-cacher-ng` cache), provisioned by an Ansible project of
> exactly this shape. Every guardrail below was paid for in real debugging time.

---

## 1. Volta must be installed with `--skip-setup`

> **GUARDRAIL:** Install Volta as `curl https://get.volta.sh | bash -s -- --skip-setup`,
> not the bare `… | bash`.

- **Symptom:** every provisioning re-apply reports a 4-line change set (the `VOLTA_HOME`
  / `PATH` exports in `~/.bashrc` and `~/.profile`); the run never converges to
  `changed=0`.
- **Cause:** Volta's installer runs `volta setup`, which **appends** `VOLTA_HOME` + `PATH`
  exports to the user's shell rc files. If your provisioning also manages the shell
  environment (a `fleet-core.sh` / rc fragment), it strips those inline exports — and the
  two fight on every apply.
- **Fix:** `--skip-setup` stops Volta touching the rc files; export `VOLTA_HOME` and put
  `~/.volta/bin` on `PATH` from your own managed shell fragment instead.

> **ANTI-PATTERN (DO NOT):** rely on `volta setup` for the shell env when something else
> already manages it. Two writers, perpetual churn.

> The shipped [`ansible/core-bootstrap.yml`](ansible/core-bootstrap.yml) uses
> `--skip-setup` for this reason.

---

## 2. Debian `genericcloud` images are UEFI-only

> **GUARDRAIL:** Boot Debian `*-genericcloud-*.qcow2` VMs with **UEFI/OVMF**
> (`virt-install --boot uefi`), never legacy BIOS.

- **Symptom:** under SeaBIOS the VM shows `running` but GRUB loops forever
  (`Booting 'Debian GNU/Linux'` repeating); the kernel never loads, no SSH, no DHCP lease.
- **Cause:** the genericcloud image ships a UEFI boot path; legacy-BIOS GRUB does not
  hand off to the kernel.
- **Fix:** `--boot uefi` (libvirt OVMF firmware autoselection). A hand-installed
  (netinst) Debian VM boots fine under BIOS, which masks the difference — don't let a
  working netinst VM convince you the cloud image will too.

---

## 3. cloud-init regenerates `/etc/apt/mirrors/*.list` — disable it before customizing the mirror

> **GUARDRAIL:** If you customize the base apt mirror on a Debian cloud image, set
> `apt: { generate_mirrorlists: false }` in the cloud-init **user-data**.

- **Symptom:** your custom `/etc/apt/mirrors/debian.list` (whatever the mechanism —
  `write_files`, the cloud-init `apt: primary/security` module, or `runcmd`) is silently
  reverted to the image default (`https://deb.debian.org/debian`) by the time apt runs.
- **Cause:** Debian's cloud image ships `generate_mirrorlists: true` in
  `/etc/cloud/cloud.cfg.d/01_debian_cloud.cfg`; `cc_apt_configure` **regenerates** the
  mirror-list files from `package_mirrors` *after* `cc_write_files`, overwriting yours.
- **Fix:** set `generate_mirrorlists: false` in user-data (user-data overrides the
  image's cloud.cfg.d), then write your mirror files — they now stick.

> **ANTI-PATTERN (DO NOT):** assume `write_files` / `apt: primary` is the final word on a
> Debian cloud image. It is not, until `generate_mirrorlists` is off. (Symptom of the
> deeper rule: on cloud-init, know *which module writes last*.)

---

## 4. An HTTP-only apt cache can't tunnel HTTPS — rewrite, don't bypass

> **GUARDRAIL:** To cache an `https://` apt repo through an HTTP-only proxy
> (apt-cacher-ng), reference it as **`http://HTTPS///<host>/<path>`** (acng's built-in
> HTTPS-remap form), with the client's `Acquire::http::Proxy` pointing at the cache.

- **Symptom:** apt through the proxy fails on every HTTPS source with
  `403 CONNECT denied (ask the admin to allow HTTPS tunnels)`; package lists stay empty.
- **Cause:** apt-cacher-ng is HTTP-only and cannot tunnel an HTTPS `CONNECT`. A cloud
  image's default mirror (and many third-party repos) are HTTPS.
- **Fix:** the `http://HTTPS///host/path` rewrite makes the cache fetch + cache the real
  `https://host/path`. This applies to the **base-distro mirrorlist too** (combine with
  guardrail #3 to make it stick). If the cache is locked down (`ForceManaged: 1`), every
  host — base distros included — also needs an explicit `Remap` rule; an unlisted host
  then returns `403` by design.

> **WORKED EXAMPLE:** a guest whose `debian.list` reads
> `http://HTTPS///deb.debian.org/debian` does a clean, cached `apt update` (`Hit:` every
> suite) through the locked-down cache.

---

## 5. Refresh the apt cache best-effort on a messy host

> **GUARDRAIL:** When installing the toolchain, do a best-effort `apt update` (tolerate
> failure) and install from cached lists, rather than a hard `update_cache: true` that
> aborts the whole run.

- **Symptom:** the provisioning run dies at "install packages" because *some unrelated*
  third-party repo on the host (a stale PPA, an HTTPS repo the cache can't serve, a
  `BADSIG`) makes `apt-get update` return non-zero.
- **Cause:** `apt: update_cache: true` (or `apt-get update &&`) treats any source failure
  as fatal, even when the packages you need are already in the cached lists.
- **Fix:** update best-effort (`failed_when: false` / a tolerant wrapper), then
  `apt install` with `update_cache: false`. On a pristine box this is a no-op; on a real
  box it stops unrelated repo cruft from blocking the toolchain.

---

## 6. cloud-init applies the seed once-per-instance — clear stale artifacts on rebuild

> **GUARDRAIL:** When you destroy a VM and rebuild it under the **same name**, delete the
> old cloud-init seed (and any pool disk/seed volumes) first, or the rebuild boots a
> **stale** seed.

- **Symptom:** template/seed edits don't take effect on a rebuilt VM; the guest keeps
  behaving like the previous build.
- **Cause:** cloud-init runs a given seed **once per instance-id**; and a builder that
  guards seed creation with `creates:`/volume-exists checks will *reuse* a cached local
  seed or pool volume from the prior build. `virsh undefine --remove-all-storage` does
  **not** necessarily remove the pool volumes either.
- **Fix:** teardown must remove the domain **and** the disk + seed volumes **and** the
  staged seed dir before recreating. (Tells you the deeper rule: seed identity must track
  content, not just VM name.)

---

## 7. Driving a REMOTE hypervisor over `qemu+ssh://` — four prerequisites

> **GUARDRAIL:** Provisioning VMs on a *remote* libvirt host (`virsh --connect
> qemu+ssh://user@host/system`, `virt-install --connect …`) needs four things the
> *local* path never exposes. Each is silent until you point at a real remote host.

1. **Trust the hypervisor's SSH host key on the controller.** libvirt's `qemu+ssh`
   transport uses plain `ssh` and does **not** honour Ansible's
   `host_key_checking=False`; an unknown host key fails with
   `Host key verification failed` / `ssh-askpass … No such file`. → `ssh-keyscan` the
   hypervisor into the controller's `~/.ssh/known_hosts` first (idempotently).
2. **Escalate locally only for a local connection.** A play that `become: true` for
   `qemu:///system` must **not** escalate for `qemu+ssh://user@host` — the transport
   has to run as the **SSH user** (its key + known_hosts), not root. Gate it:
   `become: "{{ target in ['localhost','127.0.0.1'] }}"`.
3. **Build the cloud-init seed as the controller user.** Seed-staging tasks should run
   `become: false` into a user-owned dir (`~/.cache/…`), so a local (escalated) run and
   a remote (user) run never clash over root-vs-user file ownership of the staged seed.
4. **The qemu-run user needs the `kvm` group.** If the host's `/etc/libvirt/qemu.conf`
   runs qemu as a **login user** (a common desktop config, `user="…"`) rather than the
   default `libvirt-qemu:kvm`, that user must be in the **`kvm`** group or qemu can't
   open `/dev/kvm` (`Could not access KVM kernel module: Permission denied`). Add the
   operator to `libvirt`+`kvm` and **restart libvirtd** so freshly-spawned qemu inherits
   it. *(Default libvirt-qemu setups already have this; the custom-user ones don't.)*

> **ANTI-PATTERN (DO NOT):** allocate VM names per-hypervisor when you run a multi-host
> fleet — host A and host B both start at `…-001` and collide in a shared inventory.
> Allocate names unique **fleet-wide** (per-host offset/prefix, or from the inventory).

---

## 8. Bridging a remote hypervisor's NIC + multi-host ergonomics

> **GUARDRAIL:** To give VMs real LAN addresses (reachable fleet-wide, not just from the
> hypervisor), bridge a host NIC — but the Ansible **control path must be a *different*
> NIC than the one you bridge**, and the cutover must verify + roll back.

- **Symptom:** bridging the host's primary/default-route NIC takes the host (and your
  SSH session) offline mid-play, with no way back in.
- **Cause:** the NIC you bridge is usually the default route; a botched NetworkManager
  cutover drops it.
- **Fix:** control the host over a *second* NIC (e.g. manage via `eno1`, bridge `eno2`).
  Create the bridge with NetworkManager, **replicating the NIC's ipv4** (addresses,
  gateway, DNS) onto the bridge so the host keeps its address + default route, then
  **verify** (NIC enslaved, bridge has an IP, gateway pings) and **roll back** to the
  original connection on failure. The control NIC is unaffected, so verify/rollback is
  reliable. Have console access the first time regardless.

> **GUARDRAIL (naming):** derive the fleet-wide id (the octet above) from `ip route get`
> (local) / `getent` (remote) — `ansible_default_ipv4` is unreliable when a host has
> multiple default routes (it can come back empty → a `000` id).

> **GUARDRAIL (ergonomics):** have the create flow write a controller
> `~/.ssh/config.d/<name>.conf` (behind an `Include`) with the full name **and** a short
> alias and `HostName <name>.local`, removed on teardown. Then `ssh <prefix>-<TAB>`
> tab-completes every VM with no hand-typed `.local` — the difference between a fleet you
> can reach from memory and one you can't.

---

## Related

- [README — provisioning handoff contract](README.md) ·
  [`ansible/core-bootstrap.yml`](ansible/core-bootstrap.yml) ·
  [`ansible/apt.yml`](ansible/apt.yml) · [`00-core.md`](00-core.md)
