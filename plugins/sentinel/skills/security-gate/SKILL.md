---
name: security-gate
description: >
  The consolidated pre-release security gate. Runs SENTINEL's three audits in parallel —
  pii-audit (personal data), secret-scan (credentials), dependency-audit (supply chain) — then
  merges them into a single SECURITY-REPORT.md with one overall verdict: PASS, REVIEW, or BLOCK.
  Trigger with /security-gate [scope]. This is the entry point the foundry plugin calls as its
  SECURITY station before DELIVERY when SENTINEL is installed; it is equally useful standalone
  before any release or open-sourcing. Degrades gracefully: if a sub-skill or its tooling is
  unavailable, it reports the gap rather than silently passing.
metadata:
  type: orchestrator
  output: SECURITY-REPORT.md (verdict PASS | REVIEW | BLOCK)
  composes: [pii-audit, secret-scan, dependency-audit]
model: inherit
---

# SECURITY-GATE

One command, one report, one verdict. SECURITY-GATE is the front door to SENTINEL: it fans out
the three audit lenses, consolidates their findings, and returns a single gating decision a
release pipeline (or a human) can act on.

---

## Quick start

```bash
/security-gate            # full gate: PII + secrets + dependencies → SECURITY-REPORT.md
/security-gate quick      # working-tree PII + secrets only (skip history & deps) — fast pre-commit
/security-gate ./service  # gate a specific subproject
```

---

## How it runs

Spawn the three audits **in parallel** (they share no state):

```
            ┌─ pii-audit         (personal data)   ─┐
/security-gate ─┼─ secret-scan       (credentials)    ─┼─▶ consolidate ─▶ verdict
            └─ dependency-audit  (supply chain)    ─┘
```

Each sub-skill returns its findings section in the shared SENTINEL finding format. SECURITY-GATE
then:
1. **Merges** the three sections under one report.
2. **Deduplicates** overlaps (e.g. a connection string caught by both pii-audit and secret-scan
   → listed once, "confirmed by both").
3. **Computes the overall verdict** (below).
4. **Writes** `SECURITY-REPORT.md`.

---

## Optional 4th lens — SAST via the Semgrep MCP

SENTINEL ships a `semgrep` MCP server ([`../../.mcp.json`](../../.mcp.json), package `semgrep-mcp`,
run via `uvx`; approve it once with `claude mcp list`). When present it adds a **static application
security testing (SAST)** lens through the `mcp__semgrep__*` tools — code-level vulnerability
patterns (injection, unsafe deserialisation, path traversal, weak crypto, taint flows) that the
SCA / secret / PII lenses do not cover. Scan the changed source, fold findings into the **Supply
Chain / Code** section, and apply the same severity → verdict rule. It is **optional and additive**:
if the server is not approved or `uvx` is unavailable, the gate runs its three core lenses and
records SAST as a coverage gap (no silent PASS).

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
| Personal data (pii-audit)   | ✓/⚠/✗ | … | full/partial |
| Credentials (secret-scan)   | ✓/⚠/✗ | … | tree+history+artefacts |
| Supply chain (dependency-audit) | ✓/⚠/✗ | … | advisory-tool / static-only |

## Findings — Personal Data
## Findings — Credentials
## Findings — Supply Chain
## Remediation (prioritised: CRITICAL → HIGH → hygiene)
## Coverage & Gaps   (what was NOT scanned, and why — tools missing, scope limits)
## Appendix          (files/manifests scanned, exclusions applied)
```

---

## Graceful degradation (the foundry contract)

SECURITY-GATE is what foundry calls **only if SENTINEL is installed**. Within SENTINEL, the gate
itself degrades cleanly:
- A sub-skill whose external tool is missing (e.g. no `pip-audit`) runs its static checks and
  marks that lens **partial coverage** — never a false PASS.
- Foundry's side of the contract: if SENTINEL is absent entirely, foundry skips the gate, ships
  markdown, and notes "SECURITY gate skipped — install the `sentinel` plugin to enable." The
  decision to ship without a gate is always **disclosed**, never silent.

---

## When foundry invokes this

foundry's release path (before the DELIVERY station, after STORY) checks for SENTINEL and, if
present, runs `/security-gate`. A **BLOCK** verdict halts DELIVERY (consistent with foundry's
"a gate without a check is forbidden" rule); **REVIEW** is surfaced up the line for a human
decision; **PASS** lets DELIVERY proceed with the report attached to the commit narrative.

---

## Self-improvement covenant

SECURITY-GATE inherits the covenants of its three sub-skills. Additionally: every time a real
issue ships past a PASS verdict, the verdict rule or a sub-skill pattern is tightened so the same
class cannot pass again.

## References

The gate carries no detection logic of its own — it composes the three sub-skills. See:
[`../pii-audit/SKILL.md`](../pii-audit/SKILL.md), [`../secret-scan/SKILL.md`](../secret-scan/SKILL.md), [`../dependency-audit/SKILL.md`](../dependency-audit/SKILL.md).

## Product lifecycle (by capability)

When the gate returns a **PASS** verdict (no unresolved BLOCK/REVIEW), and the **i2p** plugin is installed, mark the **ASSURE** phase done so the marketplace
product lifecycle and the status line advance to PUBLISH:

```bash
/i2p-lifecycle done ASSURE   # order-safe & idempotent — a no-op unless a lifecycle is running at ASSURE
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
