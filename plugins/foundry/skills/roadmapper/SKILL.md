---
name: roadmapper
description: >
  Use this skill to manage a project ROADMAP.md — reading it, adding features to it, and driving
  features through a formal spec-to-production development system. Trigger this skill whenever
  the user says "feature request:", "I want the app to ...", "add to the roadmap", "what's on
  the roadmap", "pull the next feature", or expresses a desire for a project improvement in any
  form. Also trigger when the user asks to begin implementing a roadmap item, or when they describe
  a bug, enhancement, or new capability they want in their project. This skill covers the FULL
  lifecycle: capturing the idea, writing formal EARS specs, generating .feature files, driving
  test-first development, implementing, and committing. Use it proactively — if the user is
  discussing changes to a project in any form, this skill is almost certainly applicable.
---

# ROADMAPPER

A skill for capturing, formalising, and implementing software features using a structured, agent-readable roadmap and a test-first development system.

---

## 1. OVERVIEW

**Roadmap location — resolve in this order:**
1. **The FLEET v2 pipeline (`docs/roadmap/`)** — the **canonical surface**. The roadmap *is* the
   pipeline the FLEET continuous-delivery engine drains. Three load-bearing artifacts, each parsed by
   the engine with a regex — keep the grammar exact:
   - `docs/roadmap/.pipeline.md` — the EPIC **manifest**: 5 leading-`|` columns
     `order | epic | state | constructs | branch`, one row per EPIC (state lives here).
   - `EPIC_NNNN.md` per capability — a `## Metadata` block (single-line `**Branch**`), a section-scoped
     `## Plans` table with 3 columns `order | plan | state`, a shared-infra map, and `depends_on`.
   - `PLAN_NNNN.md` per vertical slice — back-references its `**Epic**`; no state (state is the epic's
     `## Plans` row).

   `order` is always exactly 4 digits. **Reads resolve through the `pipeline` plugin** — an **external
   FLEET marketplace plugin** (installed separately, like `token-fairness`; not shipped in this
   marketplace): when present, answer via its deterministic surface (`/pipeline:status`,
   `pipeline-cron.sh status`/`next`, `pipeline-report`). When it is **not** installed, parse the
   artifacts above **structurally** (by the leading-`|` columns, never as prose). Authoring/emission of
   these artifacts is roadmapper's job — see §3 CAPTURE. The full, version-pinned grammar (the contract
   the engine parses) is vendored at
   [`references/fleet-pipeline-standard.md`](references/fleet-pipeline-standard.md).
2. **`.i2p/roadmap/{backlog,do,doing,done}/{id}-{slug}.md`** — **LEGACY history.** The old file-per-item
   flow tree. Surfaced read-only and clearly labelled "legacy"; its backlog is migrated into the v2
   pipeline (do not write new items here, and do not treat it as a source of truth).
3. **`ROADMAP.md`** / **`docs/ROADMAP.md`** / **`doc/ROADMAP.md`** — legacy single-file roadmap, for
   non-i2p projects without the pipeline.

> **Read vs. write — scope note.** This resolution order governs **reads** ("what's on the roadmap").
> Native **v2 emission** (CAPTURE/PLAN writing `.pipeline.md` + `EPIC_NNNN.md` + `PLAN_NNNN.md`) is
> landing incrementally; until it does, §3 CAPTURE still authors the legacy surface. Do not infer from
> this section that §3 already emits v2.

The roadmap is a living document intended to be read and acted upon by both humans and AI agents. Every entry is self-contained: it carries enough context that a fresh agent, with no prior conversation history, can pick up the item and implement it correctly.

---

## 2. TRIGGERS & ENTRY POINTS

| User says / does | Action |
|---|---|
| "feature request: …" | → §3 CAPTURE |
| "I want the app to …" | → §3 CAPTURE |
| "add X to the roadmap" | → §3 CAPTURE |
| "add feature" / "new feature" / "add this" | → §3 CAPTURE |
| "what's on the roadmap?" | → §5 QUERY |
| "what's next" / "in progress" / "check status" | → §5 QUERY (filtered) |
| "pull the next feature" | → §6 PULL & PLAN |
| Selects a feature from the roadmap display | → §6 PULL & PLAN |
| "implement [feature name]" | → §6 PULL & PLAN |
| "ship it" / "make it" / "green light" / "full send" / "just build" | → §11 GO mode for resolved item |
| "ship N" / "go N" / "build N" (N = item number) | → §11 GO mode, item N |
| "talk through" / "spec it" / "flesh out" / "plan it" / "scope it" | → §11 DISCUSS mode for resolved item |
| "update N" / "edit N" / "add to N" | → §11 DISCUSS mode, item N |
| "pick it up" / "where were we" / "resume work" | → §11 RESUME protocol |
| "park it" / "defer it" / "defer N" | → Mark item DEFERRED |
| "restore N" / "undefer N" | → Mark item PENDING |

---

