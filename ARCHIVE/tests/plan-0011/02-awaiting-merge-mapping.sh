#!/usr/bin/env bash
# PLAN_0011 / AC2 + EARS-001: AWAITING MERGE -> terminal COMPLETE mapping on the CURRENT surface,
# the v2 manifest terminal state, and the retirement of the flow-server startup mapping (no resurrection).
# Run from the repo root: bash tests/plan-0011/02-awaiting-merge-mapping.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORCH="${ROOT}/plugins/foundry/agents/lifecycle-orchestrator.md"
FLEET="${ROOT}/plugins/foundry/skills/roadmapper/references/fleet-pipeline-standard.md"
FAIL=0
ok()  { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; FAIL=1; }
[ -r "$ORCH" ] || { echo "FAIL: orchestrator not found at $ORCH"; exit 1; }
[ -r "$FLEET" ] || { echo "FAIL: fleet standard not found at $FLEET"; exit 1; }

# Happy: the live successor maps AWAITING MERGE -> terminal COMPLETE in the post-merge handler.
grep -q "AWAITING MERGE" "$ORCH" && ok "orchestrator knows the AWAITING MERGE pause state" \
  || bad "orchestrator has no AWAITING MERGE state"
grep -q "STATUS: COMPLETE" "$ORCH" && ok "post-merge handler maps to terminal STATUS: COMPLETE" \
  || bad "post-merge handler does not map to terminal COMPLETE"

# The v2 manifest terminal state is 'completed' (the engine equivalent of the retired flow 'Done').
grep -Eq '`completed`' "$FLEET" && ok "v2 manifest terminal state 'completed' documented" \
  || bad "v2 manifest terminal state 'completed' not documented in fleet standard"

# Abuse / no-resurrection: the retired flow-server history.rs startup mapping is GONE from the tree.
( cd "$ROOT" && git ls-files | grep -Eq '(^|/)history\.rs$' ) \
  && bad "a tracked history.rs source resurfaced (retired surface resurrected)" \
  || ok "no tracked flow-server history.rs source (retirement intact)"
( cd "$ROOT" && git ls-files | grep -Eq 'flow-server/.*\.rs$' ) \
  && bad "tracked flow-server Rust source resurfaced" \
  || ok "no tracked flow-server Rust source (retirement intact)"
( cd "$ROOT" && grep -rlq "status_from" plugins/ 2>/dev/null ) \
  && bad "an agent instruction calls the retired status_from startup mapping" \
  || ok "no agent calls the retired status_from startup mapping"

# Unhappy: the terminal flip is gated on a CONFIRMED merge, not on the raw paused record.
grep -q 'state == "MERGED"' "$ORCH" && ok "terminal flip is gated on a confirmed MERGED state" \
  || bad "terminal flip is not gated on a confirmed MERGED state (unknown/malformed would map blindly)"

[ "$FAIL" -eq 0 ] && echo "PASS: AC2/EARS-001 AWAITING MERGE → terminal mapping + retirement" || exit 1
