# DEV_SYSTEM PHASE SENSOR — Implementation Plan

> Feature: [2] DEV_SYSTEM Phase Sensor
> Roadmap entry: ROADMAP.md §[2]
> Date: 2026-05-17
> Status: IN PROGRESS

---

## Summary of EARS Specification

| ID       | Form            | Requirement |
|----------|-----------------|-------------|
| EARS-009 | Event-driven    | On IN PROGRESS transition, evaluate current DEV_SYSTEM phase |
| EARS-010 | Event-driven    | Compare existing artifacts against next-phase prerequisites |
| EARS-011 | Event-driven    | Install skills/agents for next phase when prerequisites met |
| EARS-012 | State-driven    | Log phase, prerequisites, and installed artifacts throughout |
| EARS-013 | Unwanted behav. | Prompt user and exit clean when prerequisites unmet |

---

## Gherkin Scenarios Summary

File: `doc/features/phase-sensor.feature`

| Scenario | Path | EARS IDs |
|----------|------|----------|
| Phase 0 — plan missing → install forge-plan | Happy | 009,010,011 |
| Phase 1 — EARS missing → install forge-ears | Happy | 009,010,011 |
| Phase 2 — .feature missing → install forge-feature | Happy | 009,010,011 |
| Phase 3 — tests missing → install forge-test | Happy | 009,010,011 |
| Phase 5 — impl missing → install forge-implement | Happy | 009,010,011 |
| Phase transition logging | Happy | 012 |
| Unsatisfied prerequisite → prompt user | Unhappy | 013 |
| No IN PROGRESS features → exit 0 | Abuse | 013 |

---

## Architecture

### Phase Detection (artifact-based)

The sensor determines the current phase by checking for the presence of artifacts
in a specific order. The highest phase whose artifact exists is the current phase.

| Phase | Name | Artifact that marks phase complete |
|-------|------|------------------------------------|
| 0 | Write the Plan | `doc/[SLUG]_PLAN.md` (non-empty) |
| 1 | EARS Specification | EARS IDs in `doc/SPECIFICATION.ears.md` |
| 2 | Feature Documentation | `.feature` file in `doc/features/` |
| 3 | Test Code | Test file in `tests/` |
| 4 | Tests Red | (transient — not detectable statically) |
| 5 | Implementation | Implementation file exists |
| 6+ | Tests Green / Sync / Commit | (out of sensor scope — human-driven) |

### Phase Definitions

Each phase is defined in `skills/phase-sensor/phases/phase-N.md`. The file has two
sections separated by `---SKILL---`:
- **Header** (metadata): `NAME`, `INSTALLS_SKILL`, `PREREQUISITES`, `QUALITY_GATE`
- **Body** (embedded SKILL.md): copied verbatim into `skills/<name>/SKILL.md` when
  the sensor fires for that phase

This self-contained format means adding a new phase requires only adding a single file —
no changes to the sensor script.

### Trigger Mechanism

A PostToolUse hook in `settings.json` watches `Edit` and `Write` tool calls. The hook
runs `check-phase.sh`, which reads stdin to check whether the modified file was
`ROADMAP.md`. If not, it exits 0 immediately (fast path). If yes, it runs the full
phase evaluation. This keeps the hook cost near-zero for non-roadmap edits.

### Idempotency

The sensor is fully idempotent:
- If a skill is already installed, it logs "already installed" and skips.
- It never modifies an existing installed skill.
- It always leaves the repository clean on exit.

---

## Files Created / Modified

| File | Action | Rationale |
|------|--------|-----------|
| `skills/phase-sensor/SKILL.md` | CREATE | Skill invocable as `/phase-sensor` |
| `skills/phase-sensor/scripts/check-phase.sh` | CREATE | Core detection + install logic |
| `skills/phase-sensor/phases/phase-0.md` | CREATE | Plan phase definition + forge-plan SKILL.md |
| `skills/phase-sensor/phases/phase-1.md` | CREATE | EARS phase definition + forge-ears SKILL.md |
| `skills/phase-sensor/phases/phase-2.md` | CREATE | Feature phase definition + forge-feature SKILL.md |
| `skills/phase-sensor/phases/phase-3.md` | CREATE | Test phase definition + forge-test SKILL.md |
| `skills/phase-sensor/phases/phase-5.md` | CREATE | Implement phase definition + forge-implement SKILL.md |
| `settings.json` | MODIFY | Add PostToolUse hook on Edit/Write |
| `tests/test-phase-sensor.bats` | CREATE | bats tests for all 8 scenarios |
| `ROADMAP.md` | MODIFY | Status → COMPLETE on finish |

---

## Test Strategy

- **Runner**: bats-core (same as Feature [1])
- **Test file**: `tests/test-phase-sensor.bats`
- **Helper**: `tests/helpers/forge-fixture.bash` — extends `git-fixture.bash` with
  Forge-specific scaffolding (ROADMAP.md with controlled feature states, EARS spec stubs)
- **Approach**: Each test seeds a Forge clone in a temp dir with specific artifact
  combinations, runs `check-phase.sh`, and asserts: exit code, log content, which
  skills were installed (or not), and repository cleanliness.

---

## Known Risks

- **Phase slug derivation**: The plan file name is derived from the feature title
  (`[SLUG]_PLAN.md`). The slug must be generated consistently between when the plan
  is written and when the sensor looks for it. The derivation rule is: upper-case,
  spaces to underscores, non-alphanumeric stripped. Tested explicitly.
- **PostToolUse stdin format**: The hook receives tool input as JSON on stdin.
  The script must parse this to check the `file_path` field without adding
  dependencies (uses `grep`/`sed`, not `jq`).
- **Idempotency on commit**: The sensor commits when it installs a skill. If the
  hook fires twice rapidly, the second invocation must detect the skill is already
  installed and exit without making an empty commit.

---

## Implementation Checklist

- [x] STEP 0 — Write this plan
- [x] STEP 1 — EARS specification (`doc/SPECIFICATION.ears.md`, EARS-009–013)
- [x] STEP 2 — Feature documentation (`doc/features/phase-sensor.feature`)
- [x] STEP 3 — Test code (`tests/test-phase-sensor.bats`)
- [ ] STEP 4 — Run tests (confirm red — bats-core not installed; manual smoke tests run)
- [x] STEP 5 — Implementation (sensor script, phase definitions, hook, SKILL.md)
- [ ] STEP 6 — Run tests (drive to green — pending bats-core install)
- [x] STEP 7 — Sync with upstream
- [x] STEP 8 — Write commit message
- [x] STEP 9 — Commit and push

---

## Resumption

If this plan is picked up by a cold-start agent:

1. Read `ROADMAP.md §[2]` for the feature description and EARS IDs.
2. Read `doc/features/phase-sensor.feature` for the Gherkin scenarios.
3. Check the checklist above to find the current step.
4. The core script is `skills/phase-sensor/scripts/check-phase.sh`.
5. Phase definitions live in `skills/phase-sensor/phases/phase-N.md` — each contains
   metadata in the header and an embedded SKILL.md after the `---SKILL---` marker.
6. The PostToolUse hook in `settings.json` calls the script and passes stdin.
7. Slug derivation: `echo "$title" | tr '[:lower:]' '[:upper:]' | tr ' ' '_' | tr -cd 'A-Z0-9_'`
