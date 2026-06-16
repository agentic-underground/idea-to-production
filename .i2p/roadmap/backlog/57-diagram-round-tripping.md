---
id: 57
title: "PRESSROOM diagram round-tripping — import & re-compose to the matrix"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [57] PRESSROOM diagram round-tripping — import & re-compose to the matrix

**Brief Description**
Import existing Mermaid / DOT / draw.io diagrams and re-compose them to the 4×9 charting matrix, flagging
legibility violations for fix.

### User Stories
- AS an author with legacy diagrams I WANT to import them and have PRESSROOM re-style them to the charting
  matrix SO THAT they match the rest of my figures and pass the legibility bar.

### EARS Specification
**Ubiquitous**
- The system SHALL import Mermaid, DOT, and draw.io sources and re-render them to the PRESSROOM charting
  matrix (dark-mode, transparent, the 4×9 lessons).

**Event-driven**
- WHEN a diagram is imported THE SYSTEM SHALL re-compose it to the matrix and report any legibility
  violations (contrast, label overlap, encoding) for the author to fix.

**Unwanted behaviour**
- IF a source uses a construct the matrix cannot express THEN THE SYSTEM SHALL disclose the lossy mapping
  rather than silently dropping nodes/edges.

### Acceptance Criteria
1. Given a Mermaid/DOT/draw.io file, When imported, Then a matrix-styled dark-mode figure is produced.
2. Given a diagram with a legibility violation, When re-composed, Then the violation is flagged with its
   location.

### Implementation Notes
- Parse each source into a common intermediate, then drive the existing charting-matrix handlers.
- Reuse the design-reviewer's legibility checks for the violation report.
- Migrated from `plugins/pressroom/ROADMAP.md` (longer-term) under roadmap item [47].
