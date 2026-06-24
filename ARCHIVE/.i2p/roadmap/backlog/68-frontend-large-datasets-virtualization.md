---
id: 68
title: "FRONTEND large datasets & virtualization — windowing without losing a11y"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [68] FRONTEND large datasets & virtualization — windowing without losing a11y

**Brief Description**
Browse grids, tables, and spreadsheet-dense paradigms need windowing/virtualization to stay fast and
accessible at thousands of rows. Must preserve keyboard roving, focus management, and reduced layout shift
under virtualization. Affects: `browse-grid`, a future `data-table`, and `inline-text-edit` at scale.

### User Stories
- AS a user of a data-dense grid I WANT thousands of rows to scroll smoothly SO THAT the UI stays fast,
  and I WANT keyboard navigation + focus to keep working SO THAT virtualization doesn't break accessibility.

### EARS Specification
**Ubiquitous**
- The system SHALL render large row sets via windowing/virtualization while preserving keyboard roving and
  focus management.

**Event-driven**
- WHEN a virtualized row scrolls out of and back into view THE SYSTEM SHALL restore its focus/selection
  state and avoid layout shift.

**Unwanted behaviour**
- IF virtualization would drop a focused row from the DOM THEN THE SYSTEM SHALL keep focus reachable (e.g.
  retain/re-bind it) rather than lose the user's place.

### Acceptance Criteria
1. Given thousands of rows, When scrolled, Then frame rate stays smooth and layout shift is minimal.
2. Given keyboard navigation, When rows virtualize in/out, Then roving focus and selection are preserved.

### Implementation Notes
- Applies to `browse-grid`, a future `data-table`, and `inline-text-edit`.
- Preserve the design system's keyboard/focus/INTENT conventions under windowing.
- Migrated from `plugins/foundry/skills/frontend/resources/ROADMAP.md` (§1) under roadmap item [47].
