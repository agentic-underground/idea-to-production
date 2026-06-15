---
id: 41
title: "Repurpose /mission-control:flow → value-carry + report"
status: PENDING
priority: HIGH
added: 2026-06-15
depends_on: "#1 (server verbs), #42 (tree source)"
---

# [41] Repurpose /mission-control:flow → value-carry + report

**Brief Description**
With the web board removed (item [39]), retarget the existing `/mission-control:flow` command from
"launch the web board" to the lightweight **value-carry + report** verb the owner wants instead of reaching
for the full FOUNDRY orchestrator. `/flow carry <item> [to <stage>]` moves an item
`roadmap → backlog → do → doing → done` and reports **who is DOING / WHAT / cost**; `/flow report` prints
the current value-flow state.

### User Stories
- AS the owner I WANT a simple verb to carry a value item to its next stage SO THAT I don't reach for the
  heavyweight FOUNDRY cycle just to advance flow.
- AS the owner I WANT each carry to record who/what/cost SO THAT the current state of value flow is always
  reportable.

### EARS Specification
**Event-driven**
- WHEN the user runs `/flow carry <item> to <stage>` THE SYSTEM SHALL move the item file between
  `.i2p/roadmap/` folders, update its `status:` front-matter, and record who/what/cost via the flow-server
  telemetry verbs.
- WHEN the user runs `/flow report` THE SYSTEM SHALL render items grouped by stage with who/what/cost.

**Unwanted behaviour**
- IF the target stage is invalid or the item is ambiguous THEN THE SYSTEM SHALL refuse and ask, never guess.

### Acceptance Criteria
1. Given a backlog item, When `/flow carry N to doing`, Then its file moves to `doing/`, `status:` becomes
   IN PROGRESS, and a telemetry record (agent + activity + cost) is written.
2. Given `/flow report`, Then the output groups items by stage and shows who/what/cost.
3. The old "launch web board" behaviour is gone; `off`/board subcommands are removed or repurposed.

### Implementation Notes
- Edit `plugins/mission-control/skills/flow/SKILL.md` + `commands/flow.md`.
- Use the flow-server stage-transition (`post_status`, `set_wait_go`) + telemetry (`append_spend`,
  `annotate`, `append_sysmsg`) verbs; reflect the move in the `.i2p/roadmap/` tree.
- Align with the carriage-agent who/what/cost model.
