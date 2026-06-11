# Cached review — FOUNDRY handler-vanilla-js

**Target file:** `plugins/foundry/agents/handler-vanilla-js.md`  
**Unit:** `handler-vanilla-js`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Frontmatter tool pattern `mcp__playwright__*` does not match plugin-namespaced MCP tool names — the granted browser tooling is likely inert

**Evidence:** Line 12: `tools: Read, Write, Edit, Bash, Grep, Glob, mcp__playwright__*` and lines 20-21: "You have the `mcp__playwright__*` tools for live, exploratory browser feedback". FOUNDRY ships its Playwright server via `plugins/foundry/.mcp.json` (server key `playwright`), but plugin-bundled MCP servers surface harness-side with the plugin-namespaced prefix — observed live in this very harness as `mcp__plugin_foundry_context7__query-docs` and `mcp__plugin_atelier_playwright__browser_click`. The pattern `mcp__playwright__*` therefore matches nothing in an installed plugin, so the handler's allowlist silently grants zero browser tools and the entire live-feedback doctrine block (lines 20-24) plus the screenshot/accessibility-snapshot workflow it promises cannot execute.

**Recommendation:** Change the frontmatter pattern to one that matches the installed naming (e.g. `mcp__plugin_foundry_playwright__*`, or both patterns for robustness), and add a body fallback: "If no `mcp__*playwright*` tool resolves at runtime, state that live feedback is unavailable and rely on the committed test contract alone — do not fabricate browser observations." This is fleet-wide (handler-js, handler-css, handler-react, handler-playwright, handler-rust-webapp all carry the same pattern) — fix at the fleet level but this file is independently defective.

### 2. [HIGH] Performance-threshold table misattributes a row to test-policy.md — the cited source contains no `Interaction → visible response < 100 ms` threshold

**Evidence:** Lines 280-287: "Thresholds live in `${CLAUDE_PLUGIN_ROOT}/knowledge/testing/test-policy.md`: | Page load (Playwright) | `domContentLoaded` < 3000 ms | | Interaction → visible response | < 100 ms |". The actual table in `plugins/foundry/knowledge/testing/test-policy.md` (~lines 197-203) contains rows for API endpoint (<200ms/<5000ms), Scheduler run, `Page load (Playwright) | domContentLoaded | < 3000 ms`, and `Disk write (CSV/JSON) | Wall time | < 100 ms`. There is no interaction-latency row anywhere in that file — the handler invents a threshold and stamps the canon's authority on it, while simultaneously declaring a missing performance assertion a "blocking defect" (line 288).

**Recommendation:** Either (a) add an interaction-latency row to test-policy.md (the canonical home, per its own "Coverage gate" section) and keep the handler's citation, or (b) restate the handler table to only quote rows that exist and mark the 100 ms interaction budget as this handler's own doctrine with its provenance (e.g. RAIL guidance). A handler must never attribute a number to a canon file that does not carry it — that is exactly the drift the inspector exists to catch.

### 3. [MEDIUM] Spawning Model Policy hardcodes concrete model IDs, violating the model-selection policy's single-edit re-tier invariant

**Evidence:** Lines 89-91 pin `claude-haiku-4-5`, `claude-sonnet-4-6`, `claude-opus-4-8` directly in the handler. `plugins/foundry/knowledge/policy/model-selection.md` says: "agents reference this table instead of pinning model IDs in their own frontmatter, so the whole fleet can be re-tiered in one edit" and "Resolve at spawn time, do not hardcode" and "When a new model family ships, update only this table and the whole fleet re-tiers." The IDs currently agree with the table, so this is structural drift-in-waiting: the next model-family ship leaves nine handler files stale (handler-js, handler-css, handler-ansible carry the identical hardcoded table).

**Recommendation:** Replace the model-ID column with tiers (`haiku` / `sonnet` / `opus`) plus a single pointer: "Resolve tier→ID via `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md` at spawn time." Keep the refuse-on-mismatch protocol (lines 93-94) keyed to tier, not ID.

### 4. [MEDIUM] The canonical test example is not runnable: `vi.fn()` without importing `vi`, and the axe matcher is never registered

**Evidence:** Line 157 imports only `{ describe, it, expect, beforeEach }` from 'vitest', yet line 168 calls `const onChange = vi.fn()` — a ReferenceError unless `globals: true` is configured, which the handler never states. Likewise lines 238-243 use `expect(await axe(document.body)).toHaveNoViolations()` after importing only `{ axe }` from 'jest-axe'; the `toHaveNoViolations` matcher requires `expect.extend(toHaveNoViolations)` (or `vitest-axe` under the prescribed Vitest default) and is never wired. A handler whose doctrine examples throw on first run erodes the test-first mandate it enforces — the spawned haiku-tier TEST-phase agent will copy these verbatim.

