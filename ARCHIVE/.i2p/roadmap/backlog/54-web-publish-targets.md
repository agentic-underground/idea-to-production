---
id: 54
title: "PRESSROOM web-publish targets — dev.to / Hashnode / static-site"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [54] PRESSROOM web-publish targets — dev.to / Hashnode / static-site

**Brief Description**
Push finished articles to dev.to, Hashnode, or a static-site repo — front-matter generation, canonical
URLs, cover-image hookup — with a dry-run preview before anything is published.

### User Stories
- AS a writer I WANT to publish a finished article to my blog platform from PRESSROOM SO THAT I don't
  re-format front-matter and re-upload images by hand.
- AS a cautious publisher I WANT a dry-run preview SO THAT I see exactly what will be posted before it goes
  live.

### EARS Specification
**Ubiquitous**
- The system SHALL publish a finished article to a configured web target (dev.to, Hashnode, or a
  static-site repo), generating the target's front-matter and wiring canonical URL + cover image.

**Event-driven**
- WHEN a publish is requested THE SYSTEM SHALL first produce a dry-run preview of the exact payload and
  require confirmation before the live post.

**Unwanted behaviour**
- IF the target API token is missing or invalid THEN THE SYSTEM SHALL stop with a clear message and publish
  nothing.

### Acceptance Criteria
1. Given a finished article and a configured target, When publish runs, Then a dry-run preview is shown and
   the live post happens only after confirmation.
2. Given a published article, When inspected on the target, Then its front-matter, canonical URL, and cover
   image match the source.

### Implementation Notes
- Per-target adapters (dev.to/Hashnode APIs; static-site = commit to a repo).
- Tokens are runtime secrets, never committed.
- Migrated from `plugins/pressroom/ROADMAP.md` (mid-term) under roadmap item [47].
