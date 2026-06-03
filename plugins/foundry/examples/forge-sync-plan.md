# FORGE AUTO-SYNC WITH CONFLICT RESOLUTION — Implementation Plan

> Feature: [1] Forge Auto-Sync with Conflict Resolution
> Roadmap entry: ROADMAP.md §[1]
> Date: 2026-05-17
> Status: IN PROGRESS

---

## Summary of EARS Specification

| ID       | Form            | Requirement |
|----------|-----------------|-------------|
| EARS-001 | Event-driven    | On session stop, execute forge-sync.sh |
| EARS-002 | Event-driven    | Fetch from origin before merge/rebase |
| EARS-003 | Unwanted behav. | Skip sync if repository is mid-operation |
| EARS-004 | Event-driven    | Fast-forward merge when possible |
| EARS-005 | Unwanted behav. | Resolve conflicts by accepting incoming |
| EARS-006 | Event-driven    | Push to origin after successful sync |
| EARS-007 | Unwanted behav. | Log and exit non-zero on irrecoverable failure |
| EARS-008 | Event-driven    | Append timestamped log entry after every run |

---

## Gherkin Scenarios Summary

File: `doc/features/forge-sync.feature`

| Scenario | Path | EARS IDs |
|----------|------|----------|
| Fast-forward sync on stop | Happy | 001,002,004,006,008 |
| Local commits pushed | Happy | 001,006,008 |
| Skip during in-progress rebase | Unhappy | 003 |
| Skip during in-progress merge | Unhappy | 003 |
| Conflict resolved by accepting incoming | Unhappy | 005,006,008 |
| Remote unreachable | Abuse | 007,008 |
| Push rejected | Abuse | 007,008 |

---

## Files Created / Modified

| File | Action | Rationale |
|------|--------|-----------|
| `forge-sync.sh` | CREATE | Core sync script, replaces inline hook command |
| `settings.json` | MODIFY | Update Stop hook to call forge-sync.sh |
| `tests/test-forge-sync.bats` | CREATE | bats tests covering all scenarios |
| `ROADMAP.md` | MODIFY | Status update on completion |

---

## Test Strategy

- **Runner**: [bats-core](https://github.com/bats-core/bats-core)
- **Test file**: `tests/test-forge-sync.bats`
- **Approach**: Each test creates a temporary git repo pair (local + remote bare clone),
  seeds the scenario's preconditions, runs forge-sync.sh, and asserts outcomes via exit
  code, log content, and repository state.
- **Setup helper**: `tests/helpers/git-fixture.bash` — creates and tears down temp repos.

---

## Known Risks

- **`git checkout --theirs` semantics during rebase**: "ours/theirs" are inverted during
  rebase vs. merge. The implementation uses `git merge -X theirs` (not rebase) to avoid
  this confusion entirely.
- **Push permission in CI/test environments**: tests use local bare repos, not a real
  remote, so push tests are hermetic.
- **`cache/` directory must exist**: `forge-sync.sh` creates it if absent; install.sh does
  not need updating.

---

## Implementation Checklist

- [x] STEP 0 — Write this plan
- [x] STEP 1 — EARS specification (`doc/SPECIFICATION.ears.md`)
- [x] STEP 2 — Feature documentation (`doc/features/forge-sync.feature`)
- [x] STEP 3 — Test code (`tests/test-forge-sync.bats`)
- [ ] STEP 4 — Run tests (confirm red — bats-core not installed; manual smoke tests run instead)
- [x] STEP 5 — Implementation (`forge-sync.sh`, update `settings.json`)
- [ ] STEP 6 — Run tests (drive to green — pending bats-core install)
- [ ] STEP 7 — Sync with upstream
- [ ] STEP 8 — Write commit message
- [ ] STEP 9 — Commit and push

---

## Resumption

If this plan is picked up by a cold-start agent:

1. Read `ROADMAP.md §[1]` for the full feature description and EARS statements.
2. Read `doc/features/forge-sync.feature` for the Gherkin scenarios.
3. Check the checklist above to find the current step.
4. Test runner is bats-core; test file is `tests/test-forge-sync.bats`.
5. The implementation target is `forge-sync.sh` at the repo root.
6. The settings change is: replace the inline Stop hook command in `settings.json` with
   `bash ~/.claude/forge-sync.sh`.
