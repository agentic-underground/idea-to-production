# Cached review — FOUNDRY handler-playwright

**Target file:** `plugins/foundry/agents/handler-playwright.md`  
**Unit:** `handler-playwright`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] MCP tool grant `mcp__playwright__*` likely matches no tool under plugin namespacing — the live-feedback capability is dead wiring

**Evidence:** Frontmatter line 10: `tools: Read, Write, Edit, Bash, Grep, Glob, mcp__playwright__*`. The server is shipped by the plugin itself (`plugins/foundry/.mcp.json` declares server name `playwright`), and Claude Code namespaces plugin-shipped MCP servers as `mcp__plugin_<plugin>_<server>__<tool>` — observably so in a live harness, where the analogous atelier-shipped server surfaces as `mcp__plugin_atelier_playwright__browser_navigate` etc. A `mcp__playwright__*` wildcard therefore grants nothing, and the body's promise at line 18 ("You have the `mcp__playwright__*` tools for live, exploratory browser feedback") fails silently at runtime. The same defect is fleet-wide (handler-css, handler-react, handler-js, handler-vanilla-js, handler-rust-webapp, and knowledge/tooling/live-feedback.md lines 17 & 25).

**Recommendation:** Verify the actual tool names exposed when foundry is installed as a plugin and correct the frontmatter glob (e.g. `mcp__plugin_foundry_playwright__*` or whatever the harness emits), or use a glob that matches both bare and plugin-namespaced forms. Add a body instruction to probe for the MCP tools at start-of-run and fall back to `npx playwright test --trace on` + screenshot artifacts when absent, so the degradation is explicit rather than silent. Fix live-feedback.md in the same change (canonical-copy discipline).

### 2. [HIGH] Frontmatter description claims Phase-5/STORY-AGENT spawning only, contradicting the body's primary Phase-3 spawning path — the routing surface is wrong

**Evidence:** Description lines 6-8: "Spawned by STORY-AGENT during FOUNDRY Phase 5 when the project has a web UI…". Body lines 62-65: "This handler is most often spawned at Phase 3 (TEST-AGENT) to author RED skeletons… then again at Phase 5 (STORY-AGENT)", and the Spawning Model Policy table (line 83) lists `ds-step-3-tests | TEST (Phase 3)` as a spawner. The description is the delegation surface an orchestrator reads to pick subagents; as written it tells Phase-3 routing to look elsewhere for the handler the body says is "most often" spawned there.

**Recommendation:** Rewrite the description to name both spawn points: "Spawned by TEST-AGENT (Phase 3) to author RED Playwright skeletons and by STORY-AGENT (Phase 5) to drive them green against the real running system." Keep description and Spawning Model Policy table in lockstep.

### 3. [HIGH] Description claims visual-regression expertise; the body contains zero visual-regression doctrine

**Evidence:** Description lines 5-6: "Expert in Playwright…, page object model, accessibility testing, visual regression, and cross-browser testing." The body has sections for POM (line ~252) and accessibility (line ~344) but no mention anywhere of `toHaveScreenshot`, snapshot baselines, `maxDiffPixels`/`maxDiffPixelRatio`, `--update-snapshots`, or masking dynamic regions — `grep -n 'toHaveScreenshot\|visual' handler-playwright.md` matches only the description line. A cold-start agent told it is a visual-regression expert has no doctrine to act on; whatever it does will be improvised, unreviewed practice.

**Recommendation:** Either add a Visual Regression section carrying real doctrine (see capability gap 1) or strike "visual regression" from the description. The former is correct — STORY-phase proof of a styled UI is exactly where pixel pinning belongs.

### 4. [HIGH] The canonical UI Interaction example violates the handler's own locator mandate — it teaches the CSS-class anti-pattern it bans