## 3. CAPTURING A FEATURE REQUEST

### 3.1 Understand Before You Write

Before writing anything, make sure you have enough information to produce a useful TITLE and BRIEF DESCRIPTION. Read carefully what the user has said and ask yourself:

- Is the actor (who uses this?) clear?
- Is the capability (what it does?) unambiguous?
- Is the outcome (why it matters?) evident?

**If any of these are unclear**, ask focused follow-up questions — one to three at most, grouped into a single conversational turn. Do not write the roadmap entry until you are confident. Good questions to consider:

- "Who is the primary actor for this feature — an end user, an admin, an external system?"
- "What does success look like? What changes in the product?"
- "Are there constraints — performance, security, platform, backward-compatibility?"
- "Does this replace existing behaviour or add to it?"
- "Are there edge cases you're already worried about?"
- "Does this feature add, modify, or remove any visible user-interface element (button, form field, dialog, editable table row, toggle, conditional section)?"
- If yes: "For each UI element, what is the complete human gesture? E.g. click Edit → a date field appears and is editable → type a new date → click Save → the label updates → reload → the change is still there."

**Duplicate detection**: Before writing any new entry, scan existing roadmap entries for semantic overlap. If a new request closely matches an existing PENDING or DEFERRED entry, surface it: "This sounds similar to item #N: [title]. Is this a refinement of that entry, or a distinct new feature?" If it's a refinement, enter DISCUSS mode on the existing entry (§11.5) rather than creating a duplicate.

### 3.2 Trawl Existing Documentation

Once the intent is clear, **scan the project** before writing anything:

1. Read `ROADMAP.md` (or `doc/ROADMAP.md`) to understand existing features and avoid overlap.
2. Read existing EARS specs (`.ears` files, or EARS sections in markdown) to understand the current specification landscape.
3. Read `.feature` files (Gherkin/Cucumber) to understand what is already modelled.
4. Scan test files to understand what is already exercised.
5. Skim the main source tree to identify components, services, and patterns that may be reused.

Note what you find — you will use this to write the implementation plan and to avoid
duplicating work.

### 3.3 Write the Roadmap Entry

Each roadmap entry has the following structure:

```markdown
## [N] TITLE
> STATUS: PENDING | IN PROGRESS | AWAITING MERGE | COMPLETE | DEFERRED
> ADDED: YYYY-MM-DD
> PRIORITY: HIGH | MEDIUM | LOW

> **`AWAITING MERGE`** — used only under `pr-approval` merge governance
> ([`../../knowledge/protocols/merge-governance.md`](../../knowledge/protocols/merge-governance.md)):
> the change is built, has **PASSed** the adversarial review, and its PR is open for a human to
> merge. It is *not* `IN PROGRESS` (so the phase-sensor takes no further phase action) and *not yet*
> `COMPLETE` (it isn't on `main`); it flips to `COMPLETE` when the human merges the PR.

**Brief Description**
One to three sentences. Plain language. What the feature does and why it matters.

### User Stories
- AS A <actor> I WANT <capability> SO THAT <outcome>
- AS A <actor> I WANT <capability> SO THAT <outcome>
  (one per distinct actor/outcome pair)

### EARS Specification
(Easy Approach to Requirements Syntax — formal, agent-readable)

**Ubiquitous requirements** (always true):
- The system SHALL <behaviour>.

**Event-driven requirements** (when something happens):
- WHEN <trigger> THE SYSTEM SHALL <response>.

**Unwanted behaviour requirements** (guard clauses):
- IF <condition> THEN THE SYSTEM SHALL <safeguard>.

**State-driven requirements** (while in a state):
- WHILE <state> THE SYSTEM SHALL <behaviour>.

**Optional feature requirements** (if configured):
- WHERE <feature flag / config> THE SYSTEM SHALL <behaviour>.

(Use whichever EARS forms apply. Not all five are required for every feature.)

### Acceptance Criteria
Numbered list of concrete, testable outcomes. Written as facts, not steps.
1. Given … When … Then …
2. …

### Implementation Notes
- Components / modules likely affected (from the codebase scan in §3.2).
- Patterns or utilities to reuse.
- Known risks or open questions.
- External dependencies or API contracts.

### Human Interface Test Plan
(Complete this section when the feature adds or changes any user-facing UI element.)

For each interactive element introduced or changed, describe the full human gesture path:

```
- [Element name / location]: navigate → find element → verify visible → act → verify UI reacts → verify data persists after reload
```

Example:
```
- [Edit button on round row]: navigate to Rounds panel → find "Edit" button for Round 3 →
  click Edit → verify a date input appears and is editable → type "2026-08-15" → click "Save" →
  verify round list shows "15 Aug 2026" → reload page → verify date still shows "15 Aug 2026"
- [Delete button on round row]: click "Delete" for Round 3 → verify inline confirmation prompt
  appears → click "Confirm" → verify Round 3 row is gone → reload → verify Round 3 still absent