**Recommendation:** Fix the imports (`import { describe, it, expect, beforeEach, vi } from 'vitest'`) and add the matcher registration line (`import { axe, toHaveNoViolations } from 'jest-axe'; expect.extend(toHaveNoViolations)` — or prescribe `vitest-axe` when Vitest is the runner). State explicitly whether `globals: true` is assumed.

### 5. [MEDIUM] The Coverage command does not enforce the Prime Directive's 100% floor — and drifts from its own cited policy

**Evidence:** Line 194: `npx vitest run --coverage      # or: npx jest --coverage --coverageThreshold='{"global":{"lines":100,"branches":100}}'`. The default (Vitest) invocation carries no thresholds, so the run passes at any coverage — the "100% line coverage AND 100% branch coverage is the floor" Prime Directive (lines 49-50) is mechanically unenforced on the primary path. test-policy.md itself (~line 279) prescribes `npx vitest run --coverage (configure thresholds: {lines: 100, branches: 100})` — the handler dropped the load-bearing parenthetical.

**Recommendation:** Make the Vitest command self-enforcing: `npx vitest run --coverage --coverage.thresholds.lines=100 --coverage.thresholds.branches=100 --coverage.thresholds.functions=100 --coverage.thresholds.statements=100`, with a note to persist thresholds in `vitest.config` when one exists. A floor that the gate command cannot fail on is not a floor.

### 6. [MEDIUM] SUBJECT_MATTER_UNDERSTANDING is claimed in the description but the body never instructs loading it or emitting the SMU sentinel

**Evidence:** Line 11 (description): "Carries the SOLID self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." The body contains zero mention of SMU — no instruction to read `doc/SUBJECT_MATTER_UNDERSTANDING.md`, no `SMU::LOADED` sentinel per `knowledge/protocols/context-sentinel.md` (~line 207), despite `knowledge/orchestration/subject-matter-understanding.md` stating "Every agent — PHASE_POOL, VALUE_HANDLER, REVIEWER... receives the SMU as part of its instantiation context" and `skills/builder/SKILL.md` (~line 409): "Each handler carries: STACK knowledge, SUBJECT_MATTER_UNDERSTANDING, SOLID covenant." The frontmatter promise is unbacked by any operative instruction.

**Recommendation:** Add to the preamble (next to the implementation-covenant read at line 36): "If `doc/SUBJECT_MATTER_UNDERSTANDING.md` exists, read it before any work and honour its constraints; emit the `SMU::LOADED` sentinel per the context-sentinel protocol. If absent, note its absence in your handoff rather than inventing domain assumptions."

### 7. [MEDIUM] Wrong-stack detection has no refusal protocol — the framework probe ends in an echo, not an action

**Evidence:** Line 135: `cat package.json 2>/dev/null | grep -E '"react"|"vue"|"svelte"|"angular"' && echo "FRAMEWORK PRESENT — wrong handler" || echo "vanilla OK"`. Nothing follows: no instruction to stop, refuse, or surface the mismatch. Contrast the model-mismatch case, which has an explicit protocol (lines 93-94: "refuse and surface the mismatch to the orchestrator before doing any work"). A handler that detects it is the wrong specialist and proceeds anyway will write framework-incompatible vanilla idioms into a React/Vue codebase.

**Recommendation:** Add the symmetric rule: "If the framework probe reports FRAMEWORK PRESENT, STOP — do no work; surface the stack mismatch to the spawning phase agent naming the detected framework and the correct handler (handler-react for React; handler-js otherwise). Exception: an explicitly framework-free sub-surface of a mixed repo, only when the spawning instruction names it."

### 8. [LOW] WCAG 2.1 AA floor is stale — WCAG 2.2 has been the W3C Recommendation since October 2023 and the marketplace's own design reviewer audits against 2.2

**Evidence:** Line 227: "## Accessibility — Non-Negotiable (WCAG 2.1 AA floor)" and description line 5's "accessibility-first" claim. The atelier plugin in this same marketplace reviews against "WCAG 2.2" (its ui-review skill), while this handler, `skills/frontend/SKILL.md` (line 43), and `definition-of-good.md` (line 7) all pin 2.1. New 2.2 AA criteria directly relevant to this handler's domain (2.4.11 Focus Not Obscured, 2.5.7 Dragging Movements, 2.5.8 Target Size Minimum 24px) are absent from its checklist.

**Recommendation:** Uplift the floor to WCAG 2.2 AA at the canonical home (`skills/frontend/resources/agents/definition-of-good.md`) and mirror here, adding the three new 2.2 AA criteria to the checklist. Fix canon-first to avoid creating handler-vs-canon drift; note the touch-target line should then read 24×24px CSS minimum (2.5.8) with 44×44px as the recommended target.

