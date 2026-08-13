---
name: bash-selftest-setE-masking
description: Bash --self-test cases that wrap the entrypoint in $(...) MASK set -e — a fail-safe/abort-class guard passes even with the fix reverted (toothless)
metadata:
  type: project
---

A `set -euo pipefail` script's `--self-test` that asserts `"$(entrypoint_fn "$file")" == expected`
CANNOT catch a `set -e`/`pipefail` abort bug in that entrypoint. Bash disables `set -e` inside a
command substitution that is used as an assignment/argument, so the fn runs to completion in the
test even when the SAME fn, called directly at top level (the real `case *)` CLI path), aborts to
rc=1/empty.

**Why:** PR #362 (resolve-review-profile.sh, PLAN 0073.002) fixed a real HIGH (Mode-less/empty file
aborted the resolver under set -e+pipefail instead of failing safe to `auto`) with a `|| true` on
`_rrp_field`. The fix is correct at the live CLI. But the added "live-path" self-test cases
`$(_rrp_resolve_file "$d/empty.md")` still wrap the entrypoint in `$()` — PROOF: with `|| true`
reverted, `--self-test` stays GREEN while `bash SCRIPT empty.md` returns rc=1/empty. The guard is
fake for the exact class it names.

**How to apply:** When re-reviewing a bash fail-safe/abort fix, don't trust a green `--self-test` —
REVERT the fix and re-run the self-test; if it's still green the guard is toothless. The toothful
form invokes the real entrypoint as a SUBPROCESS: `$(bash "${BASH_SOURCE[0]}" "$file" 2>/dev/null)`
(runs the top-level `case` direct call under live set -e), which correctly captures empty→fails the
assert on a reverted script. Related fail-open class: [[project_fail-open-guard-class]].