```

This section is consumed by EARS-AGENT (Step 1), FEATURE-AGENT (Step 2), and STORY-AGENT (Step 5)
to ensure every interactive element has a browser-level story test. Any UI element not listed here
will be missing an interaction test.

### Development Plan Reference
When this feature is selected for implementation, a detailed plan will be written to: `doc/[FEATURE_TITLE]_PLAN.md` 
The plan follows THE DEVELOPMENT SYSTEM (§4).
```

Append the new entry to the roadmap file and save it. Then immediately follow §3.4.

---

### 3.4 COMMIT AFTER EVERY ROADMAP WRITE

**Any change to `ROADMAP.md` — new entry, status update, DEFER/RESTORE, DISCUSS edit, or
completion — MUST be committed and pushed immediately after the file is saved.** The roadmap
is the shared record of intent; a local-only edit is invisible to other agents and developers.

#### Commit message format for roadmap-only changes

Use the FOUNDRY commit format (from `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/commit-message.md`)
adapted for a documentation-only change. The TESTING line is omitted when no code changes.

**Adding a new entry:**
```
📝 docs(roadmap): add [N] [TITLE]

WHY:
[One sentence: why this entry is being captured and what problem it addresses.]

WHAT:
- 📝 doc/ROADMAP.md: add entry [N] [TITLE] (STATUS: PENDING, PRIORITY: [X])

ROADMAP: [N] captured
```

**Status change (IN PROGRESS, COMPLETE, DEFERRED, RESTORED):**
```
📝 docs(roadmap): mark [N] [TITLE] [STATUS]

WHY:
[One sentence: what triggered the status change.]

WHAT:
- 📝 doc/ROADMAP.md: [N] [TITLE] → STATUS: [NEW STATUS]

ROADMAP: [closes / updates] #[N]
```

**DISCUSS mode spec edit (no status change):**
```
📝 docs(roadmap): refine spec for [N] [TITLE]

WHY:
[One sentence: what was clarified or corrected.]

WHAT:
- 📝 doc/ROADMAP.md: [N] [TITLE] — updated [EARS / acceptance criteria / implementation notes]

ROADMAP: [N] updated
```

#### Commit/push sequence

```bash
git add doc/ROADMAP.md          # stage only the roadmap file
git commit -m "$(cat <<'EOF'
📝 docs(roadmap): <summary>

WHY:
<motivation>

WHAT:
- 📝 doc/ROADMAP.md: <description>

ROADMAP: <reference>
EOF
)"
git push origin main
```

#### Rules

- Stage **only** `doc/ROADMAP.md` (or the equivalent roadmap path) — never batch unrelated
  changes into the roadmap commit.
- If the roadmap file is inside a project that uses a non-`main` default branch, push to
  that branch instead.
- If the push fails (network, conflict), report the error to the user and do not retry
  silently — the user must resolve it.
- This protocol applies at every point in the skill that modifies ROADMAP.md: §3.3 (new
  entry), §6 (status → IN PROGRESS), §9 (status → COMPLETE), §11.7 (DEFER/RESTORE).

---

## 4. THE DEVELOPMENT SYSTEM

Every feature is implemented via this nine-step process. The process is **mandatory** and is referenced from every roadmap entry. Agents pulling a feature must follow it in order.

---

### STEP 0 — WRITE THE PLAN

Before touching any code, write a detailed implementation plan to:

```
doc/[FEATURE_TITLE]_PLAN.md
```

The plan must include:

- Feature title, roadmap entry number, and date.
- Summary of the EARS specification.
- Summary of the Gherkin scenarios to be written.
- Ordered list of files to be created or modified, with rationale for each.
- Test strategy: which test runner, what test file locations, naming conventions.
- Known risks and mitigations.
- A checklist version of steps 1–9 below, so progress can be tracked by ticking items.
- A "Resumption" section: instructions explicit enough for a cold-start agent to pick up
  mid-implementation without reading the conversation history.

This plan is the single source of truth during implementation. Keep it updated as you work.

---

### STEP 1 — EARS SPECIFICATION

- Locate the existing EARS spec file(s) for the project (e.g. doc/SPECIFICATION.ears.md
  or similar). Create one if none exists.
- Add or update the EARS statements for this feature, following the EARS forms defined in §3.3.
- Ensure every EARS statement is uniquely identified (e.g. `EARS-042`) so it can be referenced from test code and feature files.
- Commit-ready: spec changes are a discrete, reviewable diff.

---

### STEP 2 — FEATURE DOCUMENTATION (.feature files)

- Locate or create the appropriate `.feature` file for this area of the application.
- Write Gherkin scenarios covering:
  - **Happy path**: the system behaves correctly under normal conditions.
  - **Unhappy path**: the system handles bad or missing inputs gracefully.
  - **Abuse / adversarial path**: the system resists malformed, malicious, or boundary inputs.
