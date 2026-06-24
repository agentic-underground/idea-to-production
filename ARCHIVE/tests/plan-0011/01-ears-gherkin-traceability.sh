#!/usr/bin/env bash
# PLAN_0011 / AC1: every EARS id exists and maps to >=1 Gherkin scenario + a test coordinate.
# Run from the repo root: bash tests/plan-0011/01-ears-gherkin-traceability.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EARS="${ROOT}/docs/internal/plan-0011-ears.md"
FEAT="${ROOT}/docs/internal/plan-0011-lifecycle-delivery-retrofit.feature"
FAIL=0
ok()  { echo "  ok: $1"; }
bad() { echo "  FAIL: $1"; FAIL=1; }

[ -r "$EARS" ] || { echo "FAIL: EARS spec not found at $EARS"; exit 1; }
[ -r "$FEAT" ] || { echo "FAIL: feature file not found at $FEAT"; exit 1; }

# Every EARS id 001..006 is defined in the spec AND referenced from at least one Gherkin scenario.
for n in 001 002 003 004 005 006; do
  grep -q "EARS-${n}" "$EARS" && ok "EARS-${n} defined in spec" || bad "EARS-${n} missing from spec"
  grep -q "(EARS-${n}" "$FEAT" && ok "EARS-${n} referenced by a Gherkin scenario" \
    || bad "EARS-${n} not referenced by any Gherkin scenario"
done

# Every EARS id names a concrete test coordinate (a tests/plan-0011/*.sh file).
grep -q "tests/plan-0011/" "$EARS" && ok "spec names test coordinates" || bad "spec names no test coordinates"
for t in 02-awaiting-merge-mapping 03-pause-and-post-merge 04-status-sync; do
  [ -r "${ROOT}/tests/plan-0011/${t}.sh" ] && ok "coordinate ${t}.sh exists" \
    || bad "coordinate ${t}.sh missing"
done

# The happy/unhappy/abuse triad is all present in the feature file.
for kind in happy unhappy abuse; do
  grep -qi "$kind" "$FEAT" && ok "feature carries a '${kind}' scenario" \
    || bad "feature has no '${kind}' scenario"
done

[ "$FAIL" -eq 0 ] && echo "PASS: AC1 EARS↔Gherkin↔test traceability" || exit 1
