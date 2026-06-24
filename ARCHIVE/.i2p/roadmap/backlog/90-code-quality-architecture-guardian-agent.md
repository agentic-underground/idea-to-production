---
id: 90
title: "code-quality v2.0 — architecture-guardian-agent (boundary enforcement)"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "#87"
---

# [90] code-quality v2.0 — architecture-guardian-agent (boundary enforcement)

**Brief Description**
An `architecture-guardian-agent` that continuously enforces architectural boundaries.

### User Stories
- AS an architect I WANT boundary violations caught continuously SO THAT the architecture doesn't erode
  between deliberate reviews.

### EARS Specification
**Ubiquitous**
- The system SHALL enforce the project's declared architectural boundaries on an ongoing basis.

**Event-driven**
- WHEN a change crosses a declared boundary (e.g. a layer importing inward-only code the wrong way) THE
  SYSTEM SHALL flag the violation.

### Acceptance Criteria
1. Given a declared boundary, When a change violates it, Then the violation is flagged with the offending
   dependency.
2. Given a boundary-respecting change, When checked, Then it passes.

### Implementation Notes
- Part of the v2.0 multi-agent pipeline [87]; needs a way to declare boundaries (config/ADR).
- Migrated from `plugins/foundry/skills/code-quality/DEPLOYMENT.md` (Roadmap v2.0) under roadmap item [47].
