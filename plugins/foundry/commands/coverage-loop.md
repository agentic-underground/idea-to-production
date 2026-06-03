---
description: Pin unpinned behaviour — find the behaviour least covered by tests, add the missing coordinate(s), and loop until every behaviour is pinned (100% coverage is the floor that results).
---

Run the coverage loop.

Invoke the **coverage-loop-agent** to systematically pin behaviour the tests do not yet locate.
100% line+branch coverage is the **floor that results**, never the target
([`${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md`](../knowledge/testing/test-policy.md)):
a unit test is a *coordinate* pinning the working solution, and the real variable is **coverage
density** (happy / unhappy / abuse per behaviour). The agent will: parse the coverage report,
select the behaviour with the most unpinned lines, add honest coordinates that pin it (never fake
coverage), record progress to `IN_PROGRESS.md`, and loop until every behaviour is pinned or you stop.

For a full quality analysis instead of just coverage, use the `code-quality` skill.
`$ARGUMENTS` may name a target file or directory to focus on.
