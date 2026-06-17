#!/usr/bin/env bash
# Test: [23][24][25][26] the missing-handler pause-and-decide gate.
# Asserts the conveyor instructions that make each card's acceptance criteria self-evidently satisfiable.
# Run from the repo root: bash tests/item-23-26/23-26-missing-handler-gate.sh
FAIL=0

LEAD="plugins/foundry/agents/builder-lead.md"
BUILDER="plugins/foundry/skills/builder/SKILL.md"
CHALLENGE="plugins/ideator/knowledge/ideation/challenge-protocol.md"
IDEA="plugins/ideator/knowledge/ideation/idea-package.md"
GATE="plugins/foundry/knowledge/orchestration/missing-handler-gate.md"
DISC="plugins/foundry/knowledge/orchestration/handler-authoring-discipline.md"
HANDLER_BUILD="docs/internal/handler-build"

for f in "$LEAD" "$BUILDER" "$CHALLENGE" "$IDEA" "$GATE" "$DISC"; do
  [ -r "$f" ] || { echo "FAIL: $f not found"; exit 1; }
done

# ── #23 — detection PAUSES, does NOT silently route to the nearest handler ──────
# AC1: a missing VALUE_HANDLER → builder-lead STOPS (does not route to nearest).
grep -qi 'PAUSE' "$LEAD" || { echo "FAIL[23]: builder-lead Phase 4.5 must PAUSE on a missing handler"; FAIL=1; }
grep -qi 'do NOT silently route to the nearest handler' "$LEAD" \
  || { echo "FAIL[23]: builder-lead must forbid silently routing to the nearest handler"; FAIL=1; }
grep -qi 'STOP before emitting the plan' "$LEAD" \
  || { echo "FAIL[23]: builder-lead must STOP before emitting the plan on a handler gap"; FAIL=1; }
# §8 of builder/SKILL.md updated to PAUSE, not silent degrade.
grep -qi 'PAUSE, not a' "$BUILDER" || { echo "FAIL[23]: builder §8 must frame a missing handler as a PAUSE"; FAIL=1; }
grep -qi 'Never route the item to the nearest handler' "$BUILDER" \
  || { echo "FAIL[23]: builder §8 must forbid nearest-handler routing"; FAIL=1; }
# AC2: stack-fit flag at ideation for an unsupported stack.
grep -qi 'no FOUNDRY value-handler' "$CHALLENGE" \
  || { echo "FAIL[23]: challenge-protocol must flag a stack with no value-handler"; FAIL=1; }
grep -qi 'SHALL flag the' "$CHALLENGE" && grep -qi 'gap at ideation' "$CHALLENGE" \
  || { echo "FAIL[23]: challenge-protocol must carry the EARS 'SHALL flag the gap at ideation'"; FAIL=1; }
grep -qi 'LANGUAGE/STACK' "$IDEA" || { echo "FAIL[23]: idea-package must carry the LANGUAGE/STACK field"; FAIL=1; }
grep -qi 'registered.*FOUNDRY value-handler' "$IDEA" \
  || { echo "FAIL[23]: idea-package LANGUAGE/STACK must require a registered value-handler"; FAIL=1; }

# ── #24 — the 3-way decision gate ──────────────────────────────────────────────
for opt in 'BUILD HANDLER FIRST' 'MVP WITH EXISTING' 'BOTH'; do
  grep -q "$opt" "$GATE" || { echo "FAIL[24]: gate doc missing option '$opt'"; FAIL=1; }
