---
name: scan-all
description: >
  The consolidated pre-release security gate. Runs SECURITY's three audits in parallel —
  scan-for-pii (personal data), scan-for-secrets (credentials), scan-dependencies (supply chain) — then
  merges them into a single SECURITY-REPORT.md with one overall verdict: PASS, REVIEW, or BLOCK.
  Trigger with /scan-all [scope]. This is the entry point the foundry plugin calls as its
  SECURITY station before DELIVERY when SECURITY is installed; it is equally useful standalone
  before any release or open-sourcing. Degrades gracefully: if a sub-skill or its tooling is
  unavailable, it reports the gap rather than silently passing.
metadata:
  type: orchestrator
  output: SECURITY-REPORT.md (verdict PASS | REVIEW | BLOCK)
  composes: [scan-for-pii, scan-for-secrets, scan-dependencies]
model: inherit
---

# SCAN-ALL

One command, one report, one verdict. SCAN-ALL is the front door to SECURITY: it fans out
the three audit lenses, consolidates their findings, and returns a single gating decision a
release pipeline (or a human) can act on.

---

## Quick start

```bash
/scan-all            # full gate: PII + secrets + dependencies → SECURITY-REPORT.md
/scan-all quick      # working-tree PII + secrets only (skip history & deps) — fast pre-commit
/scan-all ./service  # gate a specific subproject
```

---

## How it runs

Spawn the three audits **in parallel** (they share no state):

```
            ┌─ scan-for-pii         (personal data)   ─┐
/scan-all ─┼─ scan-for-secrets       (credentials)    ─┼─▶ consolidate ─▶ verdict
            └─ scan-dependencies  (supply chain)    ─┘
```

Each sub-skill returns its findings section in the shared SECURITY finding format. SCAN-ALL
then:
1. **Merges** the three sections under one report.
2. **Deduplicates** overlaps (e.g. a connection string caught by both scan-for-pii and scan-for-secrets
   → listed once, "confirmed by both").
3. **Computes the overall verdict** (below).
4. **Writes** `SECURITY-REPORT.md`.

---

## The verdict rule

| Verdict | Condition | Meaning for the line |
|---|---|---|
| **BLOCK** | Any CRITICAL finding (live credential, real special-category PII, known-critical/high vuln, private key) | Do **not** ship. foundry's DELIVERY is halted; remediate and re-run. |
| **REVIEW** | No CRITICAL, but ≥1 HIGH or unresolved MEDIUM | Human decision required before ship. foundry surfaces it up the line (questions flow UP). |
| **PASS** | Only LOW/MINIMAL findings, all documented | Clear to ship. Report retained as evidence of diligence. |

The verdict is the **max severity across all three lenses** — a clean PII scan does not offset a
leaked key. A gate that cannot run a lens (missing tool) **cannot return PASS for that lens**;
it returns REVIEW with the gap noted (no-silent-pass).

---

## SECURITY-REPORT.md structure

```markdown
# Security Gate Report — <project>
**Date:** YYYY-MM-DD   **Scope:** <scope>   **Verdict:** BLOCK | REVIEW | PASS

## Executive Summary
| Lens | Status | Highest risk | Coverage |
|------|--------|--------------|----------|
| Personal data (scan-for-pii)   | ✓/⚠/✗ | … | full/partial |
| Credentials (scan-for-secrets)   | ✓/⚠/✗ | … | tree+history+artefacts |
| Supply chain (scan-dependencies) | ✓/⚠/✗ | … | advisory-tool / static-only |

## Findings — Personal Data
## Findings — Credentials
## Findings — Supply Chain
## Remediation (prioritised: CRITICAL → HIGH → hygiene)
## Coverage & Gaps   (what was NOT scanned, and why — tools missing, scope limits)
## Appendix          (files/manifests scanned, exclusions applied)
```

---

## Graceful degradation (the foundry contract)

SCAN-ALL is what foundry calls **only if SECURITY is installed**. Within SECURITY, the gate
itself degrades cleanly:
- A sub-skill whose external tool is missing (e.g. no `pip-audit`) runs its static checks and
  marks that lens **partial coverage** — never a false PASS.
