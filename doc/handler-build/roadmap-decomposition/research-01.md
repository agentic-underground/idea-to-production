# Roadmap-Item Decomposition Research — Axis 1: Vertical Slices & Atomic Work Breakdown

## INVEST Criteria: User Story Right-Sizing

**Independent**
- Each story must be developable and deliverable standalone, with zero dependencies on unbuilt slices
- Minimizes integration risk; enables parallel work across team
- Failure mode: stories chained in sequence; unblocks only when predecessor ships

**Negotiable**
- Acceptance criteria are *discussion points*, not fixed contracts until spec-freeze (GO mode commit point)
- Teams can negotiate scope, priority, and interpretation with stakeholders pre-implementation
- Failure mode: rigid acceptance criteria written before discovery; derail when real implementation surfaces ambiguities

**Valuable**
- Must deliver user-meaningful capability; no pure infrastructure or "technical debt" stories without user payoff
- FOUNDRY maps this to *STORY test*: proves user value at acceptance-criteria level
- Failure mode: bulk data-layer work with deferred UI integration; learning deferred to future sprints

**Estimable**
- Team has *sufficient context* to estimate the work (complexity, skills, familiarity, ambiguity)
- If story is too fuzzy to estimate, it's too fuzzy to build; spike or refine first
- Common failure: "estimate or admit you can't"—stories that trigger "I have no idea" need pre-work

**Small**
- Completable in a single sprint/iteration; reviewable in one sitting
- FOUNDRY sets reviewability floor: diff must fit in one human code-review session (not literal LOC)
- Failure mode: three-week features; code review spans multiple days; rework risk increases exponentially

**Testable**
- Acceptance criteria form the test case; story fails if *no test can prove it works*
- Tests written in Step 3 (roadmapper protocol) pinpoint every branch, edge case, and guard clause
- Failure mode: "looks good" acceptance; no automated proof story is met; regression invisible until production

---

## Vertical Slice Principle: Thin End-to-End Architecture

**Core definition**: one thin path that touches *every layer it needs and nothing it doesn't*, shippable and reviewable alone.

**Key geometry** (from FOUNDRY/vertical-slice/SKILL.md):
- **Surfaces touched** (UI taxonomy): Capture, Display, Navigate, Instrument → minimize both
- **Crates touched** (backend): core, ui, web, mobile, server, api → minimize both
- **Stack integration**: each slice produces runnable, testable code across full path (not horizontal layers separated)

**Thinness test** (FOUNDRY §1):
1. Describable in ONE sentence as user-meaningful change
2. Diff reviewable in ONE sitting by reviewer agent (perf baseline sampling included)
3. Produces ≥1 NEW/CHANGED STORY test asserting user value
4. Shippable to production without depending on unbuilt future slice
   - If any fail: SPLIT and do first part only

**Failure modes**:
- Horizontal work ("build whole data layer first"): defers integration risk & learning to end-of-feature
- Over-sized slices: multi-day review; accumulates pre-review debt; gates downstream work
- Speculative abstraction: "we might need this later"; adds complexity unpinned by user stories
- Premature infrastructure: framework plumbing without user value; can't ship independently

---

## Atomic Job Breakdown: The Surgical Strike Pattern

**Philosophy**: Small, focused, independently reviewable work; each job *pins one behaviour*.

**Three-step breakdown** (exemplar):
1. Write a test that reproduces the issue (pins the problem)
2. Fix the code to pass the test (minimal change)
3. Add validation to prevent regression (closes escape hatch)

**Each "atomic" job**:
- Solves ONE piece of the story
- Has ≥1 test asserting it works
- Can be reviewed & merged standalone
- Unblocks downstream work immediately (no "waiting for the big feature")

**Preventing flaky tests** (FOUNDRY mandate):
- NEVER use arbitrary timeouts (`sleep`, `waitForTimeout`) in test code
- Replace every timing hack with deterministic assertions (poll for actual DOM state, API response)
- Retries are diagnostic-only, never permanent
- If test is flaky, treat as production bug: fix root cause (race condition in code, not test retry)
- Run full suite ≥3 times successively without `--retries` to confirm non-flakiness

**Coverage floor** (FOUNDRY hard gate):
- 100% code coverage is the floor, not a goal
- Every uncovered line = unpinned behaviour (defect)
- Valid alternatives: explicit `# pragma: no cover` with written justification only
- If shipping below 100%: go back and fix immediately

---

## Integration: Roadmapper + Vertical Slice + INVEST

**Roadmapper captures** (§3.3 ROADMAP.md entry):
- EARS spec (5 forms: ubiquitous, event-driven, unwanted behaviour, state-driven, optional feature)
- User stories (actor/capability/outcome)
- Acceptance criteria (numbered, Given/When/Then facts—not steps)
- Human Interface Test Plan (for every UI element: full gesture path including reload persistence)

