#!/usr/bin/env bash
# Test: lifecycle-orchestrator.md contains failure/fallback protocol
set -e
FILE="plugins/foundry/agents/lifecycle-orchestrator.md"
FAIL=0

grep -q "fall.back\|fallback" "$FILE" || { echo "FAIL: fallback path not documented in $FILE"; FAIL=1; }
grep -q "manual.merge\|manual merge" "$FILE" || { echo "FAIL: manual-merge fallback not documented in $FILE"; FAIL=1; }
grep -q "DELIVERY_COMPLETE.*not\|not.*DELIVERY_COMPLETE\|do not emit\|sentinel.*not\|no.*sentinel" "$FILE" || \
  grep -q "sentinel corruption" "$FILE" || { echo "FAIL: sentinel-not-corrupted guarantee not documented in $FILE"; FAIL=1; }

[ $FAIL -eq 0 ] && echo "PASS: AC3 failure-path protocol present in $FILE" || exit 1
