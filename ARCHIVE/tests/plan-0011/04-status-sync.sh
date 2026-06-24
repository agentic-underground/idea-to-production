#!/usr/bin/env bash
# PLAN_0011 / AC4 + EARS-002/005: the status-sync behaviour (Action #8) on the CURRENT surface.
# Sink-up equivalent: ds-step-9 emits DELIVERY_COMPLETE at branch HEAD; Action #8 is Reserved.
# Sink-down: a down/absent sink never fails delivery (graceful skip), and the orchestrator's
# post-merge handler no longer calls the retired flow-canvas post_status tool.
# Run from the repo root: bash tests/plan-0011/04-status-sync.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STEP9="${ROOT}/plugins/foundry/agents/ds-step-9-commit-push.md"
ORCH="${ROOT}/plugins/foundry/agents/lifecycle-orchestrator.md"
FAIL=0
ok()  { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; FAIL=1; }
[ -r "$STEP9" ] || { echo "FAIL: ds-step-9 not found at $STEP9"; exit 1; }
[ -r "$ORCH" ]  || { echo "FAIL: orchestrator not found at $ORCH"; exit 1; }

# --- EARS-002 sink-up equivalent: completion signal is DELIVERY_COMPLETE at HEAD, not a board post
grep -q "SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{branch_head_short_sha}" "$STEP9" \
  && ok "ds-step-9 emits DELIVERY_COMPLETE keyed to branch HEAD" \
  || bad "ds-step-9 does not emit DELIVERY_COMPLETE keyed to branch HEAD"
grep -q "Reserved — the live flow board was retired" "$STEP9" \
  && ok "Action #8 is Reserved (board retired)" || bad "Action #8 not documented as Reserved/retired"
grep -q "No separate board to sync" "$STEP9" && ok "no separate board to sync (sink retired)" \
  || bad "ds-step-9 still implies a live board to sync"

# --- EARS-005 sink-down: a missing sink/automation never blocks delivery (graceful skip)
grep -q "Graceful skip (no halt)" "$STEP9" && ok "ds-step-9 graceful-skips a missing sink/automation" \
  || bad "ds-step-9 has no graceful-skip path"
grep -q "Never block delivery on this" "$STEP9" && ok "graceful skip never blocks delivery (EARS-005)" \
  || bad "ds-step-9 graceful skip may block delivery"

# --- EARS-005 sink-down: the orchestrator post-merge handler no longer calls the retired canvas tool
grep -q 'Invoke MCP tool `post_status`' "$ORCH" \
  && bad "orchestrator still calls the retired post_status canvas tool" \
  || ok "orchestrator no longer calls the retired post_status canvas tool"
grep -qi "no live board" "$ORCH" && ok "orchestrator status step is a graceful no-op (no live board)" \
  || bad "orchestrator status step does not document the retired board"

[ "$FAIL" -eq 0 ] && echo "PASS: AC4/EARS-002+005 status-sync up/down on the current surface" || exit 1
