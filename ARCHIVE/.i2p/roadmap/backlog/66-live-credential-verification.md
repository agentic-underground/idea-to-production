---
id: 66
title: "SENTINEL live-credential verification — confirm-before-BLOCK (opt-in)"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [66] SENTINEL live-credential verification — confirm-before-BLOCK (opt-in)

**Brief Description**
Opt-in, sandboxed: confirm whether a detected key is still active before classifying BLOCK, reducing
rotation churn on already-dead secrets.

### User Stories
- AS a security owner I WANT detected keys checked for whether they are still live before they BLOCK SO THAT
  I'm not forced to rotate already-dead secrets.

### EARS Specification
**Optional feature**
- WHERE live-credential verification is enabled THE SYSTEM SHALL, in a sandbox, probe a detected key's
  validity before finalising its severity.

**Event-driven**
- WHEN a key is confirmed inactive THE SYSTEM SHALL downgrade it from BLOCK (still reported as a finding,
  noted dead) and keep an active key at BLOCK.

**Unwanted behaviour**
- IF verification is disabled or the probe is inconclusive THEN THE SYSTEM SHALL treat the key as live
  (BLOCK) — fail safe, never assume dead.

### Acceptance Criteria
1. Given verification enabled and a dead key, When scanned, Then it is reported but not a BLOCK.
2. Given verification disabled or inconclusive, When a key is found, Then it remains a BLOCK.

### Implementation Notes
- Opt-in only; sandboxed, rate-limited probes per provider; never exfiltrate the key.
- Default OFF (fail-safe to BLOCK).
- Migrated from `plugins/sentinel/ROADMAP.md` (longer-term) under roadmap item [47].