- Each scenario should reference the EARS ID(s) it satisfies (as a tag or comment).
- Scenarios must be written before test code. They are the human-readable contract.
- **UI features:** For every item listed in the "Human Interface Test Plan" section, write a Gherkin scenario describing the complete browser gesture (click → see → type → confirm → reload → verify). Scenarios that describe only API behaviour ("When the client sends PUT …") are not sufficient — the scenario must describe what the user does and sees in the browser. See §3.3 Human Interface Test Plan for the required format.

Example:

```gherkin
@EARS-042
Feature: User password reset

  Scenario: Happy path — valid reset link
    Given a registered user with email "user@example.com"
    When they request a password reset
    Then a reset link is sent to "user@example.com"
    And the link expires after 60 minutes

  Scenario: Unhappy path — unknown email address
    Given no account exists for "ghost@example.com"
    When a password reset is requested for "ghost@example.com"
    Then the system responds with a generic success message
    And no email is sent

  Scenario: Abuse path — reset link reuse
    Given a valid reset link that has already been used
    When the link is visited again
    Then the system rejects it with an "already used" error
```

---

### STEP 3 — TEST CODE

- Write test code (unit, integration, or end-to-end as appropriate) that exercises the
  scenarios defined in step 2.
- Cover: happy path, unhappy path, abuse/adversarial path.
- Each test should reference the relevant EARS ID and `.feature` scenario in a comment.
- **Validate tests against the spec**: before running, re-read the EARS statements and `.feature` file and confirm each test is asserting the correct expectation under the correct condition. Fix any mismatches *now*, before running.
- Do not write implementation code yet. Tests must be red (failing) at this point because the feature does not exist.
- **UI features:** For every UI element in the "Human Interface Test Plan", write a Playwright test skeleton that exercises the full gesture path listed there. These tests will be RED because the DOM elements do not yet exist — that is correct. They define what the implementation must produce.
- **THE FOUNDRY DENSITY MANDATE:** Every behaviour you are about to implement in Step 5 must be *pinned* by a coordinate written in Step 3 — a test that locates the correct implementation. For every branch, every error path, every guard clause, every exception handler, write a test that hits it; for every behaviour, the happy / unhappy / abuse triad is table-stakes. A suite that covers only happy paths has high coverage and low density — it is under-pinned, not done. The test must exist *before* the code (it is the location, not a description). If you cannot see how to pin a path, redesign the code so it can be — do not skip the coordinate. 100% coverage is the floor that results, never the target.
- **THE FOUNDRY FLAKY TEST BAN:** A test is flaky when it sometimes passes and sometimes fails without any code change. Flaky tests are **forbidden**. They are worse than no test: they erode trust in the suite and mask real failures. When writing tests:
  - **Never use arbitrary timeouts** (`waitForTimeout`, `sleep`, `time.sleep`, `setTimeout` in test code). Replace every timing hack with a deterministic assertion — poll for the specific DOM state, API response, or condition you actually care about.
  - **Never use `retries` to paper over flakiness.** Retries are permitted only as a temporary diagnostic measure while tracking down the root cause, never as a permanent solution.
  - If a test is flaky, treat it as a bug with the same priority as a production defect. Fix the root cause (usually: replace timing hack with proper wait, or fix a race in the production code).

---

### STEP 4 — RUN TESTS (first pass — confirm expected failures)

- Run the full test suite.
- **Expected**: newly written tests fail because the feature is not implemented. Existing tests pass. If any pre-existing test is now failing, stop and investigate before proceeding.
- Document the failure surface: list which tests fail and why. This is the "gap map" that
  guides implementation.
- If tests fail for unexpected reasons (environment issues, import errors, etc.), fix those
  infrastructure problems first. They are not part of the feature gap.

---

### STEP 5 — IMPLEMENTATION

- Write the minimum production code necessary to make the failing tests pass.
- Follow the project's existing conventions (naming, structure, error handling, logging).
- Reuse existing components, utilities, and patterns identified in the codebase scan (§3.2).
- Do not modify test code during this step. The tests are the guardrails; the implementation must conform to them, not the other way around.
- If you discover that a test is genuinely wrong (tests the wrong thing, or is based on a
  misread of the spec), **stop** and return to step 3. Correct the test there, validate it
  again, then return to step 5.

---

### STEP 6 — RUN TESTS (second pass — drive to green)

- Run the full test suite repeatedly until all tests pass.
- For each failure: diagnose, fix the implementation, re-run. Never fix a test to make it pass unless the test itself is in error (see step 5 rule above).
- Check for regressions: no previously-passing test should now fail.
- When all tests are green, do a final read-through of the implementation against the EARS spec and `.feature` file. Confirm the spirit of the requirement is met, not just the letter of the tests.
- **THE FOUNDRY COVERAGE FLOOR — HARD GATE:** Run coverage and confirm **100%** before proceeding to Step 7. 100% is the floor (the consequence of pinning every behaviour), not a goal; it is the definition of done. This is not optional. This is not aspirational.
  - Every uncovered line is a defect: an *unpinned* behaviour that exists but cannot be verified.
  - If coverage is below 100%: identify every uncovered line, write the missing test, re-run. Do not proceed until the number is 100.
  - The only valid alternative to a test is an explicit `# pragma: no cover` annotation with a written justification in the same comment (e.g. dead code, OS-specific branch, intentionally untestable platform shim). Silent exclusions are forbidden.
  - If you shipped a feature and coverage was not 100%, go back and fix it — the feature is not done.