**Evidence:** Line 69 (Phase-3 mandate): "Locate by accessible name or ARIA role, never by CSS class". Yet the gold-standard gesture-path example asserts via a CSS class locator at lines 129 and 133: `await expect(page.locator('.round-date').first()).toHaveText('15 Aug 2026');` — twice, including the load-bearing post-reload persistence assertion. Handlers copy canonical examples verbatim; this example will propagate brittle class-based locators into every generated story suite, in direct contradiction of the stated doctrine.

**Recommendation:** Rewrite steps 6-7 of the example with role/text-based locators (e.g. `page.getByRole('cell', { name: '15 Aug 2026' })` or a `getByTestId` with an explicit stated exception policy for display-only values). State the locator priority order once (role > label > placeholder > text > test-id; CSS/XPath forbidden) and make every example in the file conform to it.

### 5. [HIGH] Spawning Model Policy hardcodes concrete model IDs, violating the canonical model-selection policy's single-source-of-truth rule

**Evidence:** Lines 83-84 pin IDs: "| `ds-step-3-tests` | TEST (Phase 3) | `claude-haiku-4-5` (RED skeletons) | … | `ds-step-story-tests` | STORY (Phase 5) | `claude-opus-4-8` (full story tests) |". knowledge/policy/model-selection.md is explicit: "agents reference this table instead of pinning model IDs in their own frontmatter, so the whole fleet can be re-tiered in one edit", "Resolve at spawn time, do not hardcode", and "Agents that legitimately must pin a model state the *tier* here and let this doc carry the ID." The IDs currently agree with the policy table, but the policy's one-edit re-tiering promise is false while this table (and its fleet-wide siblings in every handler) carries literal IDs — they will silently age out exactly as the policy warns. Note also the table omits the IMPLEMENT row that the policy and every sibling handler carry, so the "refuse and surface the mismatch" instruction at line 86 has no defined answer if the handler is ever spawned mid-IMPLEMENT to repair a selector.

**Recommendation:** Replace literal IDs with tiers plus a pointer: "TEST (Phase 3) → **haiku** tier; STORY (Phase 5) → **opus** tier — resolve the concrete ID from `../knowledge/policy/model-selection.md` at spawn time." Either add the IMPLEMENT row (sonnet, selector/POM repair work) or state explicitly that this handler is never spawned at IMPLEMENT and what to do if it is.

### 6. [MEDIUM] Cross-browser testing claimed, but the canonical config is chromium-only with no doctrine on when to widen the matrix

**Evidence:** Description line 6 claims "cross-browser testing" expertise; the only config the handler ships (lines 195-198) is `projects: [ { name: 'chromium', use: { ...devices['Desktop Chrome'] } } ]` and no body text ever mentions firefox, webkit, or mobile emulation, nor a rule for when a single-engine run is acceptable proof versus when STORY_PROVEN needs the full matrix.

**Recommendation:** Add a short Browser Matrix rule: default chromium for speed at Phase 3/inner loop; before STORY_PROVEN, run the suite on chromium + webkit + firefox when the feature touches layout, input methods, date/file pickers, or media — or record an explicit, justified single-engine waiver in the handoff. Show the three-project config block.

### 7. [MEDIUM] API Story Tests section claims REST/GraphQL scope that the spawner's routing table assigns to FASTAPI-AGENT

**Evidence:** Handler line ~293: "## API Story Tests — For REST or GraphQL APIs without a browser UI" and description line 7 lists "REST API surface" as a spawn trigger. But ds-step-story-tests.md's interface routing table (line 89) routes "REST / HTTP API → httpx or curl + assert on response → `FASTAPI-AGENT` VALUE_HANDLER" — Playwright is reserved for "Web browser / SPA" (line 87). Two FOUNDRY surfaces claim the same work for different handlers; an orchestrator following one will contradict the other. Also a code nit in that section: line 296 imports `request` from '@playwright/test' and then shadows it with the fixture parameter — the import is unused.

**Recommendation:** Reconcile ownership: either scope the handler's API section to "API legs *within* a browser story (seeding, token bootstrap) and projects whose ONLY interface is HTTP *and* no python handler is staffed", deferring pure-REST story tests to FASTAPI-AGENT per the routing table — or change the routing table deliberately. Drop the unused `request` import from the example.

