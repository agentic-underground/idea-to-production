#!/usr/bin/env bash
# Test: [18] learnings.sh + overdue-learnings.sh — append-only ledger (open→filed) + overdue detector.
# Run from the repo root: bash tests/item-17-20/18-learnings.sh
FAIL=0
L="plugins/mission-control/skills/gemba/scripts/learnings.sh"
O="plugins/mission-control/skills/gemba/scripts/overdue-learnings.sh"
[ -r "$L" ] || { echo "FAIL: $L not found"; exit 1; }
[ -r "$O" ] || { echo "FAIL: $O not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed"; exit 0; }
bash -n "$L" || { echo "FAIL: syntax error in $L"; exit 1; }
bash -n "$O" || { echo "FAIL: syntax error in $O"; exit 1; }

TMP="$(mktemp -d)"

# AC1 — a capture then a filing records open THEN filed for the SAME id (append-only, latest-wins).
bash "$L" open "$TMP" gap-x "Missing abuse-path test for X" \
  --origin foundry --phase ASSURE --kind test-gap --target whatbirdisthat/idea-to-production \
  --verdict self --severity medium --brief doc/learnings/gap-x/ >/dev/null

[ "$(bash "$L" get "$TMP" gap-x | jq -r '.status')" = "open" ] \
  || { echo "FAIL: after open, status should be open"; FAIL=1; }

bash "$L" filed "$TMP" gap-x --issue https://github.com/whatbirdisthat/idea-to-production/issues/1 >/dev/null
[ "$(bash "$L" get "$TMP" gap-x | jq -r '.status')" = "filed" ] \
  || { echo "FAIL: after filed, status should be filed"; FAIL=1; }
[ "$(bash "$L" get "$TMP" gap-x | jq -r '.issue_url')" = "https://github.com/whatbirdisthat/idea-to-production/issues/1" ] \
  || { echo "FAIL: filed should record the issue_url"; FAIL=1; }

# the append-only history has BOTH events for the one id (open then filed), latest wins on reduce.
LEDGER="$TMP/.i2p/learnings.jsonl"
[ "$(grep -c '"id":"gap-x"' "$LEDGER")" -eq 2 ] || { echo "FAIL: ledger should hold 2 records for gap-x (open+filed)"; FAIL=1; }
events="$(jq -r 'select(.id=="gap-x") | .event' "$LEDGER" | tr '\n' ' ')"
[ "$events" = "open filed " ] || { echo "FAIL: ledger event order should be 'open filed', got '$events'"; FAIL=1; }

# AC2 — an open-but-unfiled learning is SURFACED by the detector.
bash "$L" open "$TMP" gap-y "Unfiled guard gap" --verdict gemba --target whatbirdisthat/token-fairness >/dev/null
# default 24h: just-created ⇒ open, not yet overdue, but still listed.
out="$(bash "$O" --dir "$TMP")"
echo "$out" | grep -q "gap-y" || { echo "FAIL: detector should surface the open unfiled gap-y"; FAIL=1; }
echo "$out" | grep -q "gap-x" && { echo "FAIL: detector must NOT surface the filed gap-x"; FAIL=1; }

# --hours 0 ⇒ the open learning is OVERDUE; --strict exits non-zero.
if bash "$O" --dir "$TMP" --hours 0 --strict >/dev/null 2>&1; then
  echo "FAIL: --hours 0 --strict should exit non-zero with an overdue learning"; FAIL=1
fi
bash "$O" --dir "$TMP" --hours 0 | grep -q "OVERDUE" || { echo "FAIL: --hours 0 should mark the open learning OVERDUE"; FAIL=1; }

# Once filed, the detector reports clean (exit 0) even at --hours 0.
bash "$L" filed "$TMP" gap-y --issue http://x >/dev/null
bash "$O" --dir "$TMP" --hours 0 --strict >/dev/null 2>&1 || { echo "FAIL: all-filed ledger should be clean (exit 0)"; FAIL=1; }

# Graceful: a fresh project with no ledger is clean, exit 0.
TMP2="$(mktemp -d)"
bash "$O" --dir "$TMP2" >/dev/null 2>&1 || { echo "FAIL: no-ledger detector should exit 0"; FAIL=1; }

rm -rf "$TMP" "$TMP2"
[ "$FAIL" -eq 0 ] && echo "PASS: [18] learnings ledger open→filed + overdue detector" || exit 1
