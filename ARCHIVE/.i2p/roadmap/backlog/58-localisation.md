---
id: 58
title: "PRESSROOM localisation — parallel-language editions"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [58] PRESSROOM localisation — parallel-language editions

**Brief Description**
Produce parallel-language editions of an article, with diagrams whose labels are externalised and
translated.

### User Stories
- AS a publisher with a global audience I WANT translated editions of an article — text AND diagram labels —
  SO THAT each locale reads natively, not just the prose.

### EARS Specification
**Ubiquitous**
- The system SHALL produce per-locale editions of an article, translating both the prose and the
  externalised diagram labels.

**Event-driven**
- WHEN a locale edition is requested THE SYSTEM SHALL render the article and re-render each figure with its
  labels swapped for the locale's translations.

**Unwanted behaviour**
- IF a diagram's labels are not externalised (hard-coded in the figure) THEN THE SYSTEM SHALL report that
  the figure cannot be localised rather than ship an untranslated figure silently.

### Acceptance Criteria
1. Given an article and a target locale with translations, When the edition is built, Then both the prose
   and the figure labels appear in that locale.
2. Given a figure with non-externalised labels, When localising, Then the limitation is disclosed.

### Implementation Notes
- Establish a label-externalisation convention for charting-matrix figures (a labels map per figure).
- Translation source is provided per locale (not machine-translated silently).
- Migrated from `plugins/pressroom/ROADMAP.md` (longer-term) under roadmap item [47].