### 9. [LOW] jsdom-based performance assertion doctrine is flake-prone and unqualified

**Evidence:** Lines 272-277: `expect(performance.now() - t0).toBeLessThan(50) // ms, in jsdom; tighten per project`. A single-sample wall-clock assertion in jsdom on shared CI is the classic flaky test; the handler's own marketplace ships a `flaky-test-fixer` agent for exactly this failure class, yet the doctrine prescribes the pattern without mitigation (warm-up run, median-of-N, generous-floor-tighten-later, or CI-multiplier).

**Recommendation:** Qualify the pattern: assert on the median of ≥3 runs after one warm-up, set the initial budget at ~3× observed local time, and state that a perf coordinate that flakes twice goes to the flaky-test-fixer rather than being loosened ad hoc.

### 10. [SUGGESTION] The Playwright handoff note is free-text and unbound to the handoff-protocol schema

**Evidence:** Lines 104-118 define the `PLAYWRIGHT INTERACTION TESTS REQUIRED:` block as an ad-hoc text format "to the PLAYWRIGHT-AGENT (handler-playwright)", with no reference to `skills/handoff-protocol/SKILL.md`, which exists precisely to make inter-agent transfers carry "artifacts, risks, review status, and next instructions in a strict schema."

**Recommendation:** Keep the human-readable block but wrap it in (or reference) the handoff-protocol schema so the orchestrator can verify the handoff happened — e.g. "Emit this list as the `next_instructions` field of a handoff-protocol package addressed to handler-playwright; an implementation that added interactive elements without this package is incomplete."

## Capability-uplift proposals

### 1. No untrusted-input / XSS doctrine — the handler builds DOM from data with zero injection discipline

**Proposal:** Add a section '## Untrusted Data — Non-Negotiable': "Never assign data-derived strings to `innerHTML`, `outerHTML`, `insertAdjacentHTML`, or `document.write`. Render data via `textContent`, `createElement` + property assignment, or `<template>` cloning with text-node fills. URLs from data are validated against an allowlist of schemes (`https:`, `mailto:`) before assignment to `href`/`src`; never `javascript:`. If rich HTML from data is a genuine requirement, sanitize with DOMPurify and record the dependency in the handoff. Every input-rendering surface gets a hostile-input coordinate: a test that mounts with `<img src=x onerror=...>`-class payloads and asserts they render inert as text. A surface without its hostile-input coordinate is not done."

**Rationale:** This is a front-end value handler whose entire job is binding data into the DOM, and the word 'sanitize' appears nowhere in the file. Its only `innerHTML` mentions are incidental (the BAD example line 218, test teardown line 163). DOM XSS is the dominant vanilla-JS failure class; SENTINEL gates catch it late at SECURE — the handler should never produce it.

### 2. Custom elements are claimed expertise (description line 5, line 204) but carry zero testing or design doctrine — shadow DOM silently breaks the prescribed query strategy

**Proposal:** Add '## Custom Elements doctrine': "Prefer light-DOM custom elements; adopt shadow DOM only for genuine style encapsulation, because `@testing-library/dom` queries do NOT pierce shadow roots — a shadow-DOM component is invisible to `getByRole`. When shadow DOM is used: expose state via attributes/properties, forward focus with `delegatesFocus: true`, test through `shadow-dom-testing-library` (`screen.getByShadowRole`) or query `el.shadowRoot` explicitly, and verify the jsdom/happy-dom environment supports `customElements.define` + `attachShadow` before authoring (happy-dom preferred for shadow work). Lifecycle coordinates are mandatory: one test per `connectedCallback`, `disconnectedCallback`, and each `observedAttributes` entry via `attributeChangedCallback`. Register elements idempotently (`if (!customElements.get(tag))`) so repeated test mounts do not throw."

**Rationale:** The handler tells agents to 'reach for custom elements where they earn their keep' (line 205) and then prescribes a testing strategy (role/name queries, lines 182-183) that cannot see inside one. An agent following both instructions hits an unexplained wall of 'unable to find role' failures and will degrade to querySelector — exactly the implementation-detail testing the handler forbids.

### 3. No async-DOM / timer discipline — the file imports `waitFor` in its example but never teaches when async assertions, fake timers, or microtask flushing are required