- **THE FOUNDRY FLAKY TEST BAN — SECOND CHECK:** After driving to green, run the full suite **three times in succession** without `--retries`. If any test fails in any run that passed in another, it is flaky. Fix it before proceeding. A suite that is green-once is not done; a suite that is green-three-times-in-a-row is done.

---

### STEP 7 — SYNC WITH UPSTREAM

Before committing, integrate with the upstream branch to avoid clobbering concurrent changes:

```bash
git fetch origin
git rebase origin/<main-branch>   # or merge, per project convention
```

- Run tests again after the rebase/merge to confirm nothing broke.
- Resolve any conflicts carefully, preserving both the upstream changes and the new feature.
- If conflicts affect test files, validate the resolved tests against the spec before proceeding.

---

### STEP 8 — WRITE THE COMMIT MESSAGE

> Format, emoji convention, and quality rules are defined in:
> **`${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/commit-message.md`**

Write a commit message following the WHY/WHAT/TESTING/ROADMAP structure with a Conventional
Commits type prefix on the summary line: `[emoji] type(scope): short imperative summary`.
Send to reviewer before committing.

---

### STEP 9 — COMMIT AND PUSH

```bash
git add -p          # Stage changes interactively — review every hunk
git commit          # Paste the commit message from step 8
git push origin <branch>
```

After pushing:

1. Update the roadmap entry per **merge governance** ([`../../knowledge/protocols/merge-governance.md`](../../knowledge/protocols/merge-governance.md)):
   under **direct-merge** (merged to `main`) → `STATUS: IN PROGRESS` → `STATUS: COMPLETE` + completion date;
   under **pr-approval** (branch pushed, PR opened) → `STATUS: IN PROGRESS` → `STATUS: AWAITING MERGE`,
   flipping to `COMPLETE` only once the human merges the PR.
2. Update `doc/[FEATURE_TITLE]_PLAN.md`: mark the checklist complete, add a "Completed" section with the commit hash and date.
3. If the project uses a changelog (`CHANGELOG.md`), add an entry.

---

## 5. ROADMAP QUERY ("What's on the roadmap?")

When the user asks what is on the roadmap:

> **Do not ad-hoc-read raw roadmap files. Answer through the roadmapper resolution path:**
> 1. **The FLEET v2 pipeline (preferred).** If the `pipeline` plugin (an **external FLEET marketplace
>    plugin**, installed separately) is present, answer from its deterministic surface —
>    `/pipeline:status` (or `pipeline-cron.sh status`/`next`, `pipeline-report`). Present the returned
>    view; authoritative, deterministic, ~0 LLM tokens. If it is not installed, parse the artifacts
>    **structurally** (by leading-`|` columns, not as prose): the `docs/roadmap/.pipeline.md` manifest
>    (`order | epic | state | constructs | branch`, one row per EPIC) for top-level state, then each
>    `EPIC_NNNN.md`'s section-scoped `## Plans` table (`order | plan | state`) for its slices.
> 2. **The `.i2p/roadmap/` tree — LEGACY.** Only to surface historical items, clearly labelled
>    "legacy". Enumerate by folder (`backlog`/`do`/`doing`/`done`). Never present it as the live
>    roadmap; its backlog migrates into the v2 pipeline.
> 3. **Legacy `ROADMAP.md`.** Only for non-i2p projects without the pipeline.
>
> Always note which path you used.

1. Resolve the roadmap source (above) — the v2 pipeline (`docs/roadmap/`), else legacy.
2. Display a summary table:

```
#  | Title                  | Status      | Priority | Brief Description
---|------------------------|-------------|----------|--------------------
1  | Password Reset Flow    | COMPLETE    | HIGH     | Let users reset…
2  | Dark Mode              | PENDING     | MEDIUM   | System-level theme…
3  | CSV Export             | PENDING     | LOW      | Export any list…
```

3. Ask the user which item they would like to work on next (if any), or whether they want to add a new feature.
4. If they select an item, proceed to §6.

### Filtered Queries

| User phrase | Response |
|---|---|
| "what's in progress?" / "in progress" | Show only items with STATUS: IN PROGRESS; include current step from plan file if readable |
| "what's next?" | Show next PENDING item (by roadmap order); ask GO or DISCUSS |
| "check status" | Show all non-COMPLETE items grouped: IN PROGRESS first, then PENDING by priority, then DEFERRED |

