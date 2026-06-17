---
id: 106
title: "/flow pull + reframe the foundry command surface (user- vs agent-facing)"
status: COMPLETE
priority: HIGH
added: 2026-06-17
completed: 2026-06-18
depends_on: "#105"
---

# [106] /flow pull + reframe the foundry command surface (user- vs agent-facing)

**Brief Description**
Introduce the headline verb **`/flow pull`**: pull the next `.i2p/roadmap/` backlog item and drive it
through foundry's internal builder — wrapping today's `/foundry:foundry` cycle behind an intuitive,
user-facing verb. The owner's directive (epic [93], `docs/SLASH_COMMANDS.md`): *"I want to pull from the
backlog" ≠ "/foundry:foundry"* — the current build orchestrator is non-intuitive, and the owner wants
`/flow pull`.

Alongside introducing `/flow pull`, **re-examine EVERY foundry command** and classify each as user-facing
or agent-facing. The conveyor skills are internal machinery and **SHOULD NOT be typed by users**: the
`builder`, `lifecycle-states`, `handoff-protocol`, `reviewer-gate`, `value-station-handoff`,
`development-system-core`, and `founder-method` skills, plus the `ds-step-*` agents, stay agent-internal.
The user-facing surface is the small set of verbs a human runs deliberately.

### User Stories
- AS the owner I WANT `/flow pull` to take the next backlog item to product SO THAT I express intent in
  flow terms, not by invoking the foundry orchestrator by name.
- AS the owner I WANT foundry's internal conveyor skills hidden from the typed command surface SO THAT I am
  not offered machinery I am never meant to invoke directly.

### EARS Specification
**Ubiquitous**
- The `/flow pull` verb SHALL be the user-facing entry to the BUILD conveyor; `/foundry:foundry` SHALL
  remain available as the internal engine it wraps.
- Foundry's conveyor skills (`builder`, `lifecycle-states`, `handoff-protocol`, `reviewer-gate`,
  `value-station-handoff`, `development-system-core`, `founder-method`) and the `ds-step-*` agents SHALL be
  classified agent-internal and SHALL NOT be surfaced as user-typed commands.

**Event-driven**
- WHEN the user runs `/flow pull` THE SYSTEM SHALL select the next `.i2p/roadmap/` backlog item, carry it
  into the active lane, and drive it through foundry's internal builder to a delivered increment.
- WHEN the foundry command surface is reframed THE SYSTEM SHALL document, per command, whether it is
  user-facing or agent-facing.

**Unwanted behaviour**
- IF the backlog is empty or the next item is ambiguous THEN `/flow pull` SHALL refuse and ask, never guess
  which item to build.

### Acceptance Criteria
1. Given a non-empty backlog, When `/flow pull`, Then the next item advances through the foundry conveyor
   and lands as a delivered increment, with the same rigour as `/foundry:foundry`.
2. Given the reframed surface, When the foundry commands are audited, Then each is labelled user-facing or
   agent-facing, and the seven named conveyor skills + the `ds-step-*` agents are all agent-internal.
3. The item cites the owner's directive that `/foundry:foundry` is non-intuitive and `/flow pull` is the
   intended verb.

### Implementation Notes
- Depends on [105] (the flow plugin exists to host `/flow pull`).
- `/flow pull` is a thin user-facing verb that composes the existing foundry cycle — it carries the item
  (reusing the already-shipped [41] carry behaviour) then invokes the internal builder; it does not
  re-implement the conveyor.
- Owner directive (verbatim intent, `docs/SLASH_COMMANDS.md`): *"I want to pull from the backlog"* must map
  to `/flow pull`, not `/foundry:foundry`.
- Reframing is documentation + surfacing, not deletion: agent-internal skills/agents keep working; they are
  simply no longer presented as user commands.
