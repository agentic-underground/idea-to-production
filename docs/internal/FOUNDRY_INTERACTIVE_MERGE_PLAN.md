# FOUNDRY Interactive Merge Plan — Item #33

**Date:** 2026-06-14
**Branch context:** feature/33-interactive-merge-pr
**Planned by:** foundry-builder-lead

---

## 1. Item Brief and Scope Summary

**Item #33 — Interactive "Merge PR now?" — `gh pr merge` on user approval**

This is a **markdown-only** change. No Rust, JS, or Python files are touched. The
scope is confined to two protocol documents:

1. `plugins/foundry/agents/lifecycle-orchestrator.md` — replaces the static
   AWAITING MERGE callout (the block beginning at the `## AWAITING MERGE — pause and prompt`
   section, lines ~217-236) with an interactive yes/no branch that offers to call
   `gh pr merge` immediately.

2. `plugins/foundry/knowledge/protocols/merge-governance.md` — documents the
   interactive yes/no path as a formally described sub-protocol within the existing
   `pr-approval` section.

**What does NOT change:**
- The direct-merge mode (unchanged)
- The always-on adversarial review gate (unchanged)
- The post-merge completion handler logic (unchanged — it is merely reached via a
  new path)
- Any code, test runner, or infrastructure file

**Value delivered:** The agent no longer hard-stops and waits for the user to manually
navigate to GitHub and click merge. On approval the merge happens in-session, the
completion handler runs immediately, and DELIVERY_COMPLETE is emitted within the same
conversation turn.

---

## 2. Files Changed and Exact Sections

### File 1 — `plugins/foundry/agents/lifecycle-orchestrator.md`

**Absolute path:** `/home/user/Code/idea-to-production/plugins/foundry/agents/lifecycle-orchestrator.md`

**Section to replace:** `## AWAITING MERGE — pause and prompt (pr-approval mode)`
(current content: lines 217-235)

**Current behaviour (to be replaced):**
The section unconditionally halts the loop, emits a static callout telling the user to
go and merge manually, writes loop checkpoint to `IN_PROGRESS.md`, and waits for the
user to send a post-merge signal.

**New behaviour (replacement content):**
The section keeps the PR URL extraction step (step 1 is unchanged) and the
`IN_PROGRESS.md` checkpoint write. It then replaces the static callout with an
interactive prompt and a three-way branch:

- **Path A (yes + gh available):** runs `gh pr merge {pr_number} --merge`, verifies
  via `gh pr view {pr_number} --json state,mergedAt` that `state == "MERGED"`, then
  immediately enters the post-merge completion handler (the existing `## Post-merge
  completion handler` section) without waiting for a further user signal.

- **Path B (no):** emits the existing static callout (PR URL visible), writes
  `IN_PROGRESS.md` with state `AWAITING_MERGE`, halts. No files are modified beyond
  the checkpoint. Existing behaviour is preserved exactly.

- **Path C (gh failure / unauthenticated / merge rejected):** surfaces the error text
  verbatim, falls back to Path B (manual-merge path), explicitly states that no
  sentinel has been written and no ROADMAP.md has been modified so there is no
  sentinel corruption.

The `## Post-merge completion handler` section is NOT changed — it is reachable from
both the new Path A and from the legacy user-signal flow.

### File 2 — `plugins/foundry/knowledge/protocols/merge-governance.md`

**Absolute path:** `/home/user/Code/idea-to-production/plugins/foundry/knowledge/protocols/merge-governance.md`

**Section to update:** `### pr-approval (default — human merges)`

**Current content:** four steps ending with "STOP. The human reviews and clicks merge +
close." followed by an explanatory paragraph.

**Addition (append within the pr-approval section, after the existing four steps):**

A new sub-section titled `#### Interactive merge offer (pr-approval + in-session)` that
describes the optional in-session offer:

- Triggered when the orchestrator reaches `AWAITING_MERGE` and `gh` is authenticated.
- The agent asks "Merge PR now? [yes/no]" once; the answer governs all three paths
  (yes/no/failure) per the same logic as the lifecycle-orchestrator change above.
- Clarifies that this is still `pr-approval` mode — the human is still approving (via
  the in-session "yes"); the agent is not self-merging autonomously.
- States the fallback: on "no" or on `gh` failure, the behaviour is identical to the
  classic pr-approval halt (step 4: STOP, human merges via GitHub UI).

---

## 3. EARS IDs — Acceptance Criteria Paths

