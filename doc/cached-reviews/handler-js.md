# Cached review — FOUNDRY handler-js

**Target file:** `plugins/foundry/agents/handler-js.md`  
**Unit:** `handler-js`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] tools frontmatter grants a Playwright MCP wildcard that does not match the plugin-namespaced tool names — the handler's live-feedback doctrine is unfulfillable

**Evidence:** Line 10: `tools: Read, Write, Edit, Bash, Grep, Glob, mcp__playwright__*` and line 18: "you have the `mcp__playwright__*` tools for live, exploratory browser feedback". FOUNDRY bundles its Playwright server via plugins/foundry/.mcp.json under server key `playwright`, but plugin-bundled MCP tools surface under the plugin-namespaced form `mcp__plugin_foundry_playwright__browser_*` (observed live in this harness, e.g. `mcp__plugin_foundry_context7__query-docs` and `mcp__plugin_atelier_playwright__browser_click`). The wildcard `mcp__playwright__*` matches none of those names, so the handler is spawned with zero browser tools while its tooling preamble asserts it has them.

**Recommendation:** Change the frontmatter entry (and the body reference at line 18) to the plugin-namespaced wildcard `mcp__plugin_foundry_playwright__*`, or to the documented harness-resolved form, and add one fallback sentence: "If no Playwright MCP tools are present in your tool list, proceed without live browser feedback and note the degradation in your handoff." This defect is fleet-wide (handler-css, handler-react, handler-playwright, handler-rust-webapp, handler-vanilla-js carry the same line 10/18 pair) — flag for a canonical-copy fix, but this file must be corrected regardless.

### 2. [HIGH] Hardcoded concrete model IDs in the Spawning Model Policy table violate the model-pin policy's 'resolve at spawn time, do not hardcode' rule — and the file never cites the canonical policy

**Evidence:** Lines 75–79: the table pins `claude-haiku-4-5`, `claude-sonnet-4-6`, `claude-opus-4-8` as literal IDs. knowledge/policy/model-selection.md states "Tiers map to the latest model in each family. Resolve at spawn time, do not hardcode" and "When a new model family ships, update **only this table** and the whole fleet re-tiers." handler-js.md contains no reference to model-selection.md at all, so when the canonical table re-tiers, this file's IDs silently age out — exactly the failure mode the policy exists to prevent. Sibling handler-python.md (line 82–83) at least prefixes its table with "the spawning phase agent chooses the model per the model-selection policy ([../knowledge/policy/model-selection.md])"; handler-js omits even that.

**Recommendation:** Replace the concrete IDs with tiers (haiku / sonnet / opus) and add the sentence handler-python carries: "This handler's frontmatter is `model: inherit` — the spawning phase agent resolves the tier to a concrete ID per `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md`." Keep the table as tier names only so the policy doc remains the single source of the ID mapping.

### 3. [HIGH] Jest coverage command omits branches:100 — contradicting the file's own Prime Directive and drifting from the canonical test-policy it cites

**Evidence:** Line 173: `npx jest --coverage --coverageThreshold='{"global":{"lines":100}}'` — no branch threshold. Line 38–39 (Prime Directive): "**100% line coverage AND 100% branch coverage is the floor.**" The canonical knowledge/testing/test-policy.md (line 278) gives the correct command: `npx jest --coverage --coverageThreshold='{"global":{"lines":100,"branches":100}}'`, and line 279 adds that Vitest must be configured with `thresholds: {lines: 100, branches: 100}` — the handler's Vitest command (line 170, `npx vitest run --coverage`) carries no threshold configuration note either. A haiku-tier TEST-phase spawn will execute the command as written and pass a build with unpinned branches.

**Recommendation:** Copy the exact commands from test-policy.md: add `"branches":100` to the Jest threshold JSON and add the Vitest note "configure `coverage.thresholds: {lines: 100, branches: 100}` in vitest.config — `--coverage` alone enforces nothing."

### 4. [HIGH] Unconditional 'never modify test code' contradicts the handler's TEST-phase role of authoring test code

