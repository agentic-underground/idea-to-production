#!/usr/bin/env bash
# route-eval.sh — Layer-2 behavioural routing eval (OPT-IN, token-costly, NON-deterministic).
#
# Layer 1 (scripts/verify-routing.sh) proves the routing WIRING is sound. This proves the harder
# thing: that natural wording actually ROUTES to the intended section and leaves the others dormant —
# a model behaviour, so it needs a model in the loop. It is DELIBERATELY NOT part of the pre-push gate
# (it costs tokens and can vary run to run). Run it on demand, or under /loop, and log results.
#
#   bash scripts/routing/route-eval.sh --check     # deterministic: just validate the fixtures file
#   bash scripts/routing/route-eval.sh             # emit the judge pack (one prompt per fixture)
#   bash scripts/routing/route-eval.sh --run       # if the `claude` CLI is on PATH, adjudicate + tally
#
# Fixtures: scripts/routing/eval-fixtures.tsv (phrase ⇥ expect ⇥ must_not_load ⇥ note).
# Pattern + how to extend: docs/guide/routing-tests.md §4-5.

set -uo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo"
FIX="scripts/routing/eval-fixtures.tsv"
mode="pack"
case "${1:-}" in
  --check) mode="check" ;;
  --run)   mode="run" ;;
  ""|--pack) mode="pack" ;;
  -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
  *) echo "unknown argument: $1 (supported: --check | --pack | --run)" >&2; exit 2 ;;
esac

[ -f "$FIX" ] || { echo "missing fixtures: $FIX" >&2; exit 1; }

# ── deterministic validation of the fixtures file (safe to run anywhere, no tokens) ──
rows=0; bad=0
while IFS=$'\t' read -r phrase expect mustnot note; do
  case "$phrase" in '#'*|''|phrase) continue ;; esac
  rows=$((rows+1))
  if [ -z "$expect" ]; then echo "  ✗ fixture $rows: empty 'expect' for phrase $phrase" >&2; bad=$((bad+1)); fi
  # every expect / must_not_load token must be a real installed plugin:section
  for tok in $(printf '%s,%s' "$expect" "$mustnot" | tr ',' ' '); do
    [ -z "$tok" ] && continue
    p="${tok%%:*}"; n="${tok#*:}"
    if [ ! -d "plugins/$p/skills/$n" ] && [ ! -f "plugins/$p/commands/$n.md" ] && [ ! -f "plugins/$p/agents/$n.md" ]; then
      echo "  ✗ fixture $rows: '$tok' is not an installed section" >&2; bad=$((bad+1))
    fi
  done
done < "$FIX"

if [ "$mode" = "check" ]; then
  if [ "$bad" -eq 0 ]; then echo "✓ $rows fixtures valid — every expect/must-not token resolves to a real section"; exit 0
  else echo "✗ $bad problem(s) across $rows fixtures"; exit 1; fi
fi
[ "$bad" -eq 0 ] || { echo "✗ fixtures invalid — fix them before running the eval (see --check)"; exit 1; }

# ── judge prompt for one fixture ──
judge_prompt() {
  local phrase="$1" expect="$2" mustnot="$3"
  cat <<EOF
You are a routing judge for the idea-to-production marketplace. A user says:

    $phrase

Given ONLY the installed skills' descriptions, which single plugin:section should the agent route to,
and which should stay dormant? Answer STRICTLY as: ROUTE=<plugin:section> | DORMANT_OK=<yes|no>
where DORMANT_OK=yes iff none of these would be wrongly activated: $mustnot
Expected route (for your reference, do not just echo it — judge honestly): $expect
EOF
}

# ── pack mode: print one judge prompt per fixture for an agent/human to adjudicate ──
if [ "$mode" = "pack" ]; then
  echo "# Routing eval pack — $rows fixtures. Adjudicate each with a fresh judge; tally ROUTE== expect and DORMANT_OK==yes."
  i=0
  while IFS=$'\t' read -r phrase expect mustnot note; do
    case "$phrase" in '#'*|''|phrase) continue ;; esac
    i=$((i+1)); echo; echo "## fixture $i — $note"; judge_prompt "$phrase" "$expect" "$mustnot"
  done < "$FIX"
  echo; echo "# (no tokens spent — this is the pack. Use --run to adjudicate via the claude CLI if present.)"
  exit 0
fi

# ── run mode: adjudicate through the claude CLI if available, else degrade to the pack ──
if ! command -v claude >/dev/null 2>&1; then
  echo "⚠ the 'claude' CLI is not on PATH — cannot auto-adjudicate. Emitting the pack instead:" >&2
  exec bash "$0" --pack
fi
pass=0; total=0
while IFS=$'\t' read -r phrase expect mustnot note; do
  case "$phrase" in '#'*|''|phrase) continue ;; esac
  total=$((total+1))
  verdict="$(judge_prompt "$phrase" "$expect" "$mustnot" | claude -p 2>/dev/null || true)"
  if printf '%s' "$verdict" | grep -qiF "ROUTE=$expect" && printf '%s' "$verdict" | grep -qiE 'DORMANT_OK=yes'; then
    printf "  ✓ %s\n" "$phrase"; pass=$((pass+1))
  else
    printf "  ✗ %s\n     → %s\n" "$phrase" "$(printf '%s' "$verdict" | tr '\n' ' ' | cut -c1-160)"
  fi
done < "$FIX"
echo "routing eval: $pass/$total fixtures routed as expected"
[ "$pass" -eq "$total" ]