**Proposal:** Add under Testing Standards: "Async discipline: any assertion downstream of a `fetch`, `CustomEvent` listener, `requestAnimationFrame`, debounce, or `await` boundary uses `await waitFor(...)` or `await findByRole(...)` — never a bare synchronous `getBy*` after an async act, and never arbitrary `setTimeout` sleeps in tests. Debounced/throttled paths use `vi.useFakeTimers()` + `vi.advanceTimersByTime(ms)` with `vi.useRealTimers()` in `afterEach`; when combining fake timers with `userEvent`, configure `userEvent.setup({ advanceTimers: vi.advanceTimersByTime })`. Network access in unit/DOM tests is stubbed (vi.fn fetch stub or msw); a test that touches the real network is a defect at this layer. Each async branch (pending → resolved, pending → rejected) is its own coordinate, including the loading-state render."

**Rationale:** Timing is the number-one source of flaky DOM tests, and the handler's only async surface is an unused `waitFor` import (line 158). The TEST-phase spawn is haiku-tier (line 89) — the lowest-judgement model — so the discipline must be written down, not assumed.

### 4. No greenfield bootstrap recipe — the handler assumes a test runner exists but a no-build-step vanilla project routinely starts with no package.json at all

**Proposal:** Add '## Greenfield bootstrap (no test environment present)': "If the Environment Assumptions probes find no package.json or no test runner, do not improvise and do not skip the test-first mandate. Bootstrap the minimum: `npm init -y && npm i -D vitest @vitest/coverage-v8 happy-dom @testing-library/dom @testing-library/user-event jest-axe` (or `vitest-axe`), set `"test": "vitest run --coverage"` in package.json, and create `vitest.config.js` with `environment: 'happy-dom'` and `coverage.thresholds: { lines: 100, branches: 100, functions: 100, statements: 100 }`. The app itself stays build-free (ES modules loaded directly by the browser); only the test harness lives in node_modules. Record the bootstrap in the handoff note. If npm itself is unavailable, STOP and surface a prerequisites failure (cite /foundry:check) — never ship untested code because the harness was missing."

**Rationale:** Lines 145-148 say 'Prefer the project's existing test runner. Default: Vitest... if present, else Jest' — which is undefined when neither is present, the most common state for exactly the no-framework, no-build projects this handler owns. The failure mode today is an agent inventing an ad-hoc harness or quietly shipping without tests.

### 5. The Playwright MCP is granted but never woven into the workflow — no doctrine for verifying the claims jsdom physically cannot assert

**Proposal:** Add '## What jsdom cannot prove — verify in a real browser': "jsdom/happy-dom perform no layout, no painting, and no real CSS cascade: computed contrast ratios, 24/44px target sizes, `:focus-visible` rendering, sticky/overflow behaviour, and `prefers-reduced-motion` media queries are NOT testable there — an axe pass in jsdom does not cover colour-contrast rules. Before declaring an accessibility or visual claim done: serve the surface (`npx http-server` or `python3 -m http.server`), then use the Playwright MCP to (1) snapshot the accessibility tree and confirm the role/name structure matches your test assertions, (2) screenshot at 320px and desktop widths, (3) tab through interactive elements confirming visible focus, and (4) read the console for errors. Findings feed back into committed tests or `improve?` markers — the MCP observation itself is never the proof of record (live-feedback.md)."

**Rationale:** The handler holds browser tools (line 12) and a doctrine block saying they exist (lines 20-24), then never mentions them again. Meanwhile it demands contrast ratios and visible-focus (lines 230-232) that its prescribed jsdom+axe setup cannot measure — axe-core's color-contrast rule is a no-op without real rendering. The capability is present but the knowledge of when it is the only honest verifier is missing.

### 6. Mount without unmount — the component contract has no teardown/dispose discipline, so listener and timer leaks are unpinnable

**Proposal:** Extend Implementation Standards: "Every `mount*` function returns a disposer (or the element with a `.dispose()`): all `addEventListener` calls on targets that outlive the component (document, window, external stores) are registered with a single `AbortController` signal (`addEventListener(type, fn, { signal })`) and the disposer calls `controller.abort()`; intervals/observers (`setInterval`, `ResizeObserver`, `MutationObserver`, `IntersectionObserver`) are cleared/disconnected there too. Element-local listeners may rely on GC, but document/window listeners without a signal are a defect. Coordinate: a test that mounts, disposes, dispatches the formerly-observed event, and asserts the handler did not fire (spy not called) — one per external subscription. In tests, `afterEach` disposes before clearing `document.body.innerHTML`, so leak coordinates stay meaningful."

**Rationale:** The one-way-binding section (lines 207-209) defines mounting and intent emission but no end-of-life, and the example contract `mountTagPicker(root, {...})` (line 222) returns nothing. In long-lived no-framework SPAs — this handler's exact domain — leaked document-level delegates and observers are the canonical memory/correctness failure, and nothing in the current doctrine lets a test pin their absence.