done
# MVP path emits DEGRADED_CAPABILITIES disclosed in FOUNDRY_PLAN.md.
grep -q 'DEGRADED_CAPABILITIES' "$GATE" || { echo "FAIL[24]: gate doc must name DEGRADED_CAPABILITIES"; FAIL=1; }
grep -q 'FOUNDRY_PLAN.md' "$GATE" || { echo "FAIL[24]: gate doc must disclose DEGRADED_CAPABILITIES in FOUNDRY_PLAN.md"; FAIL=1; }
# BOTH path raises feedback via gemba + files a DEFERRED handler item + awaiting-handler.
grep -q '/mission-control:gemba' "$GATE" || { echo "FAIL[24]: BOTH path must raise feedback via /mission-control:gemba"; FAIL=1; }
grep -qi 'DEFERRED .Create handler' "$GATE" || { echo "FAIL[24]: BOTH path must file a DEFERRED 'Create handler-<stack>' item"; FAIL=1; }
grep -qi 'awaiting-handler' "$GATE" || { echo "FAIL[24]: BOTH path must mark the original awaiting-handler"; FAIL=1; }

# ── #25 — handler-authoring discipline ─────────────────────────────────────────
# AC1: the doc exists and is referenced by the handler-build pipeline + the BUILD path.
grep -qi 'pinned version matrix' "$DISC" || { echo "FAIL[25]: discipline doc must require a pinned version matrix"; FAIL=1; }
grep -q 'FORBIDDEN' "$DISC" || { echo "FAIL[25]: discipline doc must require a FORBIDDEN list"; FAIL=1; }
grep -qi 'kaizen' "$DISC" || { echo "FAIL[25]: discipline doc must carry the KAIZEN covenant"; FAIL=1; }
grep -qi 'four-wave' "$DISC" || { echo "FAIL[25]: discipline doc must name the four-wave build pipeline"; FAIL=1; }
# Referenced by the handler-build pipeline material AND #24's BUILD path (the gate doc).
# The real forward link: the handler-build pipeline run-of-record routes every handler it authors to
# the discipline (so "referenced by the handler-build pipeline" is TRUE, not a MANIFEST stand-in).
[ -d "$HANDLER_BUILD" ] || { echo "FAIL[25]: handler-build pipeline material dir $HANDLER_BUILD not found"; FAIL=1; }
grep -rq 'handler-authoring-discipline.md' "$HANDLER_BUILD" \
  || { echo "FAIL[25]: the handler-build pipeline material ($HANDLER_BUILD) must reference the discipline doc"; FAIL=1; }
grep -q 'handler-authoring-discipline.md' "$GATE" \
  || { echo "FAIL[25]: the gate's BUILD path must reference the discipline doc"; FAIL=1; }
# The typst PDF pain is flagged as a SEPARATE pressroom self-improvement issue, not fixed here.
grep -qi 'typst' "$DISC" || { echo "FAIL[25]: discipline doc must note the typst PDF pain as a separate issue"; FAIL=1; }
grep -qi 'SELF_IMPROVEMENT\|self-improvement\|separate' "$DISC" \
  || { echo "FAIL[25]: typst note must be framed as a separate self-improvement issue for pressroom"; FAIL=1; }

# ── #26 — deferral + resumption (awaiting-handler ↔ DEFERRED handler item) ──────
# AC1: original is awaiting-handler, paired with a DEFERRED handler-creation item.
grep -qi 'visibly paired' "$GATE" || { echo "FAIL[26]: awaiting-handler item must be visibly paired with its DEFERRED handler item"; FAIL=1; }
# AC2: when the handler lands, the original is RESTORED + re-planned via roadmapper DEFER/RESTORE.
grep -qi 'RESTORE' "$GATE" || { echo "FAIL[26]: gate doc must surface the awaiting-handler item for RESTORE when the handler lands"; FAIL=1; }
grep -qi 're-plan' "$GATE" || { echo "FAIL[26]: RESTORE must trigger a re-plan with the real handler"; FAIL=1; }
grep -q 'roadmapper/SKILL.md' "$GATE" || { echo "FAIL[26]: gate doc must reuse the roadmapper DEFER/RESTORE/RESUME idioms (link)"; FAIL=1; }

[ "$FAIL" -eq 0 ] \
  && echo "PASS: [23][24][25][26] missing-handler pause-and-decide gate wired across builder-lead · builder §8/§14 · challenge-protocol · gate + discipline docs" \
  || exit 1