- Foundry's side of the contract: if SECURITY is absent entirely, foundry skips the gate, ships
  markdown, and notes "SECURITY gate skipped — install the `security` plugin to enable." The
  decision to ship without a gate is always **disclosed**, never silent.

---

## Chain-gap diagnostics (don't halt silently)

The gate **walks a chain** — scan-for-pii → scan-for-secrets → scan-dependencies. When a
link cannot run (a sub-skill is unreachable, its required tool is absent, or a scope it needs is
missing), the old failure mode was to **halt or skip with no actionable guidance**. Instead,
**detect the gap and emit a diagnostic the next operator can act on**, in this exact shape:

```
missing: <which lens/tool — e.g. scan-dependencies (pip-audit not on PATH)>
recent steps: <the chain links that DID run and their status — e.g. scan-for-pii ✓, scan-for-secrets ✓>
to proceed: <the one command that closes the gap — e.g. `pip install pip-audit` then re-run /scan-all>
```

This is **detect-and-report**, never an auto-install (no network side-effects mid-audit — see the
scan-dependencies anti-patterns). The gap is already reflected in the verdict (a lens that cannot
run **cannot return PASS** for that lens; the gate returns REVIEW with the gap noted), but the
diagnostic turns a dead halt into a next action.

**Log the gap to `IN_PROGRESS.md`** (the conveyor's disaster-recovery artifact — the same ledger
foundry's coverage-loop and phase work resume from) so a halted gate is recoverable across
sessions and surfaces up the line. Append under a `## Security Gate — chain gap` heading:

```markdown
## Security Gate — chain gap
- **missing:** scan-dependencies (pip-audit unavailable)
- **recent steps:** scan-for-pii ✓ · scan-for-secrets ✓
- **to proceed:** install pip-audit, then re-run `/scan-all`
- **logged:** YYYY-MM-DD  (verdict held at REVIEW until closed)
```

This honours quality-first ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)): the gate
is never weakened to make progress — a gap is disclosed and made actionable, not papered over.

---

## When foundry invokes this

foundry's release path (before the DELIVERY station, after STORY) checks for SECURITY and, if
present, runs `/scan-all`. A **BLOCK** verdict halts DELIVERY (consistent with foundry's
"a gate without a check is forbidden" rule); **REVIEW** is surfaced up the line for a human
decision; **PASS** lets DELIVERY proceed with the report attached to the commit narrative.

---

## Self-improvement covenant

SCAN-ALL inherits the covenants of its three sub-skills. Additionally: every time a real
issue ships past a PASS verdict, the verdict rule or a sub-skill pattern is tightened so the same
class cannot pass again.

## References

The gate carries no detection logic of its own — it composes the three sub-skills. See:
[`../scan-for-pii/SKILL.md`](../scan-for-pii/SKILL.md), [`../scan-for-secrets/SKILL.md`](../scan-for-secrets/SKILL.md), [`../scan-dependencies/SKILL.md`](../scan-dependencies/SKILL.md).

## Product lifecycle (by capability)

SECURITY owns the **SECURE** phase — the security gate, distinct from foundry's **ASSURE** quality gate
that precedes it (quality ≠ security). When the **i2p** plugin is installed, drive the lifecycle from
the verdict so the marketplace product lifecycle and the status line track the BUILD ⇄ ASSURE ⇄ SECURE
loop:

```bash
# on a PASS verdict — security certified, exit the loop and advance to PUBLISH
/i2p:lifecycle done SECURE   # order-safe & idempotent — a no-op unless a lifecycle is running at SECURE

# on a REVIEW or BLOCK verdict — re-enter BUILD (loop back-edge: loop_state→BUILD, loop_pass++)
/i2p:lifecycle fail SECURE   # order-safe & idempotent — a no-op unless a lifecycle is running at SECURE
```

`fail SECURE` is the back-edge that turns the loop on a security-gate failure: the status line renders
`⇄ ×N` for the iteration count, and the **Gate failure** callout in the README tells the operator which
findings to fix in BUILD before the re-run. Degrades silently when i2p is absent. The canonical model is
`i2p/knowledge/product-lifecycle.md`.