### 8. [MEDIUM] No RED-for-the-right-reason protocol — a Phase-3 skeleton failing on webServer boot is indistinguishable from one failing on the missing element

**Evidence:** Lines 67-70 require a Phase-3 skeleton to "Fail RED because the element does not yet exist in the DOM", but at Phase 3 the feature's UI (sometimes the whole app) does not exist; the test will frequently fail on `webServer` timeout, a 404 route, or a config error instead — a RED that pins nothing. The handler carries no instruction to verify the failure reason, despite FOUNDRY's verification canon (lifecycle-states) demanding failure-gap mapping, and ds-step-4-first-test-run existing precisely to validate REDs.

**Recommendation:** Add a "RED for the right reason" check: after authoring a skeleton, run it once and assert the failure is a locator/assertion failure (e.g. `expect(locator).toBeVisible()` timeout naming the element), NOT a webServer/network/syntax error; if the app cannot boot at Phase 3, gate the skeleton on a reachable shell route or record the boot-blocker in the handoff instead of claiming a valid RED.

### 9. [MEDIUM] No output/completion contract — the handler never says what it returns to its spawner

**Evidence:** The file ends at the SOLID Covenant (lines 382-388) with no section defining what the handler reports back: which test files were created/modified, the EARS-ID → test trace map the Prime Directive (lines 37-44) depends on, run results, or journeys left uncovered. inspection-core.md's agent-definition criteria require "output/completion protocol precise", and ds-step-story-tests.md must assemble STORY_PROVEN evidence (`{story_test_count}` etc., its line 253) from exactly the data this handler never promises to surface.

**Recommendation:** Add a Completion Report contract (see capability gap 5): a fixed-format block listing test files, the EARS→test trace table, pass/fail counts with the run command, journeys covered vs. journeys in SUBJECT_MATTER_UNDERSTANDING still uncovered, and any waivers — so STORY-AGENT can emit its sentinel without re-deriving the evidence.

### 10. [MEDIUM] Accessibility mandate is weakened to "should" and carries no violation-triage or scoping doctrine

**Evidence:** Line 346: "Every page-level story test **should** include an accessibility check" — soft language in a file whose other mandates are "Non-Negotiable", from a handler whose description claims accessibility-testing expertise. The single example asserts `expect(results.violations).toEqual([])` with no WCAG tag scoping (`withTags(['wcag2a','wcag2aa'])`), no doctrine for triaging or formally waiving violations (e.g. third-party widgets), and no statement of whether an axe violation blocks STORY_PROVEN.

**Recommendation:** Promote to a mandate: every distinct page/route a story visits gets one axe scan scoped with `.withTags(['wcag2a','wcag2aa'])`; a violation blocks STORY_PROVEN unless waived in the handoff with rule id, node, and justification; never use axe `disableRules` silently. Show the scoped AxeBuilder snippet.

## Capability-uplift proposals

### 1. Visual regression — claimed in the description, absent from doctrine

**Proposal:** Add a section:

## Visual Regression — pixel pinning at STORY

When a feature changes styled UI, pin its rendered appearance:

```typescript
// @EARS-051 — dashboard visual baseline
test('dashboard renders to baseline', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page.getByRole('main')).toHaveScreenshot('dashboard.png', {
    maxDiffPixelRatio: 0.01,
    mask: [page.getByTestId('clock'), page.getByTestId('avatar')],
    animations: 'disabled',
  });
});
```

Rules: (1) screenshot a scoped locator, not the full page, unless the layout itself is the feature; (2) mask every dynamic region (timestamps, avatars, live data) — an unmasked dynamic region is a flake factory; (3) baselines are committed artifacts: the FIRST run generates them — review the generated PNG before committing, it is the spec; (4) update baselines only via `npx playwright test --update-snapshots` in the same change that intentionally alters the UI, never to silence a red; (5) baselines are per-platform — generate them in the environment CI uses (the `webkit`/CI suffix in the snapshot name tells you which); a baseline regenerated on a different OS is a silent test deletion.

