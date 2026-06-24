#!/usr/bin/env bash
# PLAN_0011 story-proof runner — runs every PLAN_0011 unit/story test and reports a single verdict.
# This is the story-level proof: it invokes the suite against the live agent-instruction surface and
# asserts the full happy/unhappy/abuse chain pins each retrofitted PR #56 behaviour.
# Run from the repo root: bash tests/plan-0011/run.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAIL=0
for t in "$DIR"/0*.sh; do
  echo "── $(basename "$t") ──"
  if bash "$t"; then :; else FAIL=1; fi
  echo
done
if [ "$FAIL" -eq 0 ]; then
  echo "STORY_PROVEN: PLAN_0011 — all PR #56 lifecycle-delivery behaviours pinned (happy/unhappy/abuse)"
else
  echo "STORY FAILED: PLAN_0011 — one or more behaviours unpinned"; exit 1
fi
