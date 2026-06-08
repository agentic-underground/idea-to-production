# VM-DEBUGGING — Knowledge Package

> **Purpose:** This package is **intake-stage field knowledge** distilled from real
> incidents debugging bridged libvirt VMs that booted but remained invisible on the
> network. It documents every tool, triage step, decision point, and root-cause pattern
> that was paid for in debugging time — so an agent or operator never has to rediscover them.

This is not a tutorial. It is a **field reference and decision system**. Every technique,
command, and guardrail in here was validated against a live, misbehaving VM.

---

## What this package covers

Diagnosing a libvirt/QEMU guest that is running (or appears to be) but is unreachable:
no SSH, no IP in `virsh domifaddr`, no mDNS, no ping. The canonical symptoms are:

- `virsh list --all` shows `running`
- `virsh domifaddr <vm>` returns nothing useful
- `ping <vm>.local` fails
- The VM was freshly provisioned with cloud-init

The root cause is **often infrastructure, not the VM itself** — a misconfigured apt
proxy, a wrong network segment, a missing cloud-init package install. This package
gives you the tools to find out without guessing.

---

## How to read the certainty markers

Every consequential statement in this package is tagged. The markers mean exactly this:

- `> **IMPORTANT — THE ONLY WAY:**` — The single sanctioned approach. No acceptable
  alternative. Do not deviate.
- `> **GUARDRAIL:**` — A rule that prevents a specific, known failure. Breaking it
  reintroduces a problem already paid for.
- `> **ANTI-PATTERN (DO NOT):**` — A forbidden or outdated approach, always paired with
  *why* and the correct alternative.
- `> **WORKED EXAMPLE:**` — The concrete reference incident that grounded this knowledge.

When a marker and your instinct disagree, the marker wins.

---

## Index of documents

Read in order for a new incident. Consult individual documents once the workflow is familiar.

| # | Document | What it gives you |
|---|----------|-------------------|
| — | [`00-MANIFEST.md`](00-MANIFEST.md) | Charter, scope, prime directives, glossary. **Read first.** |
| 1 | [`01-offline-disk-inspection.md`](01-offline-disk-inspection.md) | libguestfs: read the VM's filesystem without booting it. |
| 2 | [`02-serial-console-triage.md`](02-serial-console-triage.md) | Raw serial console: determine boot state without SSH or credentials. |
| 3 | [`03-packet-capture.md`](03-packet-capture.md) | tcpdump on the bridge: verify the guest is actually transmitting. |
| 4 | [`04-guest-agent-and-ip-discovery.md`](04-guest-agent-and-ip-discovery.md) | Why `virsh domifaddr` fails on bridged VMs and what to use instead. |
| 5 | [`05-runbook.md`](05-runbook.md) | The decision tree: VM unreachable → root cause found. |
| 6 | [`06-symptom-to-cause-ledger.md`](06-symptom-to-cause-ledger.md) | Symptom → cause → fix entries, anchored by the centerpiece worked example. |

**Fast path for an active incident:** jump to [`05-runbook.md`](05-runbook.md) and
follow the decision tree; it cites the other documents at each branch.

---

## Intake status

This is **field knowledge at intake stage** — extracted from a real debugging session
and ready for promotion into a value handler or standing runbook. It has not yet been
integrated into a formal production handler. The content is authoritative; the
packaging may be refined on promotion.

---

## Provenance

Distilled from a live incident: a fresh Debian 13 cloud-init bridged VM that booted to
a login prompt but was invisible to the fleet (no IP, no mDNS, no agent). Root cause:
a non-routable apt proxy placeholder baked into the cloud-init config prevented
`qemu-guest-agent` and `avahi-daemon` from installing, making the VM undiscoverable by
every mechanism that depends on them. See [`06-symptom-to-cause-ledger.md`](06-symptom-to-cause-ledger.md)
for the full worked example.
