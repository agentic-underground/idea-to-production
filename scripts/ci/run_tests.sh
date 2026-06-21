#!/usr/bin/env bash
# run_tests.sh — deterministic offline runner for the repo's tests/ suite.
#
# Each tests/**/*.sh is a self-contained behaviour test that exits 0 on PASS and
# non-zero on FAIL (some SKIP cleanly when an optional tool like jq is absent — a SKIP
# is exit 0 by design). This runner discovers every tracked test, runs it from the repo
# root, and aggregates: it exits 0 only when every test passed, non-zero otherwise.
# No network, no build step — just bash.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

mapfile -t tests < <(git ls-files 'tests/*.sh' | sort)
if [ "${#tests[@]}" -eq 0 ]; then
  echo "run_tests: no tests/*.sh found — nothing to run"
  exit 0
fi

fails=0
passed=0
for t in "${tests[@]}"; do
  if bash "$t" >/tmp/ci-test.out 2>&1; then
    passed=$((passed + 1))
  else
    fails=$((fails + 1))
    echo "✗ FAIL: $t"
    sed 's/^/    /' /tmp/ci-test.out
  fi
done
rm -f /tmp/ci-test.out

if [ "$fails" -eq 0 ]; then
  echo "run_tests: ${passed}/${#tests[@]} test(s) passed"
  exit 0
fi
echo "run_tests: ${fails}/${#tests[@]} test(s) FAILED"
exit 1
