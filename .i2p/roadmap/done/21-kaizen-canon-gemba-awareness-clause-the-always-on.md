---
id: 21
title: "KAIZEN-canon GEMBA awareness clause — the always-on instinct"
status: COMPLETE
priority: MEDIUM
added: 2026-06-14
completed: 2026-06-17
depends_on: "— (atomic; PR-A)"
---

# [21] KAIZEN-canon GEMBA awareness clause — the always-on instinct

**Brief Description**
Add a short **GEMBA reflex** clause to `KAIZEN.md` (canonical root) + `kaizen-covenant.md`: when work hits a
gap/failure/thrash, go and see — capture it and raise it as feedback (SELF → auto PR; GEMBA → consented
issue). Re-synced byte-identical into all 9 plugins via `verify-prereqs.sh --fix` and injected every session
via `inject-kaizen.sh`. **This is what makes the reflex fire without being asked.**

### EARS Specification
**Ubiquitous**
- The system SHALL carry the GEMBA-reflex clause in the canonical KAIZEN canon, byte-identical across all 9 plugins.
**Event-driven**
- WHEN a session starts THE SYSTEM SHALL inject the GEMBA-reflex awareness (via `inject-kaizen.sh`).

### Acceptance Criteria
1. `bash scripts/verify-prereqs.sh` green (KAIZEN canon byte-identical across 9 plugins, check N).
2. A fresh session shows the GEMBA-reflex clause injected.

### Implementation Notes
- Canonical-copy promise: edit the canon, re-sync all copies. Plan §1e.

### Development Plan Reference
`doc/GEMBA_AWARENESS_CLAUSE_PLAN.md`