Pre-assigned identifiers: `#33-AC1`, `#33-AC2`, `#33-AC3`.

**#33-AC1 — Happy path: yes + gh available**

> WHEN the lifecycle-orchestrator reaches the `AWAITING_MERGE` state
> AND the user answers "yes" to the "Merge PR now?" prompt
> AND `gh` is authenticated and the PR is open,
> THEN the system SHALL execute `gh pr merge {pr_number} --merge`,
> AND confirm `state == "MERGED"` via `gh pr view {pr_number} --json state,mergedAt`,
> AND proceed immediately to the post-merge completion handler,
> AND update `ROADMAP.md` status to `COMPLETE` with `COMPLETED: YYYY-MM-DD`,
> AND emit `SENTINEL::DELIVERY_COMPLETE::ROADMAP-{N}::COMPLETE::{commit_hash}`,
> AND sync the flow canvas card to status `done`,
> AND display the completion summary to the user.

**#33-AC2 — Decline path: no**

> WHEN the lifecycle-orchestrator reaches the `AWAITING_MERGE` state
> AND the user answers "no" to the "Merge PR now?" prompt,
> THEN the system SHALL emit the PR URL in a visible callout,
> AND write `IN_PROGRESS.md` with state `AWAITING_MERGE` and the PR URL,
> AND halt without modifying any other file,
> AND the PR SHALL remain open and the roadmap item SHALL remain in status `AWAITING MERGE`.

**#33-AC3 — Failure path: gh unauthenticated or merge fails**

> WHEN the lifecycle-orchestrator reaches the `AWAITING_MERGE` state
> AND the user answers "yes" to the "Merge PR now?" prompt
> AND `gh pr merge` exits with a non-zero status OR `gh pr view` does not return
> `state == "MERGED"`,
> THEN the system SHALL surface the verbatim error text to the user,
> AND fall back to the manual-merge path (Path B behaviour),
> AND SHALL NOT write `SENTINEL::DELIVERY_COMPLETE`,
> AND SHALL NOT modify `ROADMAP.md`,
> AND the `IN_PROGRESS.md` checkpoint SHALL carry state `AWAITING_MERGE` (not COMPLETE).

---

## 4. Test Strategy

This item is markdown-only. There are no compilation steps, no unit tests in the
traditional sense, and no runtime. Tests are shell scripts that grep the target
markdown files for required protocol language. Story tests are doc-review passes.

### 4.1 Shell test scripts

All scripts are non-destructive read-only greps. They exit 0 on pass, 1 on fail, and
print a clear message.

**Script 1 — `tests/33-ac1-yes-path.sh`**

Verifies lifecycle-orchestrator.md contains language for the yes/gh-available path.

```sh
#!/usr/bin/env bash
# Test: #33-AC1 — yes path language present in lifecycle-orchestrator.md
set -euo pipefail
TARGET="/home/user/Code/idea-to-production/plugins/foundry/agents/lifecycle-orchestrator.md"

fail() { echo "FAIL #33-AC1: $1"; exit 1; }

grep -q 'gh pr merge' "$TARGET" \
  || fail "'gh pr merge' invocation missing"

grep -q 'Merge PR now' "$TARGET" \
  || fail "Interactive prompt 'Merge PR now?' missing"

grep -q 'state.*MERGED\|MERGED.*state' "$TARGET" \
  || fail "Merge verification check (state == MERGED) missing"

grep -q 'post-merge completion handler' "$TARGET" \
  || fail "Reference to post-merge completion handler missing from yes-path"

echo "PASS #33-AC1"
```

**Script 2 — `tests/33-ac2-no-path.sh`**

Verifies lifecycle-orchestrator.md contains language for the no/halt path.

```sh
#!/usr/bin/env bash
# Test: #33-AC2 — no path language present in lifecycle-orchestrator.md
set -euo pipefail
TARGET="/home/user/Code/idea-to-production/plugins/foundry/agents/lifecycle-orchestrator.md"

fail() { echo "FAIL #33-AC2: $1"; exit 1; }

grep -q 'AWAITING_MERGE' "$TARGET" \
  || fail "AWAITING_MERGE sentinel/state string missing"

grep -q 'IN_PROGRESS.md' "$TARGET" \
  || fail "IN_PROGRESS.md checkpoint write missing"

grep -q 'no.*halt\|halt.*no\|answer.*no\|no.*PR.*open' "$TARGET" \
  || fail "No-answer halt behaviour missing"

echo "PASS #33-AC2"
```

