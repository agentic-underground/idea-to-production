---
id: 53
title: "PRESSROOM citations & bibliography — references.bib + notes"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [53] PRESSROOM citations & bibliography — references.bib + notes

**Brief Description**
When an article references sources, manage a `references.bib` and render footnotes/endnotes consistently
across markdown, PDF, and HTML.

### User Stories
- AS an author I WANT to cite sources once and have them rendered correctly in every output format SO THAT
  I don't hand-maintain footnotes per channel.

### EARS Specification
**Ubiquitous**
- The system SHALL manage a `references.bib` and render citations + a bibliography consistently across
  markdown, PDF, and HTML outputs.

**Event-driven**
- WHEN an article cites a key present in `references.bib` THE SYSTEM SHALL render the in-text citation and
  the corresponding footnote/endnote and bibliography entry in the active format's idiom.

**Unwanted behaviour**
- IF a cited key is missing from `references.bib` THEN THE SYSTEM SHALL surface the unresolved citation,
  never silently drop it or emit a dangling marker.

### Acceptance Criteria
1. Given an article citing `[@key]` with `key` in `references.bib`, When rendered to PDF and HTML, Then
   both show a consistent in-text citation and a bibliography entry.
2. Given a citation whose key is absent, When rendered, Then the build reports the unresolved key.

### Implementation Notes
- Pandoc citeproc (or equivalent) for cross-format citation rendering.
- Define where `references.bib` lives relative to the article source.
- Migrated from `plugins/pressroom/ROADMAP.md` (mid-term) under roadmap item [47].
