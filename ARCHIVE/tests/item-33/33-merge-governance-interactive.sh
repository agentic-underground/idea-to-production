#!/usr/bin/env bash
# Test: merge-governance.md documents the interactive merge offer
set -e
FILE="plugins/foundry/knowledge/protocols/merge-governance.md"
FAIL=0

grep -q "interactive\|Interactive" "$FILE" || { echo "FAIL: interactive merge offer not documented in $FILE"; FAIL=1; }
grep -q "Merge PR now\|merge prompt" "$FILE" || { echo "FAIL: 'Merge PR now' phrase not in $FILE"; FAIL=1; }
grep -q "gh pr merge" "$FILE" || { echo "FAIL: 'gh pr merge' not documented in governance spec $FILE"; FAIL=1; }

[ $FAIL -eq 0 ] && echo "PASS: interactive merge offer documented in $FILE" || exit 1
