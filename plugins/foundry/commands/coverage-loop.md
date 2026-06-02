---
description: Chase test coverage to 100% — find the least-covered file, write tests to fill the gap, and loop until complete.
---

Run the coverage loop.

Invoke the **coverage-loop-agent** to systematically drive coverage toward the floor
(`${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md`: 100% is the floor, not the goal).
It will: parse the coverage report, select the worst-covered file, analyse and fill the gap
with honest tests (never fake coverage), record progress to `IN_PROGRESS.md`, and loop until
done or you stop.

For a full quality analysis instead of just coverage, use the `code-quality` skill.
`$ARGUMENTS` may name a target file or directory to focus on.
