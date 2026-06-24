#!/usr/bin/env bash
# Test: lifecycle-orchestrator.md contains no-path halt protocol
set -e
FILE="plugins/foundry/agents/lifecycle-orchestrator.md"
FAIL=0

grep -q "answer.*no\|no.*halt\|no.*leave" "$FILE" || grep -qi '"no"' "$FILE" || { echo "FAIL: no-path halt protocol not found in $FILE"; FAIL=1; }
grep -q "PR URL" "$FILE" || grep -q "pr_url" "$FILE" || { echo "FAIL: PR URL visible on no-path not documented in $FILE"; FAIL=1; }

[ $FAIL -eq 0 ] && echo "PASS: AC2 no-path protocol present in $FILE" || exit 1
