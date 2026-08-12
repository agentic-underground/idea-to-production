---
name: epic-0066-board-linkage
description: EPIC 0066 board-linkage guardrails slice chain (0066.001-004) — cross-slice consistency traps to re-check
metadata:
  type: project
---

EPIC 0066 (board-linkage guardrails) establishes `docs/roadmap/` + a board-first workflow, then builds four guardrails across PLANs: 0066.001 workflow+convention (CLAUDE.md), 0066.002 `verify-board-linkage.sh` pre-push gate, 0066.003 SessionStart tripwire, 0066.004 PR template + CI. All 002/003/004 depend on 001. Project board is #4 (`idea-to-production — pipeline`, owner agentic-underground) — CONFIRMED real via `gh project list`.

**Why:** the linkage convention is meant to be ONE canonical thing every guardrail reads (EPIC "single source of truth", owned by 0066.001/CLAUDE.md). Cross-slice drift is the live risk.

**How to apply — re-check on each later slice:**
- **Convention drift:** CLAUDE.md accepts `Board: #<issue>` OR `Refs #<issue>`, but EPIC "Shared infrastructure" + every PLAN EARS omit `Refs`. When 0066.002/004 build the gate/CI, confirm they recognize BOTH or the doc/spec was reconciled — else a `Refs`-only PR that CLAUDE.md blesses will fail the gate.
- **Present-tense overclaim:** 0066.001's CLAUDE.md describes the gate/tripwire/PR-template as things that "all check" the convention while none exist yet; the completing slices must make that true (or the wording should be future-tense until then).
- Gate green facts: `verify-prereqs.sh` Check P passes in board-mode (no `.pipeline.md`); `verify-routing.sh` R7 scans `docs/roadmap/` live and validates Phase (DELIVER/ASSURE valid) + Loads (deliver:roadmapper/vertical-slice/pr-review all resolve).
- **0066.002 gate over-match class (PR #288, NEEDS_REVISION):** the gate's regexes lack word/line anchoring, giving TWO demonstrated false-PASS holes that defeat its stated "no off-board work" purpose: (1) exemption scan `grep -oiE '\[no-board\]:...'` matches the marker anywhere in commit PROSE — a commit merely *describing* `[no-board]:` exempts an unlinked branch (the PR's own `pipeline/0066-*` branch mislabels as "exempt", not branch-linked, because a commit body quotes the convention); (2) trailer regex `(Board|Refs):?\s*#\d+` has no `\b`, so "dashboard #7 / keyboard: #5 / clipboard #12" → false "linked to issue #N". Precedence exempt>branch>trailer also lets a stray exemption mention MASK genuine linkage. Fix = anchor marker to line-start/trailer position + word-boundary the Board/Refs regex. Untested hard-FAIL branch: `verify_issue_exists`→`absent`→FAIL (trailer to nonexistent issue) has no self-test row. NON-issue (verified, don't re-flag): the `verify_issue_exists` network discriminator `could not resolve|not found|no issue` does NOT collide with real gh 2.96 network error ("error connecting to X / check your internet connection" → unknown → advisory PASS, correct).
- Related: [[fleet-cd-migration-pr-chain]] (staged PRs must retire forward-refs), [[archive-move-redirect-class]], [[wiki-publisher-exfil]] (same blocklist/word-boundary sanitiser class).