After displaying the roadmap table, GO/DISCUSS shortcuts are available inline:
- "ship 3" or "go 3" immediately triggers GO mode for item #3
- "talk through 3" triggers DISCUSS mode for item #3

These shortcuts bypass the need to re-state the full trigger phrase after seeing the table.

---

## 6. PULL & PLAN ("Pull the next feature")

"Next" means the first item with `STATUS: PENDING` in roadmap order (top to bottom),
**unless** the user specifies a different item by number or name.

Steps:

1. Read the full roadmap entry for the selected feature.
2. Change its `STATUS` to `IN PROGRESS` in the roadmap file and save.
3. Perform the codebase scan described in §3.2 (if not already done for this feature).
4. Execute **STEP 0** of the Development System: write `doc/[FEATURE_TITLE]_PLAN.md`.
5. Present the plan to the user for confirmation before beginning implementation. After presenting, say:
   > "Plan is ready. Say **'green light'** to begin implementation, **'talk through'** to revisit any part of the spec, or **'park it'** to defer this feature."
6. On GO authorization ("green light" or equivalent), proceed through steps 1–9 of the Development System.

---

## 7. ROADMAP FILE TEMPLATE

Use this template when creating a new `ROADMAP.md`:

```markdown
# Project Roadmap

> Last updated: YYYY-MM-DD
> Maintained by: [team / agent]

This document is the authoritative list of planned features for this project.
Each entry is self-contained and can be acted upon by an AI agent or developer without additional context. Features are implemented using THE DEVELOPMENT SYSTEM defined in the ROADMAPPER skill.

---

## Status Legend
- **PENDING** — not yet started
- **IN PROGRESS** — actively being implemented
- **SUSPENDED** — mid-implementation pause; plan file has resumption instructions
- **COMPLETE** — shipped
- **DEFERRED** — postponed, reason noted in entry

---

<!-- Feature entries follow -->
```

---

## 8. EARS QUICK REFERENCE

See `${CLAUDE_PLUGIN_ROOT}/knowledge/specs/ears.md` for the full EARS forms, mandatory rules,
good/bad examples, ID assignment convention, and coverage requirements.

Summary: five forms (Ubiquitous, Event-driven, Unwanted behaviour, State-driven,
Optional feature). Every statement: one behaviour, unique ID (`EARS-{NNN}`),
independently testable, no vague qualifiers.

---

## 9. QUALITY GATES

See `references/quality-gates.md` for the full gate table, blocking rules,
and gate failure protocol.

Summary: every transition from Step N to Step N+1 requires all gate conditions
met and reviewer PASS before advancing. No partial advancement.

---

## 10. EDGE CASES & AGENT GUIDANCE

**"The test is wrong"**: If during step 5 you believe a test is incorrect, do not modify it in place. Return to step 3, re-validate the test against the EARS spec and .feature file, correct it there with documented reasoning, then re-proceed. This preserves the audit trail.

**Partial implementation**: If a feature is too large for one session, commit what is done (with tests green for the completed portion) and update the plan file with a "Resumption" section describing exactly what remains. Mark the roadmap item `IN PROGRESS`.

**Conflicting requirements**: If a new feature's EARS statements conflict with existing ones, flag the conflict explicitly in the plan, propose a resolution, and seek user confirmation before proceeding.

**No test runner found**: If the project has no established test framework, ask the user which they prefer before writing test code. Document the choice in the plan file.

**Feature already partially implemented**: If the codebase scan reveals partial work, document it in the plan, write tests that expose the gap, and proceed from step 4. Do not credit the partial implementation as satisfying the spec until all tests pass.

**Branching strategy**: If the project uses feature branches, create one before beginning (`git checkout -b feature/[FEATURE_TITLE]`) and note the branch in the plan file.

**Branches must not be left "dangling"**: If the project uses feature branches, when a feature implementation is complete, the branch must be merged to main and deleted. Do not introduce confusion and cognitive load to the project by creating branches that may or may not contain valuable code. Prefer staying on main branch when developing to creating a new feature branch. Do not delete a branch until or unless the code has been merged to main branch.

**Prefer trunk-based development**: Unless the repository shows evidence of feature-branching, use trunk-based development and stay on main branch when creating new features.

**Spec gap found during GO mode**: Do not improvise a fix to the spec or the test. Surface the specific gap to the user and pause: "I found a gap in EARS-042: it doesn't specify what happens when [condition]. I need to enter DISCUSS mode to resolve this before I can proceed." Wait for user to authorize DISCUSS mode. After the gap is resolved and the user re-authorizes GO, resume from where execution stopped — do not restart from Step 0.

**User invokes GO with no feature resolved**: Apply §11.1 reference resolution. If still ambiguous after all strategies, show the roadmap table and require an explicit selection before entering GO mode. Never guess which feature to implement.

**User invokes DISCUSS on an IN PROGRESS item**: Warn before switching: "[TITLE] is currently IN PROGRESS. Switching to DISCUSS mode will SUSPEND implementation — any in-progress plan steps must be re-verified when you return. Confirm? (yes / cancel)" On confirm, set STATUS: SUSPENDED and enter DISCUSS mode.