**Evidence:** Lines 31–32: "As per the PRINCIPLE_PHILOSOPHY: think before coding, ask if unclear, never widen scope unnecessarily, never modify test code." But the frontmatter (lines 6–7) says the handler is "Spawned by TEST-AGENT…" and the Spawning Model Policy (line 77) staffs it under `ds-step-3-tests` for "TEST (Phase 3)" — a phase whose entire output IS test code. The builder skill scopes this constraint to Phase 4 only (skills/builder/SKILL.md line 344: "**Constraint:** Do not modify test files. If a test is wrong, return to Phase 3."). As written, a literal-minded TEST-phase spawn (deliberately run on haiku, the least judgement-capable tier) receives a direct prohibition against its own assignment.

**Recommendation:** Phase-scope the rule: "never modify test code **when spawned for the IMPLEMENT phase** — if a test is wrong, surface it to the orchestrator for a return to Phase 3. When spawned for the TEST or STORY phase, authoring and revising test code is your assignment."

### 5. [MEDIUM] Load-bearing knowledge references use agent-file-relative paths a spawned handler cannot resolve — inconsistently with the file's own ${CLAUDE_PLUGIN_ROOT} usage

**Evidence:** Line 21 `(../knowledge/tooling/live-feedback.md)`, lines 49–50 `(../knowledge/first-principles.md … ../knowledge/testing/test-policy.md)`, line 239 `(../knowledge/architecture/solid-covenant.md)` — all relative to agents/. A spawned subagent's working directory is the project, not the plugin's agents/ dir, so these `../` paths dangle at runtime; the same file proves it knows the correct form at lines 30 and 223 (`${CLAUDE_PLUGIN_ROOT}/knowledge/...`). The self-containment law says plugin files resolve paths only through ${CLAUDE_PLUGIN_ROOT}.

**Recommendation:** Rewrite all four references as `${CLAUDE_PLUGIN_ROOT}/knowledge/...` paths so the canon (test-policy, first-principles, solid-covenant, live-feedback) is actually reachable by the running handler, not just by a human browsing the repo.

### 6. [MEDIUM] Stale runtime floor: 'Node.js 18+' claims expertise anchored to an EOL runtime

**Evidence:** Line 5 (description): "Expert in Node.js 18+, ES2022+, TypeScript 5+ …". Node 18 reached end-of-life 2025-04-30; as of 2026-06 the supported lines are 20 (maintenance), 22, and 24 (LTS). A handler that bootstraps greenfield projects with an 18+ floor can legitimately target an unsupported, CVE-accumulating runtime, and misses 20+/22+ built-ins it should prefer (stable `fetch`, `node:test`, `--env-file`, import attributes).

**Recommendation:** Raise the description to "Node.js 20+ (prefer the active LTS)" and add one Environment Assumptions line: "If `node --version` reports an EOL line (<20), surface it to the orchestrator as a maintenance finding before building on it."

### 7. [MEDIUM] Project-specific residue and a self-inconsistent example in the Performance Assertions section

**Evidence:** Lines 214–221: the example is a Playwright page test referencing `'rounds panel loads within SLO'`, `page.goto('/')`, and `await page.waitForSelector('#app.show')` — selectors leaked from one past project (the same project bleeds into lines 97–101: "Edit button on round row", "verify date input… click Save"). Three defects: (a) a generic marketplace handler carries another project's DOM contract as doctrine; (b) the example measures wall-clock around `waitForSelector`, while the threshold table it sits beside (line 227) specifies `domContentLoaded` < 3000 ms — the example does not measure what the table mandates; (c) it is a Playwright test, which this handler's own UI-gate section (line 104) says belongs to handler-playwright.

**Recommendation:** Replace the example with one in this handler's actual lane — e.g. a Vitest test asserting `performance.now()` elapsed around an exported async function or an HTTP handler invocation against the p95 < 200 ms row — and genericise the UI-handoff examples to placeholder names ([Submit button on entity form]).

### 8. [MEDIUM] The mandatory UI-test handoff note has no defined output channel and bypasses the handoff-protocol schema

**Evidence:** Lines 93–104: "you must produce a handoff note listing every interactive element… This handoff goes to the PLAYWRIGHT-AGENT (handler-playwright)." Nothing says WHERE the note goes — final response text? a file? which path? — and the plugin ships a strict transfer schema for exactly this (skills/handoff-protocol/SKILL.md: "must package artifacts, risks, review status, and next instructions in a strict schema") that this section never invokes. A handler that 'does not orchestrate' (line 27) also cannot deliver anything to handler-playwright itself; the note's actual consumer is the spawning phase agent, which is never named as the recipient.

