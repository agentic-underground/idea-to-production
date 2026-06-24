---
id: 72
title: "FRONTEND element-registry growth — new registry elements"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [72] FRONTEND element-registry growth — new registry elements

**Brief Description**
Candidate future elements: data-table (editable, sortable, virtualized), date/time picker, relationship
explorer, hierarchical/tree selector, rich-text editor, file uploader, map/geographic picker,
levers/sliders, and a chart family. Each ships as a registry page in the established anatomy and is added to
`elements/README.md` so `-help` stays current.

### User Stories
- AS a builder I WANT more ready-made registry elements SO THAT I can compose richer data-bound UIs without
  authoring each control from scratch.

### EARS Specification
**Ubiquitous**
- The system SHALL grow the element registry with new elements, each following the established registry-page
  anatomy and INTENT-marker conventions.

**Event-driven**
- WHEN a new element is added THE SYSTEM SHALL register it as a registry page and add it to
  `elements/README.md` so `-help` lists it.

**State-driven**
- WHILE an element is in the registry THE SYSTEM SHALL keep it discoverable via `-help` and consistent with
  the design system's accessibility/dark-mode/keyboard rules.

### Acceptance Criteria
1. Given a new element, When added, Then it has a registry page in the standard anatomy and appears in
   `-help`.
2. Given any registry element, When inspected, Then it meets the design-system accessibility/keyboard rules.

### Implementation Notes
- Candidate set: data-table, date/time picker, relationship explorer, tree selector, rich-text editor, file
  uploader, map picker, levers/sliders, chart family.
- Each is its own incremental deliverable; this item is the umbrella for registry growth.
- Migrated from `plugins/foundry/skills/frontend/resources/ROADMAP.md` (§5) under roadmap item [47].
