---
description: Keep score — emit deterministic, artifact-measured scorecards proving the PRODUCT you build and the MARKETPLACE that builds it are getting better over time. Coverage, corpus FP-rate, test/rule counts, security verdict, real tokens/wall-clock (product); inspection findings, self-improve PRs, integrity, portability (marketplace).
---

Score it. Follow the [`scorecard` skill](../skills/scorecard/SKILL.md):

1. **Product** — in the project you're building, run
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/scorecard/scripts/scorecard.sh` → writes `SCORECARD.json` (coverage,
   corpus FP, test/rule count, SENTINEL verdict, and real tokens/wall-clock from the last cycle's
   `IDEA_COST.jsonl` when present).
2. **Marketplace** — in the marketplace source tree, run
   `bash ${CLAUDE_PLUGIN_ROOT}/skills/scorecard/scripts/marketplace-score.sh` → appends a line to
   `.foundry/MARKETPLACE_SCORECARD.jsonl` (inspection findings, self-improve PRs, canonical-copy integrity,
   `~/.claude` portability violations, self-coverage).
3. **Read the trend, not the snapshot** — improvement is the direction of travel across runs (coverage
   holds, FP/violations down, findings-closed > opened, regressions 0). Every metric is measured from a
   file on disk — never a model-assigned score — so it cannot be gamed.

Set `SCORECARD_TS="$(date -u +%FT%TZ)"` to stamp the run. Schema:
`knowledge/orchestration/scorecard-schema.md`.
