---
id: 16
title: "EPIC — KAIZEN UPLIFT: GEMBA feedback reflex + missing-handler decision gate"
status: COMPLETE
priority: HIGH
added: 2026-06-14
completed: 2026-06-17
depends_on: "—"
---

# [16] EPIC — KAIZEN UPLIFT: GEMBA feedback reflex + missing-handler decision gate

**Brief Description**
When an idea-to-production plugin hits something it can't finish well — a missing value-handler, a tooling
thrash, a reviewer BLOCK, a failure — it should *instinctively* capture the event and route it into the
GitHub issue→PR feedback loop, so the fix lands once, upstream, for everyone. This epic weaves that **GEMBA
feedback reflex** into the fabric (PR-A) and adds the **missing-capability decision gate** that turns a
capability gap into a choice instead of a grind (PR-B). It generalises what we did by hand this session for
the token-fairness scheduler (issue + draft PR + `docs/internal/token-fairness-learnings/`).

### User Stories
- AS the marketplace I WANT to capture-and-file every gap/failure/thrash at the place it broke SO THAT fixes
  land once, upstream, for the whole community — not re-solved per project.
- AS a builder hitting a missing value-handler I WANT a 3-way decision (build the handler · MVP with existing ·
  both) SO THAT a capability gap is a choice, not a silent degrade or a grind.
- AS any agent I WANT the reflex to be always-on awareness (the KAIZEN canon) SO THAT it fires without being asked.

### EARS Specification (epic-level; per-child EARS in #17–#26)
**Ubiquitous**
- The system SHALL classify every captured learning by **target** — SELF_IMPROVEMENT (this repo, auto),
  GEMBA (a sibling repo, ask-first), or external (local ledger only).
**Event-driven**
- WHEN work hits a gap it cannot finish, a failure, or a painful thrash THE SYSTEM SHALL capture it
  (incident + proposed-solutions) and route it to the issue→PR loop per its target.
- WHEN the conveyor needs a value-handler that is not in the pool THE SYSTEM SHALL pause and surface the 3-way gate.
**Unwanted behaviour**
- IF a learning targets a sibling/cross-repo (GEMBA) THEN THE SYSTEM SHALL ask before filing; IF same-repo
  (SELF_IMPROVEMENT) it MAY file automatically — but SHALL never self-merge (merge governance still gates).
- IF an identical issue already exists THEN THE SYSTEM SHALL dedup (search by stable slug) and not file again.

### Acceptance Criteria
1. Given a captured learning, Then it is filed to the correct repo per its target, deduped, and recorded in
   `.i2p/learnings.jsonl` (open→filed), with cross-repo filing gated on consent.
2. Given a roadmap item with an unknown stack, Then `builder-lead` stops at the 3-way gate (no silent degrade);
   option BOTH produces an MVP plan + a filed handler issue + a DEFERRED "Create handler-<stack>" item.
3. Given a fresh session, Then the GEMBA-reflex clause is injected (always-on awareness), byte-identical across all 9 plugins.

### Implementation Notes
- **Cross-plugin**: PR-A in MISSION-CONTROL (reuses incident→postmortem→action-items→iterate); PR-B in
  FOUNDRY + IDEATOR. Reuse-don't-reinvent per the plan's "What already exists" inventory.
- **Net-new (small, sharp)**: there is no `gh issue create` anywhere yet; no umbrella-org identity; the
  missing-handler path doesn't pause — these three seams are the work.
- **Token safety**: large cycle — stamp `tf plan --class large`, bracket plan-open/close; gate any fan-out.
- Full spec, decisions (already made — do not re-ask), and the worked references: `docs/internal/KAIZEN_UPLIFT_PLAN.md`.

### Development Plan Reference
`docs/internal/KAIZEN_UPLIFT_PLAN.md` (the master plan); each child gets its own `doc/<TITLE>_PLAN.md` at GO.
