---
id: 8
title: "Per-job model selection — default shown, per-card override"
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "#1, #2, #3"
---

# [8] Per-job model selection — default shown, per-card override

**Brief Description**
Each job on the board carries a model assignment. The user can see the **default** model assigned to any
item and **override** it per job — switching a given job from Sonnet to Opus, or from Opus to Haiku (or
Fable) — directly on the card. The item's carriage agent then runs under the chosen model, so the human
can tune the cost↔capability trade-off job-by-job (cheap model for mechanical work, the strongest model
for the hard slice) while watching the live token tally that #3 records.

### User Stories
- AS A builder I WANT to see the default model assigned to any item SO THAT I know what will process it
  before I spend anything.
- AS A builder I WANT to set the model for any given job on the board SO THAT I can switch it from Sonnet
  to Opus, or Opus to Haiku, to match the job's difficulty and cost.
- AS A builder I WANT the carriage agent to run under the model I chose SO THAT my selection actually
  governs how the work is done and what it costs.

### EARS Specification
**Ubiquitous**
- The system SHALL display, on each item, the model currently assigned to it and whether that model is the
  default or a user override.
- The system SHALL assign every item a default model when it is created.
**Event-driven**
- WHEN the user selects a different model for an item THE SYSTEM SHALL record the override, broadcast the
  change to all connected clients, and use that model for the item's carriage agent on its next run.
- WHEN the user clears an override THE SYSTEM SHALL revert the item to its default model.
**Unwanted behaviour**
- IF the user selects a model that is not in the configured allowlist THEN THE SYSTEM SHALL refuse the
  change and leave the current assignment unchanged.
- IF an item is mid-run THEN THE SYSTEM SHALL apply a model change only to its next run, never silently
  switching a model under an in-flight agent.
**Optional feature**
- WHERE a model allowlist is configured THE SYSTEM SHALL offer only those models in the picker (default
  set: Haiku 4.5 · Sonnet 4.6 · Opus 4.8 · Fable 5).

### Acceptance Criteria
1. Given any item, Then its card shows the assigned model and a marker distinguishing "default" from
   "overridden".
2. Given an item on the default model, When the user picks a different allowlisted model, Then the card
   shows the new model as an override and the change persists after reload.
3. Given an overridden item, When the user clears the override, Then the card reverts to the default model.
4. Given an override is set, When the item's carriage agent next runs, Then it runs under the chosen model
   (verifiable in the JSONL telemetry's recorded model field).
5. Given a non-allowlisted model is requested, Then the change is refused and the prior assignment stands.

### Implementation Notes
- **Data:** each item gains a `model` field (`{default, override?}`); the resolved model is `override ??
  default`. Stored with the item; broadcast over #1's WebSocket; mutated via a new MCP/REST verb
  `set_item_model(item_id, model | null)`.
- **Default assignment:** the orchestrator picks the default per item (e.g. by task class/complexity) when
  the item is created — keep the policy in one place so it is tunable later; this entry only requires that
  a default exists and is shown.
- **Carriage agent (#3):** reads the resolved model before each run and spawns under it; records the model
  used in the telemetry line so cost is attributable per model.
- **UI (#2):** a model picker on the card (badge + dropdown), default-vs-override styling, allowlist-driven
  options; pairs naturally beside the token-cost badge so cost and model are read together.
- **Allowlist:** marketplace model IDs — `claude-haiku-4-5`, `claude-sonnet-4-6`, `claude-opus-4-8`,
  `claude-fable-5`; configurable so a project can narrow the set.

### Human Interface Test Plan
- [Model badge shows default]: navigate to canvas → find an item → verify its card shows a model badge
  marked "default" with the assigned model name.
- [Override the model]: click the model badge → verify a picker lists the allowlisted models → choose a
  different one (e.g. Opus → Haiku) → verify the badge updates and now reads "override" → reload → verify
  the override persists.
- [Clear the override]: open an overridden item's picker → choose "Use default" → verify the badge reverts
  to the default model → reload → verify reverted.
- [Override governs the run]: set an item's model, then let its carriage agent run → verify the telemetry
  line for that run records the chosen model.

### Development Plan Reference
`doc/PER_JOB_MODEL_SELECTION_PLAN.md`