**Rationale:** The frontmatter already promises this expertise (line 6) and STORY phase is where rendered appearance is the behaviour under proof; today an agent asked for visual regression improvises with no baseline-governance rules, which is worse than not claiming it.

### 2. Flakiness discipline — no anti-flake doctrine despite FOUNDRY shipping a flaky-test-fixer agent

**Proposal:** Add a section:

## Anti-Flake Discipline — Non-Negotiable

A flaky story coordinate is worse than no coordinate: it teaches the pipeline to ignore red.

- **Web-first assertions only.** `await expect(locator).toBeVisible()` auto-retries; `expect(await locator.isVisible()).toBe(true)` does not — never write the latter.
- **`page.waitForTimeout()` is BANNED** in committed tests. Wait for a condition: `expect(locator).toHaveText(...)`, `page.waitForURL(...)`, or `page.waitForResponse(resp => resp.url().includes('/api/rounds') && resp.ok())` around the action that triggers it.
- **Never wait for `networkidle`** — deprecated guidance; apps with polling/websockets never go idle. Wait for the element or response you actually need.
- **One retry budget, declared:** `retries: process.env.CI ? 2 : 0` stays; but a test that PASSES ONLY on retry is a defect — read the trace, fix the race, do not ship it. If you cannot fix it this run, hand it to `flaky-test-fixer` via the completion report rather than merging a known flake.
- **On any failure, read the trace before editing the test:** `npx playwright show-trace test-results/<run>/trace.zip` (or inspect the trace dir listing when headless) — the failure screenshot, DOM snapshot, and network log say whether the app or the test is wrong.

**Rationale:** The config sets `trace: 'on-first-retry'` but the body never tells the agent to read a trace, ban timing sleeps, or distinguish app bugs from test races — the single biggest real-world failure mode of E2E suites, and FOUNDRY already staffs a flaky-test-fixer this handler never coordinates with.

### 3. Test data management and isolation — examples assume 'alice@example.com' exists with no seeding, teardown, or auth-reuse doctrine

**Proposal:** Add a section:

## Test Data & Isolation

Story tests run against the REAL system, so the data they rely on is part of the test contract:

- **Seed through the system's own surfaces** — a setup API route, CLI seed command, or the UI itself in a `beforeAll`. Never INSERT directly into the database: that bypasses the validation the story claims to prove.
- **Own your fixtures:** each spec creates uniquely-named entities (`user-${testInfo.workerIndex}-${Date.now()}@example.com`) so `fullyParallel: true` cannot collide, and deletes what it created in teardown. A suite that only passes on a fresh database is a suite that cannot run twice.
- **Authenticate once, reuse everywhere:** log in inside a setup project and persist `storageState`:

```typescript
// tests/story/auth.setup.ts
import { test as setup } from '@playwright/test';
setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.E2E_USER!);
  await page.getByLabel('Password').fill(process.env.E2E_PASS!);
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.waitForURL('/dashboard');
  await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
```

wire it via a `setup` project + `dependencies: ['setup']` and `use: { storageState: 'playwright/.auth/user.json' }`. The login JOURNEY still gets its own dedicated story test — auth reuse is for every OTHER journey. Credentials come from env vars, never literals committed in specs.

**Rationale:** Every example in the file hardcodes credentials for a user nobody created; without seeding/isolation/storageState doctrine, generated suites are serially-dependent, parallel-unsafe, slow (login per test), and leak literal credentials into committed specs.

### 4. Environment failure modes — browser install, missing MCP, and webServer boot failures have no playbook

**Proposal:** Extend Environment Setup with:

### When setup fails

