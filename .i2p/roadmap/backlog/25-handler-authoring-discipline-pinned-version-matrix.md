---
id: 25
title: "Handler-authoring discipline — pinned version matrix + FORBIDDEN list"
status: PENDING
priority: MEDIUM
added: 2026-06-14
depends_on: "— (atomic; PR-B)"
---

# [25] Handler-authoring discipline — pinned version matrix + FORBIDDEN list

**Brief Description**
A new knowledge doc `handler-authoring-discipline.md` — the antidote to version/tooling thrash (rust+tauri,
typst): every new handler bakes in a **pinned version matrix**, a **FORBIDDEN list**, the KAIZEN covenant,
and the four-wave build pipeline — generalised from `rust-webapp-rollout/references/00-MANIFEST.md`.

### EARS Specification
**Ubiquitous**
- The system SHALL require every new value-handler to carry a pinned version matrix + a FORBIDDEN list.

### Acceptance Criteria
1. The discipline doc exists and is referenced by the handler-build pipeline + #24's BUILD path.
2. A handler authored under it carries a pinned matrix + FORBIDDEN list.

### Implementation Notes
- Generalise `plugins/foundry/skills/rust-webapp-rollout/references/00-MANIFEST.md`. The typst pain becomes a
  separate SELF_IMPROVEMENT issue to harden `pressroom`'s PDF path. Plan §2c.

### Development Plan Reference
`doc/HANDLER_AUTHORING_DISCIPLINE_PLAN.md`
