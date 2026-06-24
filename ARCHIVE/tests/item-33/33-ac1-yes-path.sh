#!/usr/bin/env bash
# Test: lifecycle-orchestrator.md contains yes-path interactive merge protocol
set -e
FILE="plugins/foundry/agents/lifecycle-orchestrator.md"
FAIL=0

grep -q "Merge PR now?" "$FILE" || { echo "FAIL: 'Merge PR now?' not found in $FILE"; FAIL=1; }
grep -q "gh pr merge" "$FILE" || { echo "FAIL: 'gh pr merge' not found in $FILE"; FAIL=1; }
grep -q "gh pr view.*--json state" "$FILE" || { echo "FAIL: merge verification step not found in $FILE"; FAIL=1; }
grep -q "yes/no" "$FILE" || { echo "FAIL: 'yes/no' prompt not found in $FILE"; FAIL=1; }
grep -q "post-merge completion handler" "$FILE" || { echo "FAIL: link to post-merge handler not found in $FILE"; FAIL=1; }

[ $FAIL -eq 0 ] && echo "PASS: AC1 yes-path protocol present in $FILE" || exit 1