- **Browser install on Linux/CI:** `npx playwright install` alone fails on missing system libraries — use `npx playwright install --with-deps chromium` (matches `skills/check/requirements.tsv`). If installation is impossible (offline/sandboxed), do NOT fake green: report `ENVIRONMENT_BLOCKED` in your completion report naming the exact failing command and stderr, and stop — a story suite that never ran proves nothing.
- **Playwright MCP absent:** if no `mcp__*playwright*` tool responds, proceed CLI-only — `npx playwright test --trace on` plus `page.screenshot()` artifacts replace live snapshots. Note the degradation in the completion report.
- **webServer timeout:** when the runner reports `Timed out waiting for <url>`, run the `command` from the webServer block directly in Bash and read ITS stderr — the defect is almost always the app (port in use, missing env var, migration not run), not the test. Diagnose the app before touching `timeout:`. Raising the timeout to outwait a crash is concealment.
- **Version probe:** record `npx playwright --version` in the completion report so reviewers can correlate failures with runner versions.

**Rationale:** The Environment Setup section only covers the happy path; the three failures that actually stop E2E runs cold (no system deps, no MCP, app won't boot) have no instructions, inviting the worst outcome — an agent that silently skips story proof or raises timeouts to mask a crash.

### 5. Completion/output contract — no defined artifact returned to TEST-AGENT/STORY-AGENT

**Proposal:** Add a final section:

## Completion Report — required output

End every run by emitting this block to your spawner (it feeds the STORY_PROVEN sentinel evidence):

```
PLAYWRIGHT_HANDLER_REPORT
phase: TEST|STORY
files: [tests/story/*.spec.ts created/modified]
trace_map:            # the Prime Directive, proven
  EARS-042: tests/story/user-auth.story.spec.ts :: 'happy path — user logs in…'
  EARS-043: tests/story/user-auth.story.spec.ts :: 'unhappy path — wrong password…'
run: npx playwright test → N passed / N failed (expected RED at Phase 3: list which, and the failure REASON proving each red is a locator/assertion miss, not a boot error)
journeys_uncovered: [actor journeys from SUBJECT_MATTER_UNDERSTANDING with no test yet — empty is the only acceptable value at STORY]
a11y: routes scanned / violations (blocking) / waivers (rule id + justification)
visual: baselines added/updated + why
flakes_handed_off: [tests passing only on retry → flaky-test-fixer]
waivers: [single-engine browser run, env degradations]
```

An empty or omitted `trace_map` means the run is incomplete — the Prime Directive is checked against this table, not against intentions.

**Rationale:** inspection-core requires a precise completion protocol; today STORY-AGENT must re-derive story_test_count, coverage of journeys, and EARS traceability from the filesystem, and the Prime Directive ('every journey covered') is unenforceable because nothing ever enumerates journeys vs tests.

### 6. Locator doctrine is two scattered bullets, not a priority order with a test-id escape hatch

**Proposal:** Add under the Test-First Mandate:

### Locator priority — one ladder, no exceptions unstated

1. `getByRole(role, { name })` — the contract a user (and screen reader) sees; preferred always.
2. `getByLabel` / `getByPlaceholder` — form fields.
3. `getByText` — static, user-visible copy (exact: true when the text is short/ambiguous).
4. `getByTestId` — ONLY for display-only values with no role/name (a computed date cell, a chart tooltip). Adding `data-testid` to the implementation is a legitimate part of making the RED skeleton drivable — request it in the Phase-3 handoff rather than reaching for CSS.
5. CSS/XPath selectors — FORBIDDEN in committed story tests. If you cannot reach an element by 1-4, that is an accessibility finding to report, not a styling hook to exploit.

Scope every locator that can match multiple nodes (`.first()` is a smell — prefer filtering: `page.getByRole('row', { name: 'Round 3' }).getByRole('button', { name: 'Edit' })`).

**Rationale:** The file's own canonical example uses `page.locator('.round-date')` and unscoped `.first()` calls because the rule exists only as a one-line Phase-3 bullet; a single explicit ladder with the test-id escape hatch removes the ambiguity that produced the contradiction and doubles as an accessibility forcing-function.
