---
id: 32
title: "EPIC — FOUNDRY lifecycle delivery hardening"
status: PENDING
priority: HIGH
added: 2026-06-14
depends_on: "—"
---

# [32] EPIC — FOUNDRY lifecycle delivery hardening

**Brief Description**
Two gaps exposed when operating the FOUNDRY SDLC in anger. First: when a PR is open and
reviewed, the agent currently halts and leaves the user to merge manually — the interactive
"Merge PR now?" confirmation + autonomous `gh pr merge` is missing. Second: the delivery
automation changes shipped in PR #56 (AWAITING MERGE pause, post-merge COMPLETE handler,
flow-canvas sync from step-9) bypassed the SDLC entirely — no EARS, no Gherkin, no story
proof. Both gaps are closed here.

### Dependency tree

```
EPIC #32 — FOUNDRY lifecycle delivery hardening
 ├─ #33 Interactive "Merge PR now?" — confirm + `gh pr merge` on yes    [atomic]
 └─ #34 EARS + Gherkin + story proof for PR #56 lifecycle changes        → blocks on #33
```

### Development Plan Reference
`doc/FOUNDRY_DELIVERY_HARDENING_PLAN.md` (master); each child gets its own plan at GO.
