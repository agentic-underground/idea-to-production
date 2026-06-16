---
id: 56
title: "PRESSROOM brand/style themes — pressroom.config.json"
status: PENDING
priority: LOW
added: 2026-06-16
depends_on: "—"
---

# [56] PRESSROOM brand/style themes — pressroom.config.json

**Brief Description**
A `pressroom.config.json` carrying fonts, colours, and a LaTeX/CSS theme so every artefact (PDF, slides,
web) shares one visual identity.

### User Stories
- AS a builder with a brand I WANT one config that themes every PRESSROOM output SO THAT my PDF, slides, and
  web articles look like one product, not three.

### EARS Specification
**Ubiquitous**
- The system SHALL read a project `pressroom.config.json` (fonts, colours, theme) and apply it consistently
  across every output format.

**Event-driven**
- WHEN any artefact is rendered THE SYSTEM SHALL apply the configured theme tokens (fonts/colours) to that
  format's renderer (CSS for web/slides, LaTeX preamble for PDF).

**Optional feature**
- WHERE no `pressroom.config.json` is present THE SYSTEM SHALL fall back to the built-in default theme.

### Acceptance Criteria
1. Given a `pressroom.config.json` with a brand palette, When a PDF and a web article are rendered, Then
   both use the configured fonts and colours.
2. Given no config, When rendering, Then the default theme is used with no error.

### Implementation Notes
- Define the config schema (fonts, colour roles, per-format theme hooks).
- Map tokens → CSS variables (web/slides) and → LaTeX preamble (PDF).
- Migrated from `plugins/pressroom/ROADMAP.md` (longer-term) under roadmap item [47].
