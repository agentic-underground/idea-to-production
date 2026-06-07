---
name: phase-sensor
description: >
  DEV_SYSTEM Phase Sensor for FOUNDRY. Detects the current development phase
  of each IN PROGRESS ROADMAP feature by inspecting existing artifacts, then
  installs the skill for that phase automatically. Triggered via PostToolUse hook
  on ROADMAP.md edits. Also invocable directly as /phase-sensor.
---

# PHASE-SENSOR

Keeps FOUNDRY's DEV_SYSTEM self-applying: when a feature advances, the right
skill for the next unit of work is automatically installed and ready.

## How it works

1. Reads `ROADMAP.md` for features with `STATUS: IN PROGRESS`.
2. For each, inspects artifact presence to determine the current incomplete phase.
3. Looks up `skills/phase-sensor/phases/phase-N.md` for that phase.
4. Extracts the embedded `SKILL.md` and installs it under `skills/<name>/`.
5. Commits the new skill to the project and logs the transition.

## ROADMAP ↔ sentinel-state cross-check

Before phase detection, the sensor cross-checks each ROADMAP item's declared `STATUS:`
against its terminal completion sentinel in the **sentinel audit log**
(`doc/FOUNDRY_PLAN.md` under `## Sentinel Audit Log`, per
`knowledge/protocols/context-sentinel.md`):

- `STATUS: COMPLETE` must be witnessed by `SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}`.
- `STATUS: AWAITING MERGE` must be witnessed by `SENTINEL::AWAITING_MERGE::ROADMAP-{N}`
  (or its superseding `DELIVERY_COMPLETE`).

On a mismatch it emits a specific `WARN [N] …` line and a non-zero exit — **detect-only,
never auto-fix** (an unwitnessed COMPLETE may mean the item never actually reached `main`).
It is **silent** when records agree, or when there is no audit log to contradict.

## Phase detection table

| Phase | Name | Artifact marking phase complete |
|-------|------|---------------------------------|
| 0 | Write the Plan | `doc/[SLUG]_PLAN.md` (non-empty) |
| 1 | EARS Specification | `### EARS-` headers in `doc/SPECIFICATION.ears.md` |
| 2 | Feature Documentation | Any `*.feature` in `doc/features/` |
| 3 | Test Code | Any `test-*.bats` in `tests/` |
| 5 | Implementation | Phase 3 done (phase 4 is transient) |
| 6+ | Human-driven | Not detectable from static artifacts |

## Invocation

**Automatic:** PostToolUse hook fires on every `Edit`/`Write`. Fast-exits in <1ms
if the modified file is not `ROADMAP.md`.

**Manual:** `bash ${CLAUDE_PLUGIN_ROOT}/skills/phase-sensor/scripts/check-phase.sh`

## Implementation principles

All skills installed by the phase-sensor operate under FOUNDRY's universal implementation
covenant: `${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/implementation-covenant.md`. Agents are not expected to rediscover these
rules from context — they inherit them by reference. Every phase skill may read
`PRINCIPLE_PHILOSOPHY.md` at the start of its work to establish the invariants it must honour.

## Adding a new phase

Create `skills/phase-sensor/phases/phase-N.md` following the format of existing phase
files. The script discovers it automatically — no code change required.

## Logs

Appends to the project-local `.claude/cache/phase-sensor.log` with timestamps, feature references,
phase detected, prerequisites evaluated, and skills installed.