**User says GO on a DEFERRED item**: Confirm: "[TITLE] is DEFERRED. Move it back to PENDING and begin implementation? (yes / cancel)" On confirm, restore to PENDING then enter GO mode.

**Overlapping features during GO**: If a second feature is mentioned while one is IN PROGRESS, do not silently switch. Acknowledge the new mention: "I'm currently executing [TITLE-1]. Did you want to pause that and start [TITLE-2], or finish [TITLE-1] first?"

---

## 11. ROADMAP ITEM RESOLUTION & MODE DISPATCH

This section governs how an agent (a) identifies which roadmap item a user is referring to and (b) determines whether to operate in DISCUSS mode (edit the spec) or GO mode (execute the plan).

The core principle is the **work-authorization commit point** from job-lifecycle theory: once a job is authorized to execute (GO), its specification freezes and becomes the contract. Changes to the spec after authorization require explicit re-authorization through DISCUSS mode. This is not a preference — it is the invariant that makes TDD work. Editing acceptance criteria or EARS statements after Step 2 would invalidate already-written test code (Step 3) and break the contract.

---

### 11.1 Reference Resolution

When a user message references a roadmap item, resolve it before acting. Resolution is always performed against the live ROADMAP.md. Strategies, in order:

1. **Explicit number** — "roadmap 3", "item 5", "feature #2", "ship 4", "#3" → use that number
2. **Explicit name** — "the auth feature", "the CSV export", "dark mode" → fuzzy match against entry titles
3. **Context from conversation** — "it", "that", "this one", "the feature we were just discussing" → use the most recently mentioned item in the current session
4. **Implicit: IN PROGRESS** — if exactly one item has STATUS: IN PROGRESS, it is the implied item
5. **Unresolvable** — if steps 1–4 all fail, display the roadmap table (§5 format) and ask the user to select an item by number before proceeding

Do NOT guess or act on an ambiguous reference. Precision matters because GO mode is irreversible in practice (plan files get written, status changes, implementation begins).

---

### 11.2 Job-Lifecycle Model

Each roadmap item passes through these lifecycle states. STATUS in the roadmap entry reflects the current state:

```
PENDING ──[DISCUSS]──▶ PENDING (refined spec)
PENDING ──[GO]──────▶ IN PROGRESS ──[complete]──▶ COMPLETE
PENDING ──[DEFER]───▶ DEFERRED ──[restore]──────▶ PENDING
IN PROGRESS ──[DISCUSS gap found]──▶ SUSPENDED ──[spec fixed + GO]──▶ IN PROGRESS
IN PROGRESS ──[session ends]───────▶ SUSPENDED ──[resume]──────────▶ IN PROGRESS
```

The **commit point** — the moment GO is authorized — freezes the spec. Before commit: spec is *mutable* (DISCUSS mode). After commit: spec is *frozen* (GO mode); only STATUS may change in the roadmap entry.

The Status Legend in §7 ROADMAP FILE TEMPLATE should include **SUSPENDED** for items paused mid-implementation.

---

### 11.3 GO/DISCUSS Mode Dispatch

Mode is determined by the user's invocation phrase, resolved in this order:

| User phrase pattern | Mode | Entry point |
|---|---|---|
| GO hook: "ship it", "make it", "green light", "full send", "just build", "ship N", "go N", "build N" | **GO** | §11.4 |
| DISCUSS hook: "talk through", "spec it", "flesh out", "plan it", "scope it", "update N", "edit N" | **DISCUSS** | §11.5 |
| Resume hook: "pick it up", "where were we", "resume work" | **RESUME** | §11.6 |
| Bare reference only: "roadmap 3", "item 5", "[feature name]" with no mode hook | **SURFACE** | Display full entry, ask GO or DISCUSS |
| Ambiguous: "implement X", "work on X" (no explicit hook) | **AUTO** | Check STATUS: if PENDING → ask; if IN PROGRESS → GO; if SUSPENDED → RESUME |

If the user enters a GO or DISCUSS hook without a resolved item (§11.1 produced no match), resolve the item first (§11.1), then enter the dispatched mode.

---

### 11.4 GO Mode — Rules

GO mode is the executive phase. The spec is frozen. The DEV_SYSTEM (§4) runs.

**What the agent MAY do:**
- Execute Development System Steps 0–9 in order
- Write and update `doc/[FEATURE_TITLE]_PLAN.md`
- Write EARS IDs, .feature files, test code, implementation code
- Update the roadmap entry STATUS field only (PENDING → IN PROGRESS → COMPLETE)
- Add a completion date to the roadmap entry when setting COMPLETE

**What the agent MUST NOT do:**
- Edit the roadmap entry's EARS Specification section
- Edit the roadmap entry's User Stories section
- Edit the roadmap entry's Acceptance Criteria section
- Begin a different feature while this one is IN PROGRESS (without explicit user direction)