**Development System** (§4 roadmapper, 9 steps):
- STEP 0: Write `doc/[FEATURE_TITLE]_PLAN.md` with file-by-file rationale, test strategy, resumption notes
- STEP 1: Add EARS statements to spec file (unique ID per statement, e.g. `EARS-042`)
- STEP 2: Write `.feature` files (Gherkin) covering happy/unhappy/abuse paths; tag with EARS IDs
- STEP 3: Write test code pinning every branch (100% coverage floor); tests RED at this point
- STEP 4: Run tests first time; expect failures (feature not built yet)
- STEP 5: Implement minimum code to make failing tests pass; reuse existing patterns
- STEP 6: Drive to green; run suite 3x successively; validate coverage 100%; confirm no flakiness
- STEP 7: Sync with upstream (git rebase/merge); re-run tests
- STEP 8: Write commit message (WHY/WHAT/TESTING/ROADMAP structure)
- STEP 9: Commit, push, update roadmap STATUS, update plan file, add changelog entry

**Vertical slice ledger** (each slice records):
- `SLICE-NN · <value sentence> · STORY:<name> · perf:<delta vs baseline> · shipped:<date>`
- Slice ledger is audit trail for fresh agent to reconstruct project history zero-context

---

## Testing & Validation Strategy

**STORY test** (acceptance proof):
- Browser-level test exercising full user gesture (Playwright, Cypress, etc.)
- Covers every interactive element from "Human Interface Test Plan"
- Navigates → finds element → clicks/types → verifies UI reacts → reloads → verifies persistence
- Proves user-meaningful change occurred

**Boundary & seam tests**:
- Whenever API contracts change or data layer touched: write boundary test
- Mock external dependencies; test integration points deterministically

**Perf baseline gating** (FOUNDRY station protocol):
- Each slice runs unit → module → boundary → system → STORY, each emitting perf sample
- STORY perf-delta gate must PASS against baseline before shipping
- Captures new baseline after slice ships; LEARN note recorded for marketer

**Common pitfall**: UI tests written in Step 2 (Gherkin) must become Playwright tests in Step 3; skipping the test-code pinning step leaves "looks good" acceptance with no automation.

---

## Right-Sizing: Red Flags & Guardrails

**Story is TOO BIG if**:
- Diff touches >5 files
- Code review would take >1 sitting (>60 min for expert reviewer)
- Touches >3 layers of the stack
- Requires work in unbuilt crate/module
- Acceptance criteria > 5 items
- Estimate confidence < 70%

**Story is TOO SMALL if**:
- Produces zero new STORY test
- Not independently shippable
- Only refactoring/tech debt, no user value
- Depends on another PENDING story

**The split rule** (FOUNDRY): If ANY thinness-test criterion fails, split the story and implement first part only. This prevents scope creep and enables early integration feedback.

---

## Canonical Tooling & Versions

**Spec writing**:
- EARS syntax: https://www.anagilemind.org/invest (referenced in roadmapper)
- Gherkin (Cucumber): BDD standard, language-agnostic
- Test framework per language: pytest (Python), jest (JavaScript), RSpec (Ruby), etc.

**Code coverage**:
- Python: `coverage.py`
- JavaScript: `nyc`, `c8`, or `vitest --coverage`
- Require CI gate: fail if coverage drops below baseline

**Browser testing**:
- Playwright (cross-browser, fastest loop)
- Cypress (dev-friendly, slower)
- Selenium (legacy compatibility)

**Version control & atomic commits**:
- `git add -p` (interactive staging; review every hunk)
- Conventional Commits: `[emoji] type(scope): message` (FOUNDRY protocol in `commit-message.md`)

---

## Sources

- [Agile Alliance: Vertical Slice](https://agilealliance.org/resources/experience-reports/a-tale-of-slicing-and-imagination/)
- [IEEE: Improving the User Story Agile Technique Using INVEST Criteria](https://ieeexplore.ieee.org/document/6693222/)
- [An Agile Mind: INVEST Criteria](https://www.anagilemind.org/invest)
- [Monday.com: Vertical Slice Guide](https://monday.com/blog/rnd/vertical-slice/)
- [Deep Project Manager: Vertical Slicing Agile](https://deeprojectmanager.com/vertical-slicing-agile/)
- [Greg Park: Horizontal vs Vertical Slices](https://gregpark.io/blog/building-new-features-horizontal-or-vertical-slices)
- [Adam Hannigan: Atomic Planning](https://adamhannigan81.medium.com/breaking-down-technical-tasks-with-atomic-planning-6045218b0c86)
- [Test Guild: Atomic Tests](https://testguild.com/atomic-tests/)
- FOUNDRY internal: `plugins/foundry/skills/vertical-slice/SKILL.md`, `plugins/foundry/skills/roadmapper/SKILL.md`
