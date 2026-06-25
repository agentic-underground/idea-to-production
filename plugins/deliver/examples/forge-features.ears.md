# The Forge — EARS Specification

> **Historical worked example — provenance archive.** Not part of the marketplace runtime;
> retained to illustrate the EARS station. See [`../docs/HISTORY.md`](../docs/HISTORY.md).

> Format: Easy Approach to Requirements Syntax (EARS)
> Last updated: 2026-05-17

Each statement carries a unique ID (`EARS-NNN`) referenced from test code and
.feature files. Statements use SHALL (mandatory), SHOULD (recommended), MAY (optional).

---

## Feature [1]: Forge Auto-Sync with Conflict Resolution

### EARS-001
WHEN the Claude Code session stops, THE SYSTEM SHALL execute `forge-sync.sh` to
synchronise `~/.claude` with git origin.

### EARS-002
WHEN `forge-sync.sh` runs, THE SYSTEM SHALL fetch from origin before attempting any
merge or rebase operation.

### EARS-003
IF the repository is in a mid-operation state (`.git/rebase-merge` directory exists,
`.git/rebase-apply` directory exists, or `.git/MERGE_HEAD` file exists), THEN THE SYSTEM
SHALL skip the sync and append a log entry describing the reason.

### EARS-004
WHEN a fast-forward merge to `origin/main` is possible, THE SYSTEM SHALL apply it
without creating a merge commit.

### EARS-005
IF a fast-forward merge is not possible and file conflicts exist, THEN THE SYSTEM SHALL
resolve all conflicts by accepting the incoming (origin) version of each conflicted file,
in accordance with the CLAUDE.md conflict resolution policy ("prefer the incoming change
unless you are certain the local version is newer").

### EARS-006
WHEN sync completes successfully (fast-forward or conflict-resolved merge), THE SYSTEM
SHALL push the resulting state to origin.

### EARS-007
IF sync fails irrecoverably (network unreachable, push rejected for unrecoverable reasons,
or internal git error), THEN THE SYSTEM SHALL log the error, exit with a non-zero status
code, and leave the repository in a clean, non-broken state.

### EARS-008
WHEN any sync operation completes — whether successful or failed — THE SYSTEM SHALL
append a timestamped log entry to `~/.claude/cache/forge-sync.log` describing the
outcome, the operation performed, and any files affected by conflict resolution.

---

## Feature [2]: DEV_SYSTEM Phase Sensor

### EARS-009
WHEN a Forge feature transitions to `STATUS: IN PROGRESS` in `ROADMAP.md`, THE SYSTEM
SHALL evaluate the current DEV_SYSTEM phase by inspecting existing artifacts in the
repository.

### EARS-010
WHEN the current DEV_SYSTEM phase is identified, THE SYSTEM SHALL compare existing
artifacts against the documented prerequisites for the next phase.

### EARS-011
WHEN all prerequisites for the next DEV_SYSTEM phase are met, THE SYSTEM SHALL install
or update the skills and agents required for that phase under `~/.claude/skills/` and
`~/.claude/agents/`, committing the result to the Forge repository.

### EARS-012
WHILE a DEV_SYSTEM phase transition is in progress, THE SYSTEM SHALL record the
current phase number, each prerequisite evaluated, its pass/fail status, and any
artifacts installed, in `~/.claude/cache/phase-sensor.log`.

### EARS-013
IF a prerequisite for the next DEV_SYSTEM phase cannot be automatically satisfied, THEN
THE SYSTEM SHALL output a human-readable description of the unsatisfied prerequisite and
exit without making any repository changes.