**Recommendation:** Specify the channel and recipient: "Emit the `PLAYWRIGHT INTERACTION TESTS REQUIRED:` block verbatim in your final completion report to the spawning phase agent, populated into the handoff-protocol schema's next-instructions field (`${CLAUDE_PLUGIN_ROOT}/skills/handoff-protocol/SKILL.md`); the phase agent routes it to handler-playwright."

### 9. [LOW] Routing boundary with handler-vanilla-js is ambiguous: 'non-React, non-CSS' does not exclude vanilla front-end work

**Evidence:** Line 8 (description): "when the project stack includes JavaScript or TypeScript (non-React, non-CSS)", and line 5 claims "Testing Library" expertise. handler-vanilla-js.md (lines 4–10) owns "vanilla-JavaScript front-end projects… @testing-library/dom" — a no-framework DOM project satisfies BOTH descriptions, so a spawning phase agent has no deterministic tiebreak, and the Testing Library claim overlaps the sibling's core domain.

**Recommendation:** Sharpen the exclusion to "(non-React, non-CSS, non-vanilla-DOM-front-end — DOM/front-end vanilla JS routes to handler-vanilla-js; this handler owns Node services, CLIs, libraries, and shared TS logic)" and drop or qualify "Testing Library" to "Testing Library (for the rare DOM-adjacent unit)".

### 10. [LOW] Weakened SOLID covenant section and a duplicated section divider

**Evidence:** Lines 237–239: the SOLID Covenant section opens "At the end of your work, note any TypeScript patterns…" — it never states the covenant-carrying declaration sibling handler-python.md leads with ("You carry the SOLID self-improvement covenant.") nor python's project-memory bullet ("this project uses a custom fixture pattern — add to memory", which is what `memory: project` at line 13 exists to feed). Separately, lines 115–116 are two consecutive `---` dividers — a stray empty section left by a past edit.

**Recommendation:** Open the section with "You carry the SOLID self-improvement covenant." and add the project-memory bullet so the `memory: project` frontmatter key has an explicit write-side instruction; delete the duplicate `---` at line 116.

## Capability-uplift proposals

### 1. No test-double discipline — the handler can over-mock or mock the wrong boundary with zero guidance

**Proposal:** Add a '## Test Doubles — Mock the Boundary, Not the Middle' section: "Mock only at architectural boundaries (network, clock, filesystem, randomness, process env). Use `vi.mock`/`jest.mock` for module boundaries; prefer injected fakes (in-memory repos) over module mocks for domain collaborators. Network: intercept with `msw` (or `nock` for raw Node http) — never stub your own fetch wrapper and call it tested. Time: `vi.useFakeTimers()` / `jest.useFakeTimers()` with explicit `advanceTimersByTime`; a test that calls real `setTimeout` is a flake coordinate. Restore every double (`vi.restoreAllMocks()` in `afterEach` or `restoreMocks: true` config). A test whose assertions only inspect mock call counts, never output values, is a blurry coordinate — rewrite it."

**Rationale:** The handler mandates exact assertions and 100% coverage but says nothing about HOW to isolate, the dominant quality failure in JS test suites (over-mocked tests that pass while the integration is broken). Haiku-tier TEST-phase spawns especially need this prescriptive rail.

### 2. No async failure-mode doctrine — unhandled rejections, open handles, and floating promises are the canonical JS defect class and the handler is silent on all of them

**Proposal:** Add an '## Async Discipline — Required' section: "Every promise is awaited or explicitly returned; enable `@typescript-eslint/no-floating-promises` and treat a violation as a blocking defect. Every async error path has a coordinate using `await expect(fn()).rejects.toThrow(ExactErrorType)`. Before declaring a suite done, prove it exits cleanly: Jest `--detectOpenHandles`, Vitest `--reporter=hanging-process` on a hung run — an open handle (timer, socket, watcher) is a defect in the code under test, not the test. Register a `process.on('unhandledRejection')` failer in test setup so a swallowed rejection fails the run instead of logging."

**Rationale:** The file's only async guidance is 'async/await over .then()' (line 195). The failure modes that actually sink Node services — leaked handles, swallowed rejections, un-awaited fire-and-forget calls — are unaddressed, so the handler cannot recognise them today.

### 3. No type-correctness gate — '100% coverage' can pass while the TypeScript build is broken or exported types lie

