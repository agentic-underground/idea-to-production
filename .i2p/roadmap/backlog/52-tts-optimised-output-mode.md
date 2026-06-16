---
id: 52
title: "PRESSROOM TTS-optimised output — format=audio-script"
status: PENDING
priority: HIGH
added: 2026-06-16
depends_on: "—"
---

# [52] PRESSROOM TTS-optimised output — format=audio-script

**Brief Description**
Promote the writer's existing TTS hinting (flowing prose, no inline headers, em-dash pacing) to a
first-class `format=audio-script` target for narration pipelines — output shaped to be read aloud rather
than scanned on a page.

### User Stories
- AS a creator I WANT an article rendered as a narration script SO THAT I can feed it to a TTS pipeline
  without hand-stripping headers and list syntax.

### EARS Specification
**Ubiquitous**
- The system SHALL produce a narration-optimised script (`format=audio-script`): flowing prose, no inline
  markdown headers/list markers, paced for speech.

**Event-driven**
- WHEN `format=audio-script` is requested THE SYSTEM SHALL transform headers into spoken transitions,
  expand or drop figure references that cannot be read aloud, and normalise punctuation for pacing.

**Unwanted behaviour**
- IF the source contains content that cannot be voiced (a raw table, a code block) THEN THE SYSTEM SHALL
  summarise or annotate it for narration rather than emit literal markup into the script.

### Acceptance Criteria
1. Given an article, When `format=audio-script` runs, Then the output contains no markdown header/list
   syntax and reads as continuous prose.
2. Given a figure reference, When the script is produced, Then it is rendered as a spoken description or
   omitted, never left as a raw image link.

### Implementation Notes
- Build on the writer skill's existing audio-script hinting; add the explicit `format=audio-script` target.
- Define the header→transition and figure→narration transforms.
- Migrated from `plugins/pressroom/ROADMAP.md` (near-term) under roadmap item [47].
