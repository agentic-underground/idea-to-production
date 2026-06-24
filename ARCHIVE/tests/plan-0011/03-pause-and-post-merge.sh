#!/usr/bin/env bash
# PLAN_0011 / AC3 + EARS-003/004/005/006: the AWAITING MERGE pause and the post-merge completion
# handler — one happy (merged -> complete), one unhappy (merge fails -> stays paused), one abuse
# (not-yet-merged -> refuses to complete), each pinned in lifecycle-orchestrator.md.
# Run from the repo root: bash tests/plan-0011/03-pause-and-post-merge.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORCH="${ROOT}/plugins/foundry/agents/lifecycle-orchestrator.md"
FAIL=0
ok()  { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; FAIL=1; }
[ -r "$ORCH" ] || { echo "FAIL: orchestrator not found at $ORCH"; exit 1; }

# --- EARS-003: the pause ------------------------------------------------------
grep -q "Merge PR now? \[yes/no\]" "$ORCH" && ok "pause emits the 'Merge PR now? [yes/no]' callout" \
  || bad "pause callout missing"
grep -q "IN_PROGRESS.md" "$ORCH" && grep -q 'state `AWAITING_MERGE`' "$ORCH" \
  && ok "pause writes IN_PROGRESS.md with state AWAITING_MERGE" \
  || bad "pause does not record AWAITING_MERGE in IN_PROGRESS.md"

# --- EARS-004: happy — merged PR drives the item to COMPLETE ------------------
grep -qi "Post-merge completion handler" "$ORCH" && ok "post-merge completion handler present" \
  || bad "post-merge completion handler missing"
grep -q "SENTINEL::DELIVERY_COMPLETE::ROADMAP" "$ORCH" \
  && ok "handler emits DELIVERY_COMPLETE on completion" || bad "handler does not emit DELIVERY_COMPLETE"
grep -q "completion summary" "$ORCH" && ok "handler emits a completion summary" \
  || bad "handler emits no completion summary"

# --- EARS-006: abuse — refuse a not-yet-merged PR ----------------------------
grep -q "If not yet merged, warn the user and wait" "$ORCH" \
  && ok "handler refuses a not-yet-merged PR (warn and wait)" \
  || bad "handler does not refuse a not-yet-merged PR"
grep -q "do not proceed" "$ORCH" && ok "handler does not proceed without a confirmed merge" \
  || bad "handler missing the 'do not proceed' guard"

# --- EARS-005: unhappy — merge fails / gh down => stays paused, no corruption -
grep -q "Path C — gh unavailable or merge fails" "$ORCH" \
  && ok "Path C (gh unavailable / merge fails) present" || bad "Path C missing"
grep -q "Do NOT emit DELIVERY_COMPLETE" "$ORCH" && ok "Path C does not emit DELIVERY_COMPLETE" \
  || bad "Path C may emit DELIVERY_COMPLETE"
grep -q "Do NOT corrupt the sentinel chain" "$ORCH" && ok "Path C does not corrupt the sentinel chain" \
  || bad "Path C may corrupt the sentinel chain"

[ "$FAIL" -eq 0 ] && echo "PASS: AC3/EARS-003-006 pause + post-merge happy/unhappy/abuse" || exit 1