**Proposal:** Add to Implementation Standards: "Before reporting completion on any TS work, run `npx tsc --noEmit` — a non-zero exit is a blocking defect even when all tests pass (Vitest/esbuild transpile without type-checking; green tests do not prove the types). Require `strict: true` in new tsconfig; if the project's tsconfig is non-strict, surface that as a finding, do not silently inherit it. For exported public APIs, add type-level coordinates with Vitest's `expectTypeOf` (or `tsd`): assert the exported signature's parameter and return types exactly, so a widening to `any` fails a test."

**Rationale:** Vitest's default transform skips type-checking entirely — the handler's coverage floor is satisfiable by code that does not compile. A TS specialist without a `tsc --noEmit` gate is missing its most basic verification step.

### 4. No greenfield/degraded-toolchain protocol — Environment Assumptions only covers the happy path where a runner already exists

**Proposal:** Extend Environment Assumptions with a 'When the assumptions fail' ladder: "(1) No package.json → `npm init -y`, set `\"type\": \"module\"`, and install the runner the stack manifest names (default Vitest) as a devDependency with a pinned major. (2) package.json but no test script/runner → propose Vitest to the phase agent before installing; never bolt a second runner beside an existing one. (3) Multiple lockfiles present → surface the conflict to the orchestrator; do not pick silently. (4) Monorepo (workspaces/turbo/nx detected) → run tests from the owning package dir with the workspace-aware command (`npm test -w <pkg>` / `pnpm --filter`), never from the repo root blind. (5) No network for installs → fall back to the zero-dependency built-in `node:test` runner + `node:assert/strict` and say so in the handoff. (6) Malformed or ambiguous spec from the phase agent (no EARS IDs, untestable acceptance) → stop and return NEEDS_REVISION naming the missing fields; never invent requirements."

**Rationale:** The current section (lines 118–135) only inspects a healthy project. Every listed condition is a real spawn state in FOUNDRY (greenfield items especially), and today the handler has no doctrine for any of them — it will improvise inconsistently per spawn.

### 5. Hostile-input and security hygiene is absent — the handler can implement injection-prone code without any tripwire

**Proposal:** Add an '## Input Hardening — Coordinates for Hostile Input' section: "Every function that accepts external input (HTTP body, env var, file path, user string) gets hostile coordinates: prototype-pollution payloads (`{\"__proto__\":{...}}` through JSON paths), path traversal (`../../etc/passwd` through any path join — use `path.resolve` + prefix check), oversized input (length bounds asserted), and type-confusion (string where number expected). Validate at the boundary with a schema validator the project already uses (zod/ajv); never hand-roll regex validation for emails/URLs. Never build shell strings from input — use `execFile`/`spawn` with arg arrays. Forbid `eval`, `new Function`, and dynamic `require` of input-derived paths outright."

**Rationale:** The refutation brief's 'hostile input' failure mode has zero coverage in the file. JS's dominant CVE classes (prototype pollution, injection through child_process, path traversal) are cheap to pin as coordinates if the doctrine demands them — and invisible if it doesn't.

### 6. No machine-readable completion contract — the handler's output to the phase agent is undefined beyond the UI-handoff snippet

**Proposal:** Add an '## Completion Report — Required Shape' section: "End every assignment with a fenced report the phase agent can parse without interpretation: `STATUS: COMPLETE|BLOCKED|NEEDS_REVISION` · `FILES: <created/modified list>` · `TESTS: <n> added, <n> passing, RED-confirmed: yes/no (you ran each new test and saw it fail first)` · `COVERAGE: lines <x>% branches <y>% (command + exact output line)` · `TYPECHECK: tsc --noEmit exit <code>` · `PLAYWRIGHT INTERACTION TESTS REQUIRED: <block or 'none'>` · `RESIDUAL RISKS: <list or 'none'>` · `SELF-IMPROVEMENT: <patterns to flag per the SOLID covenant or 'none'>`. A report missing any field is an incomplete handoff — the phase agent must bounce it."

**Rationale:** FOUNDRY's pipeline quality depends on what phase agents can verify from handler output. Today the file mandates outcomes (coverage, TDD, perf assertions) but never makes the handler attest to them in a checkable shape, so a spawn can claim completion without evidence and the reviewer gate has nothing concrete to audit.
