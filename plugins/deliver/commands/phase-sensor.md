---
description: Detect the current development phase of each IN_PROGRESS roadmap feature and install the right skill for the next stage.
---

Run the phase sensor.

Execute `bash ${CLAUDE_PLUGIN_ROOT}/skills/phase-sensor/scripts/check-phase.sh` (or follow the
`phase-sensor` skill) to inspect existing artifacts, determine each IN_PROGRESS feature's
current phase, and surface/install the correct lifecycle skill for the next stage. This is the
**detector** in the executor/detector/gate-definition triad (`ds-step-*` / phase-sensor /
`lifecycle-states`). It also runs automatically via the plugin's PostToolUse hook on
`ROADMAP.md` edits.
