---
id: 51
title: "PRESSROOM multi-format export — docx / epub / html via pandoc"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [51] PRESSROOM multi-format export — docx / epub / html via pandoc

**Brief Description**
A `format=` matrix beyond markdown/pdf: `docx`, `epub`, and `html` (single-file, styled) via a
pandoc-backed renderer, so one PRESSROOM source reaches every channel. (PRESSROOM already ships a
`handler-docx` for Word; this generalises the export surface across formats from one source.)

### User Stories
- AS a publisher I WANT to export one article as docx, epub, or single-file HTML SO THAT I reach every
  channel without re-authoring per format.

### EARS Specification
**Ubiquitous**
- The system SHALL render a PRESSROOM article to `docx`, `epub`, and single-file styled `html` from the
  same source, selected by a `format=` argument.

**Event-driven**
- WHEN a supported `format=` is requested THE SYSTEM SHALL invoke the pandoc-backed renderer with the
  matching template and embed figures/assets inline where the format requires it (e.g. single-file html).

**Unwanted behaviour**
- IF pandoc (or a required format engine) is absent THEN THE SYSTEM SHALL report the missing prerequisite
  and which formats remain available, never emit a corrupt or empty file.

### Acceptance Criteria
1. Given an article, When `format=docx|epub|html` is requested, Then a valid file of that type is produced
   from the one source.
2. Given a single-file `html` request, When rendered, Then images/styles are inlined so the file is
   self-contained.

### Implementation Notes
- Extend `/pressroom:publish` with the `format=` matrix; route to a pandoc renderer.
- Reuse `handler-docx`'s reference-doc/accessibility discipline for the docx path.
- Declare pandoc + per-format engines in the check manifest.
- Migrated from `plugins/pressroom/ROADMAP.md` (near-term) under roadmap item [47].