**Spec gap found during GO** — if implementation reveals that the spec is incomplete, wrong, or contradictory, the agent MUST stop immediately (do not improvise), surface the gap explicitly, wait for DISCUSS mode authorization, resolve the gap in DISCUSS mode (§11.5), then return to GO mode and continue from where execution stopped.

---

### 11.5 DISCUSS Mode — Rules

DISCUSS mode is the deliberative phase. The spec is mutable. The agent asks questions, proposes changes, and aligns with the user. No implementation artefacts are produced.

**What the agent MAY do:**
- Edit any part of the roadmap entry (user stories, EARS spec, acceptance criteria, implementation notes, priority, description)
- Add new EARS statements or modify existing ones
- Ask clarifying questions (one at a time, per IDEATOR convention)
- Propose structural changes to the entry
- Re-number EARS IDs if the set changes significantly

**What the agent MUST NOT do:**
- Write `doc/[FEATURE_TITLE]_PLAN.md` (that is Step 0, a GO-mode artefact)
- Write .feature files or test code
- Write implementation code
- Change STATUS to IN PROGRESS (that is the GO mode commit point)

**End of DISCUSS mode** — when the user signals readiness ("that's good", "looks right", "I'm happy with that", "done", "ready to go"), ask:

> "The spec looks solid. Ready to implement? Say **'green light'** to begin, or **'plan it'** if you want to review the implementation plan first."

This single prompt makes the GO/DISCUSS boundary explicit and creates a natural commit point.

---

### 11.6 RESUME Protocol

When user says "pick it up", "where were we", or "resume work":

1. Read ROADMAP.md and find all items with STATUS: IN PROGRESS or SUSPENDED
2. If exactly one: proceed to step 3. If multiple: list them and ask which one.
3. Read `doc/[FEATURE_TITLE]_PLAN.md` for that item
4. Identify the last completed step from the plan's checklist
5. Report to user:
   > "Resuming [TITLE]. Last completed: Step N ([step name]). Next: Step N+1 ([step name]). The plan is at doc/[FEATURE_TITLE]_PLAN.md. Ready to continue? ('green light' to go, or 'talk through' to review)"
6. Wait for explicit GO authorization before resuming execution

RESUME never auto-starts execution. The user must explicitly authorize GO.

---

### 11.7 DEFER / RESTORE

**DEFER** ("park it", "defer it", "defer N"):
1. Resolve the referenced item (§11.1)
2. Ask: "Reason for deferring? (optional — press enter to skip)"
3. Set STATUS: DEFERRED and add `> DEFERRED: YYYY-MM-DD` and reason (if given) to the entry
4. Save and confirm

**RESTORE** ("restore N", "undefer N"):
1. Resolve the referenced item (§11.1)
2. Set STATUS: PENDING, remove the DEFERRED line
3. Save and confirm: "[TITLE] is back in the queue."

---

### 11.8 GO Hook Reference Card

When the roadmapper skill is invoked fresh (no roadmap item already in context from the conversation), include this reference card in the first response — but only if the user hasn't already invoked a mode hook in their opening message:

```
Quick reference — mode hooks:
  green light / ship it / make it / full send  →  GO (implement now)
  talk through / spec it / flesh out / plan it →  DISCUSS (refine spec)
  pick it up / where were we / resume work     →  RESUME (continue in-progress)
  what's next / in progress / check status     →  QUERY (status overview)
```

---

## 12. SELF-IMPROVEMENT PROTOCOL

ROADMAPPER carries the KAIZEN self-improvement covenant. Trigger this protocol
when you observe any of the following:

- A user correction that reveals a gap in the question bank or mode hooks
- A recurring edge case not covered by §10
- A status transition not represented in the Status Legend (§7)
- Repeated confusion about scope, priority, or brief fields

### 12.1 When to trigger

- After any session where a user corrects a ROADMAPPER behaviour
- After every 5th roadmap session (track mentally within session)
- When the inspector surfaces a ROADMAPPER finding in `FOUNDRY_INSPECTION_REPORT.md`

### 12.2 Self-improvement steps

1. **Identify the change type:**
   - Missing mode hook → add to §11
   - Gap in question bank → add to §5 or §6
   - Status legend gap → add to §7
   - Edge case → add to §10

2. **Write the proposed change** as a diff-style description:
   > "Proposed addition to §7 Status Legend: BLOCKED — item cannot progress
   > due to external dependency. Rationale: two sessions surfaced this case."

3. **Verify covenant compliance before applying:**
   - [ ] Single responsibility (S) — the change does one thing
   - [ ] Open/Closed (O) — extends, does not rewrite existing sections
   - [ ] No downstream documents break (L)
   - [ ] Does not force users of one feature to change workflow (I)
   - [ ] Depends on the roadmap abstraction, not session specifics (D)

4. **Apply on user approval.** Commit with prefix `skill:`.