**Script 3 — `tests/33-ac3-failure-path.sh`**

Verifies lifecycle-orchestrator.md contains language for the gh-failure/fallback path.

```sh
#!/usr/bin/env bash
# Test: #33-AC3 — failure/fallback path language present in lifecycle-orchestrator.md
set -euo pipefail
TARGET="/home/user/Code/idea-to-production/plugins/foundry/agents/lifecycle-orchestrator.md"

fail() { echo "FAIL #33-AC3: $1"; exit 1; }

grep -q 'fail\|failure\|error\|unauthenticated' "$TARGET" \
  || fail "Failure/error path not mentioned"

grep -q 'fall.*back\|manual.*merge\|manual-merge' "$TARGET" \
  || fail "Fallback to manual-merge path not mentioned"

grep -q 'sentinel.*corrupt\|no sentinel\|sentinel corruption\|not.*DELIVERY_COMPLETE' "$TARGET" \
  || fail "Sentinel corruption / no-sentinel guarantee missing"

echo "PASS #33-AC3"
```

**Script 4 — `tests/33-merge-governance-interactive.sh`**

Verifies merge-governance.md contains the interactive-offer sub-section.

```sh
#!/usr/bin/env bash
# Test: merge-governance.md documents the interactive yes/no path
set -euo pipefail
TARGET="/home/user/Code/idea-to-production/plugins/foundry/knowledge/protocols/merge-governance.md"

fail() { echo "FAIL #33-governance: $1"; exit 1; }

grep -q 'Interactive merge offer\|interactive merge' "$TARGET" \
  || fail "Interactive merge offer sub-section missing"

grep -q 'yes.*no\|yes/no\|no.*yes' "$TARGET" \
  || fail "yes/no prompt description missing"

grep -q 'pr-approval' "$TARGET" \
  || fail "Clarification that this is still pr-approval mode missing"

grep -q 'gh.*failure\|failure.*gh\|gh.*fail\|fall.*back' "$TARGET" \
  || fail "gh failure fallback mention missing"

echo "PASS #33-governance"
```

### 4.2 Story tests (doc-review pass)

A story test for a markdown-only item is a structured doc-review. The reviewer reads
the two changed files and verifies:

1. **Internal consistency:** the yes/no prompt described in lifecycle-orchestrator.md
   and the interactive-merge-offer section in merge-governance.md describe the same
   three paths with no contradictions.

