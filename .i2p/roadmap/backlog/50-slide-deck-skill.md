---
id: 50
title: "PRESSROOM slide-deck skill — article/outline → presentation deck"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [50] PRESSROOM slide-deck skill — article/outline → presentation deck

**Brief Description**
A `slide-deck` skill that generates presentation decks from an article or outline: Marp markdown →
HTML/PDF, or Beamer for LaTeX users. It reuses `diagram-studio` for figures sized to 16:9 and the
writer's narrative discipline (one idea per slide, a hook on every section). It surfaces as a
`format=slides` target for `/publish`.

### User Stories
- AS a builder I WANT to turn a finished article into a slide deck SO THAT I can present the same material
  without re-authoring it.
- AS a presenter I WANT figures sized for 16:9 and one idea per slide SO THAT the deck reads cleanly on a
  projector.

### EARS Specification
**Ubiquitous**
- The system SHALL produce a presentation deck from an article or outline as another `/publish` format
  (`format=slides`).

**Event-driven**
- WHEN `format=slides` is requested THE SYSTEM SHALL render Marp markdown to HTML/PDF (or Beamer when the
  project targets LaTeX), embedding diagram-studio figures sized to 16:9.

**Optional feature**
- WHERE a Beamer/LaTeX toolchain is configured THE SYSTEM SHALL offer Beamer output in addition to Marp.

### Acceptance Criteria
1. Given an article, When `/publish format=slides` runs, Then a deck (HTML or PDF) is produced with one
   primary idea per slide and a hook on each section.
2. Given a section that references a figure, When the deck is built, Then the figure is rendered via
   diagram-studio at a 16:9-appropriate size.

### Implementation Notes
- New skill `plugins/pressroom/skills/slide-deck/`; wire `format=slides` into `/pressroom:publish`.
- Reuse `diagram-studio` for figures and the writer's narrative rules.
- Marp CLI (markdown→HTML/PDF) primary; Beamer optional behind a LaTeX-present check.
- Migrated from `plugins/pressroom/ROADMAP.md` (near-term) under roadmap item [47].
