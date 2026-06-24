---
id: 67
title: "SENTINEL findings ledger — SECURITY-LEDGER.jsonl trends over time"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [67] SENTINEL findings ledger — SECURITY-LEDGER.jsonl trends over time

**Brief Description**
A machine-readable `SECURITY-LEDGER.jsonl` accumulating verdicts over time, so trends (regressions,
recurring false positives) are visible and feed self-improvement.

### User Stories
- AS a security owner I WANT each gate run appended to a ledger SO THAT I can see regressions and recurring
  false positives over time and feed them back into the rules.

### EARS Specification
**Ubiquitous**
- The system SHALL append each security-gate run's verdict + findings summary to a machine-readable
  `SECURITY-LEDGER.jsonl`.

**Event-driven**
- WHEN the security-gate completes THE SYSTEM SHALL append one ledger record (timestamp, verdict, per-lens
  counts, new vs recurring findings).

**State-driven**
- WHILE a finding recurs across runs THE SYSTEM SHALL mark it recurring in the ledger so persistent
  false-positives are visible for rule tuning.

### Acceptance Criteria
1. Given two gate runs, When the second completes, Then the ledger has two records and marks any finding
   present in both as recurring.
2. Given the ledger, When read, Then verdict and per-lens counts over time are reconstructable.

### Implementation Notes
- Append-only JSONL (one record per run); a small reducer for trend reporting.
- Feeds the self-improvement covenant (recurring FPs → rule fixes).
- Migrated from `plugins/sentinel/ROADMAP.md` (longer-term) under roadmap item [47].