2. **Completeness:** all three EARS paths (#33-AC1, #33-AC2, #33-AC3) are addressed
   in lifecycle-orchestrator.md with no gap (no path leads to an unspecified state).

3. **Sentinel hygiene:** the yes-path explicitly calls the existing post-merge
   completion handler (no duplication of that handler's steps inline); the no-path and
   failure-path do NOT emit DELIVERY_COMPLETE.

4. **merge-governance.md additive-only:** the existing `pr-approval` and
   `direct-merge` sections are untouched; the new sub-section is purely additive.

---

## 5. Implementation Plan

### 5.1 Changes to `lifecycle-orchestrator.md`

Replace the content of the `## AWAITING MERGE — pause and prompt (pr-approval mode)`
section (currently lines 217-235). Keep the section heading and step 1 (PR URL
extraction). Replace step 2 (the static callout) and step 3 (halt) with the following
structure:

```markdown
## AWAITING MERGE — pause and prompt (pr-approval mode)

When step-9 returns the `AWAITING_MERGE` sentinel, the active loop **HALTS** unless
the user approves an immediate in-session merge. Before halting (or merging), the
orchestrator MUST:

1. Extract the PR URL and PR number from the sentinel payload:
   `SENTINEL::AWAITING_MERGE::ROADMAP-{N}::AWAITING_MERGE::{pr_url}`

2. Write loop checkpoint to `IN_PROGRESS.md` with state `AWAITING_MERGE` and the PR
   URL. (Written before the prompt — if the session dies during the prompt, the
   checkpoint is intact.)

3. **Offer an interactive merge.** Present this prompt to the user:

   > **Item #{N} is built and reviewed — your PR is ready:**
   > {pr_url}
   >
   > **Merge PR now? [yes / no]**
   > - Reply **yes** and I will run `gh pr merge {pr_number} --merge` immediately,
   >   confirm the merge, mark item #{N} COMPLETE, update the flow board, and record
   >   delivery — all in this session.
   > - Reply **no** to leave the PR open and merge it yourself via the GitHub UI.
   >   Once merged, reply "merged" (or run `/i2p-lifecycle post-merge {N}`) and I
   >   will complete the delivery record.

4. **Branch on the answer:**

   **Path A — answer is "yes" and `gh` is available:**
   a. Run `gh pr merge {pr_number} --merge`.
   b. Verify: run `gh pr view {pr_number} --json state,mergedAt` and confirm
      `state == "MERGED"`. If not yet MERGED, surface the response and wait — do not
      proceed to the completion handler.
   c. On confirmed MERGED: proceed immediately to the **Post-merge completion
      handler** below (no further user signal required).

   **Path B — answer is "no":**
   - The `IN_PROGRESS.md` checkpoint (written in step 2) stands.
   - No other files are modified.
   - The loop halts. The PR remains open. The item remains AWAITING MERGE.
   - The user merges via the GitHub UI and sends the post-merge signal when ready.

   **Path C — `gh pr merge` fails (non-zero exit, unauthenticated, or merge
   rejected) OR `gh pr view` does not return `state == "MERGED"`:**
   - Surface the verbatim error text to the user.
   - Fall back to Path B (manual-merge path):
     - `IN_PROGRESS.md` checkpoint (step 2) stands unchanged.
     - `ROADMAP.md` is NOT modified.
     - `SENTINEL::DELIVERY_COMPLETE` is NOT emitted.
     - No sentinel corruption has occurred — the sentinel chain ends at
       `AWAITING_MERGE`.
   - Instruct the user to merge via the GitHub UI and send the post-merge signal.
```

The `## Post-merge completion handler` section immediately following is **not changed**.

### 5.2 Changes to `merge-governance.md`

In the `### pr-approval (default — human merges)` section, append a new sub-section
after the existing step 4 and its explanatory paragraph:

```markdown
#### Interactive merge offer (pr-approval + in-session)

When the lifecycle-orchestrator reaches `AWAITING_MERGE` and `gh` is authenticated,
it MAY offer an interactive "Merge PR now? [yes/no]" prompt rather than a static halt.
This is still `pr-approval` mode: the human is approving via the in-session answer;
the agent is not self-merging autonomously. The adversarial review gate has already
passed before this point.

Three paths:

- **yes (gh succeeds):** `gh pr merge {pr_number} --merge` is run, merge is verified
  (`state == "MERGED"`), and the post-merge completion handler executes immediately.
  No separate user signal ("merged") is needed.

- **no:** identical to the classic pr-approval halt — STOP, the human merges via the
  GitHub UI, and sends the post-merge signal when ready.

- **gh failure or unauthenticated:** error surfaced verbatim; falls back to the "no"
  path (classic halt). `ROADMAP.md` is not modified and no `DELIVERY_COMPLETE`
  sentinel is emitted — the sentinel chain is clean.

The interactive offer does not change the mode. It does not bypass the adversarial
review. It does not grant the agent merge autonomy. It is a convenience: the human
says "yes" once and the delivery completes in-session.
```

---

## 6. Commit Message Format

This item changes only markdown files in `plugins/foundry/`. The correct Conventional
Commits type is `agent` (marketplace-source artefact class, per commit-message.md §10)
for the orchestrator change, and `docs` for the governance doc. Since both land in a
single commit, the primary artefact wins: `agent`.

```
✨ agent(lifecycle-orchestrator): add interactive yes/no merge offer on AWAITING MERGE

WHY:
The static AWAITING MERGE halt required the user to leave the session, navigate
to GitHub, click merge, return, and type "merged". Roadmap item #33 replaces this
with a single in-session prompt so delivery can complete without leaving the
conversation.

WHAT:
- 📐 #33-AC1, #33-AC2, #33-AC3: interactive merge offer with yes/no/failure paths
- 📝 plugins/foundry/agents/lifecycle-orchestrator.md: replace static AWAITING MERGE
  callout with three-way interactive branch (yes/no/gh-failure)
- 📝 plugins/foundry/knowledge/protocols/merge-governance.md: add interactive merge
  offer sub-section to pr-approval mode documentation

TESTING:
Shell grep tests: tests/33-ac1-yes-path.sh, tests/33-ac2-no-path.sh,
tests/33-ac3-failure-path.sh, tests/33-merge-governance-interactive.sh — all PASS.
Story test: doc-review confirms three paths internally consistent, sentinel hygiene
clean, merge-governance.md additive-only. No regressions.

ROADMAP: item #33
```

> Note: this origin is `agentic-underground/*` (allowlisted). Use `ROADMAP: item #33`
> (not `closes #33`) in the commit footer; the PR body carries `Closes #{github-issue}`
> per merge-governance.md §Org-allowlist.

---

## 7. Definition of Done Checklist

All gates must be checked before the PR is opened.

### Specification

- [ ] `#33-AC1` EARS statement written and reviewed (EARS-REVIEWER PASS)
- [ ] `#33-AC2` EARS statement written and reviewed (EARS-REVIEWER PASS)
- [ ] `#33-AC3` EARS statement written and reviewed (EARS-REVIEWER PASS)
- [ ] Gherkin feature file written covering all three paths (BDD-REVIEWER PASS)

### Implementation

- [ ] `plugins/foundry/agents/lifecycle-orchestrator.md` `## AWAITING MERGE` section
  replaced with the three-way interactive branch per Section 5.1
- [ ] `plugins/foundry/knowledge/protocols/merge-governance.md` interactive-offer
  sub-section added under `### pr-approval` per Section 5.2
- [ ] No other files modified (markdown-only scope confirmed via `git diff --stat`)

### Tests

- [ ] `tests/33-ac1-yes-path.sh` exits 0 (PASS)
- [ ] `tests/33-ac2-no-path.sh` exits 0 (PASS)
- [ ] `tests/33-ac3-failure-path.sh` exits 0 (PASS)
- [ ] `tests/33-merge-governance-interactive.sh` exits 0 (PASS)
- [ ] Story test (doc-review): three paths internally consistent between both files
- [ ] Story test: `## Post-merge completion handler` not duplicated inline
- [ ] Story test: merge-governance.md changes are additive-only (existing sections intact)

### Sentinel hygiene

- [ ] Yes-path proceeds to `## Post-merge completion handler` (existing section) — no
  new handler code written inline
- [ ] No-path and failure-path do NOT emit `SENTINEL::DELIVERY_COMPLETE`
- [ ] `IN_PROGRESS.md` checkpoint is written before the prompt (not after)
- [ ] Failure-path explicitly states sentinel chain ends at `AWAITING_MERGE`

### Review and delivery

- [ ] EARS-REVIEWER PASS on all three EARS statements
- [ ] BDD-REVIEWER PASS on feature file
- [ ] TEST-DESIGN-REVIEWER PASS on shell test scripts
- [ ] DOCS-REVIEWER PASS on both changed markdown files
- [ ] PR-REVIEWER (adversarial) PASS before PR is opened
- [ ] Commit message follows FOUNDRY format (WHY / WHAT / TESTING / ROADMAP) — PASS
- [ ] PR body carries `Closes #{github-issue}` (allowlisted origin)
- [ ] ROADMAP.md item #33 updated to AWAITING MERGE after PR is opened
- [ ] On merge: ROADMAP.md updated to COMPLETE, `DELIVERY_COMPLETE` sentinel emitted,
  flow canvas synced to `done`, completion summary shown

---

## 8. Resumption Instructions

If this plan is loaded cold by a new session:

1. Read `/home/user/Code/idea-to-production/docs/internal/FOUNDRY_INTERACTIVE_MERGE_PLAN.md`
   (this file) for the full item context.
2. Read `/home/user/Code/idea-to-production/plugins/foundry/agents/lifecycle-orchestrator.md`
   to see the current state of the `## AWAITING MERGE` section.
3. Read `/home/user/Code/idea-to-production/plugins/foundry/knowledge/protocols/merge-governance.md`
   to see the current state of the `### pr-approval` section.
4. Check whether a `CHECKPOINT_*.md` exists at the project root — if so, restore loop
   state from it and continue from `current_stage`.
5. If no checkpoint exists, begin at step-0-plan with item #33 brief (Section 1 of
   this file) and the decomposition in Sections 3–5.

---

## 9. Self-Improvement Flags

No missing VALUE_HANDLERs required for this item (markdown-only, no new stack).

Flag for KAIZEN review: the static AWAITING MERGE halt is a friction point that
surfaced because the orchestrator had no `gh` invocation path at the AWAITING_MERGE
boundary. Now that the pattern exists (offer → branch → verify → complete), any future
item that introduces a similar "agent offers to automate a human step" should be
modelled on this three-path (yes/no/failure) structure. Recommend adding this pattern
to `knowledge/orchestration/orchestration-loop.md` as a named pattern
("interactive-offer branch") for reuse.
