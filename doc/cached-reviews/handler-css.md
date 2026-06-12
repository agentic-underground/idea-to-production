# Cached review — FOUNDRY handler-css

**Target file:** `plugins/foundry/agents/handler-css.md`  
**Unit:** `handler-css`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Frontmatter tool allowlist `mcp__playwright__*` does not match the plugin-prefixed MCP tool names actually exposed

**Evidence:** Line 10: `tools: Read, Write, Edit, Bash, Grep, Glob, mcp__playwright__*`. FOUNDRY registers Playwright as a plugin MCP server (`plugins/foundry/.mcp.json`, server key `playwright`), and plugin MCP tools are exposed under the plugin-prefixed namespace — observed live in this very environment as `mcp__plugin_foundry_context7__query-docs` and `mcp__plugin_atelier_playwright__browser_click`, i.e. the pattern is `mcp__plugin_<plugin>_<server>__*`, not `mcp__<server>__*`. The handler's tooling banner (lines 18-22) and `knowledge/tooling/live-feedback.md` line 17 repeat the unprefixed form.

**Recommendation:** Verify against the current Claude Code plugin-MCP naming and update the frontmatter allowlist (and the tooling banner) to the form that actually resolves — e.g. `mcp__plugin_foundry_playwright__*` — or to a documented harness-supported alias. Until fixed, the handler's advertised live visual-feedback capability (screenshots at breakpoints, computed-style inspection, dark-mode checks) is silently denied: the agent is told to rely on tools its allowlist never grants. This is fleet-wide (handler-js, handler-react, live-feedback.md carry the same string), so fix the canonical doc and all handlers together.

### 2. [HIGH] Hardcoded concrete model IDs in the Spawning Model Policy table violate the model-pin policy

**Evidence:** Lines 82-84: `| ds-step-3-tests | TEST (Phase 3) | claude-haiku-4-5 (test code) |` … `claude-sonnet-4-6` … `claude-opus-4-8`. The canonical policy (`knowledge/policy/model-selection.md`) states: "agents reference this table instead of pinning model IDs in their own frontmatter, so the whole fleet can be re-tiered in one edit (and pinned IDs cannot silently age out)" and "Resolve at spawn time, do not hardcode." handler-css's table carries the IDs with no reference to the policy doc, so when the ID table re-tiers, this file silently ages out — exactly the failure the policy exists to prevent. handler-python (lines 82-83) already shows the compliant form: it cites the policy doc above its table.

**Recommendation:** Replace the concrete IDs with tier names (haiku / sonnet / opus) and add the handler-python-style preamble: "This handler's frontmatter is `model: inherit` — the spawning phase agent chooses the model per the model-selection policy ([`../knowledge/policy/model-selection.md`](../knowledge/policy/model-selection.md))". Let the policy doc carry the ID resolution. Also note the same drift exists in handler-js and handler-react.

### 3. [HIGH] The mandated accessibility gate is vacuous for the handler's own non-negotiables: jest-axe in jsdom cannot evaluate colour contrast

**Evidence:** Lines 111-124 mark jest-axe in a jsdom/Testing Library environment as "Accessibility testing (mandatory)", while line 167 declares "Colour contrast: ≥ 4.5:1 for normal text, ≥ 3:1 for large text (WCAG AA)" non-negotiable and line 46 declares "100% accessibility-violation-free is the floor". axe-core's `color-contrast` rule is disabled/inapplicable under jsdom because jsdom performs no rendering — so the only mandated test pattern structurally cannot detect a violation of the handler's headline non-negotiable. A component with 1.1:1 contrast passes this gate clean.

**Recommendation:** State the jsdom limitation explicitly and mandate browser-real verification for render-dependent rules: contrast, focus-visible appearance, reduced-motion, and target size must be asserted via `@axe-core/playwright` (`new AxeBuilder({ page }).analyze()`) or explicit computed-value checks in a real browser. Keep jest-axe for structural rules (ARIA, roles, labels) and say which class of rule each tool covers, so "100% violation-free" is a claim the tests can actually prove.

### 4. [MEDIUM] Computed-style assertion example runs in jsdom, where external stylesheets are not applied — the coordinate passes or fails for the wrong reason

**Evidence:** Lines 134-138: `const element = screen.getByRole('button'); const styles = window.getComputedStyle(element); expect(styles.display).toBe('flex')`. `screen` implies Testing Library under jsdom; jsdom does not load external `.css`/`.scss` build output into the cascade, so `getComputedStyle` will not reflect the stylesheet under test unless the CSS is manually injected. The handler's own doctrine (line 57) says coordinates must "assert the rendered outcome … not the CSS source text" — this example asserts in an environment that doesn't render the stylesheet.

**Recommendation:** Either show the injection step (read the built CSS and append a `<style>` element to the jsdom document before asserting) or move computed-style coordinates to Playwright (`page.locator(...).evaluate(el => getComputedStyle(el).display)`), and say explicitly that jsdom-based getComputedStyle is only valid for inline/injected styles.

### 5. [MEDIUM] WCAG 2.1 is stale against both the standard and the marketplace's own canon, and the 44×44 target-size figure is mis-attributed to AA

**Evidence:** Line 5 and line 47: "accessibility (WCAG 2.1)" / "WCAG 2.1 AA is non-negotiable." WCAG 2.2 has been the W3C Recommendation since October 2023 (current date: June 2026), and FOUNDRY's own reviewer already gates on it — `agents/reviewer.md` line 577: "(WCAG 2.2 AA for documents)"; the atelier plugin's design reviewer is likewise WCAG 2.2. Additionally line 169's "Touch targets: ≥ 44×44px" is WCAG 2.1 **AAA** (2.5.5); the AA-level requirement is 2.2's 2.5.8 (24×24 minimum) — listing 44×44 under "non-negotiable" AA conflates levels and versions.

**Recommendation:** Move the handler to WCAG 2.2 AA and add the 2.2-new success criteria it must defend in CSS (2.4.11 Focus Not Obscured, 2.5.8 Target Size Minimum 24×24). Keep 44×44 if desired, but label it as the house standard exceeding AA, not as the AA requirement.

### 6. [MEDIUM] Description promises CSS-in-JS expertise; the body contains zero CSS-in-JS doctrine

**Evidence:** Line 6: "CSS custom properties, BEM, responsive design, accessibility (WCAG 2.1), CSS-in-JS patterns, and visual regression testing." The only other occurrence of the concept is the env probe on line 96 grepping for `styled|emotion`. There is no Implementation Standard, test pattern, or guidance for styled-components/Emotion/vanilla-extract anywhere in the body — the spawning orchestrator selects this handler on the description's promise, and the cold-start agent has nothing to honour it with.

**Recommendation:** Either delete "CSS-in-JS patterns" from the description (and let handler-react/handler-js own it), or add a short CSS-in-JS standards section: theme objects map to custom properties, no runtime style recalculation in hot paths, testing via rendered computed styles not snapshot of generated class names.

### 7. [MEDIUM] SUBJECT_MATTER_UNDERSTANDING is claimed in the description but never operationalised in the body

**Evidence:** Lines 8-9: "Carries the KAIZEN self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." The body never instructs the agent to locate or read it. The builder skill establishes the artefact at a known path (`skills/builder/SKILL.md` line 77: "Check for `doc/SUBJECT_MATTER_UNDERSTANDING.md`"), so a cold-start handler has no instruction connecting the claim to the file.

**Recommendation:** Add one line after the implementation-covenant instruction (line 31): "Read `doc/SUBJECT_MATTER_UNDERSTANDING.md` in the target project if it exists; if absent, ask the spawning phase agent for the domain context before styling decisions that encode domain meaning (status colours, severity scales, density)."

### 8. [MEDIUM] No failure-mode handling: absent tooling, non-Node stacks, and malformed specs are unaddressed

**Evidence:** The only conditional in the whole file is line 126: "Visual regression (if Playwright is in the stack)". There is no protocol for: Playwright MCP unavailable (the live-feedback banner assumes it), no axe/jest-axe in the project (the "mandatory" pattern at line 113 imports jest-axe unconditionally), no JS test runner at all (a Rails/Django/static-site SCSS project — yet line 96/102 pipe `cat package.json`, which errors when no package.json exists), or a design spec that contradicts the a11y floor (e.g. spec demands 2:1 contrast).

**Recommendation:** Add a "Degradation ladder" section: (1) required a11y tooling missing → install dev-dependency if the phase agent permits, else surface as a blocking gap, never skip the gate silently; (2) non-Node stack → use Playwright CLI or pa11y against a served page; (3) spec conflicts with the WCAG floor → refuse and escalate to the phase agent with the exact failing criterion, mirroring the existing wrong-model refusal at lines 86-87.

### 9. [LOW] Environment-probe commands are silently broken in non-interactive bash

**Evidence:** Line 95: `ls *.css *.scss src/**/*.css src/**/*.scss 2>/dev/null | head -20` — `**` requires `shopt -s globstar`, which is off in non-interactive bash, so nested stylesheets are silently missed and the probe under-reports the stack. Lines 96/102 use `cat package.json | grep …`, which prints an error and yields nothing on non-Node projects.

**Recommendation:** Replace with `find . -name '*.css' -o -name '*.scss' | grep -v node_modules | head -20` and guard the manifest probe: `[ -f package.json ] && grep -E 'sass|postcss|tailwind|styled|emotion|axe|pa11y' package.json`.

### 10. [LOW] No output/completion contract — the handler never says what it hands back to the spawning phase agent

**Evidence:** The file ends at the KAIZEN Covenant note (lines 183-187) with no section defining the completion report: which files changed, which coordinates (state × breakpoint × a11y axes) were added, what a11y evidence accompanies the work. The inspection criteria for agent definitions require an "output/completion protocol precise", and the marketplace ships a handoff schema (`skills/handoff-protocol/SKILL.md`) this handler never references.

**Recommendation:** Add a "Completion report" section: list of styles touched, the coordinate table (state/breakpoint/a11y axis → test file), axe results summary, screenshot baselines added/updated, and any flagged covenant items — formatted per the handoff-protocol schema so the phase agent can populate `reviewer_status` without re-deriving it.

## Capability-uplift proposals

### 1. No modern-CSS doctrine: container queries, :has(), cascade layers, native nesting, logical properties

**Proposal:** Add an Implementation Standards subsection "Modern CSS (baseline 2024+)": Prefer container queries (`@container`, `container-type: inline-size`) over viewport media queries for component-level responsiveness — a component must adapt to its container, not the page. Use `@layer reset, tokens, components, utilities;` to make specificity ordering explicit; never win a specificity war with `!important` or selector stacking. Use logical properties (`margin-inline`, `padding-block`, `inset-inline-start`) instead of physical ones so RTL locales work without overrides. Native CSS nesting is allowed to BEM-element depth only (one level); `:has()` is allowed for state-driven parent styling but each `:has()` usage needs its own coordinate. Each modern feature used must be checked against the project's browserslist; if unsupported, write the @supports fallback and a coordinate for both branches.

**Rationale:** The handler's newest techniques are custom properties and mobile-first media queries — circa 2018. Container queries, :has(), and @layer have been baseline across all evergreen browsers since 2023-2024; a 2026 CSS specialist that never reaches for them produces structurally worse, less maintainable styling, and viewport-only responsiveness fails the marketplace's own component-composability standards.

### 2. SCSS expertise claimed but no Sass module-system doctrine; @import deprecation unaddressed

**Proposal:** Add an Implementation Standards subsection "Sass modules (non-negotiable for SCSS work)": Use `@use`/`@forward` exclusively; `@import` is deprecated since Dart Sass 1.80 and is removed in Dart Sass 3.0 — treat any new `@import` as a blocking defect and flag existing ones for migration (`npx sass-migrator module --migrate-deps <entry>`). Namespace by default (`@use 'tokens' as t; color: t.$primary`), `as *` only for a single project-level tokens module. Built-in modules over global functions: `math.div()` never `/` division, `color.adjust()` never `darken()`/`lighten()` (also deprecated). Partials expose a public API via a `_index.scss` `@forward` hub; private members are `-` prefixed.

**Rationale:** The description (line 4) claims "SCSS/Sass" expertise, but the body's entire Sass content is a 3-line BEM snippet. The @import→@use migration is the single largest correctness/currency issue in real SCSS codebases today; a handler that writes new `@import` lines in 2026 ships deprecation warnings and future build breakage.

### 3. Visual-regression flake discipline absent — one toHaveScreenshot line with no determinism doctrine

**Proposal:** Add a "Visual regression — determinism rules" subsection: Every screenshot coordinate must be deterministic before it lands: (1) disable animations (`page.emulateMedia({ reducedMotion: 'reduce' })` plus Playwright's `animations: 'disabled'` screenshot option); (2) wait for fonts (`await page.evaluate(() => document.fonts.ready)`); (3) mask dynamic regions (timestamps, avatars) via the `mask` option — never widen `maxDiffPixelRatio` past 0.01 to absorb nondeterminism; (4) pin viewport and deviceScaleFactor in the project's playwright config, and note that baselines are renderer-specific — generate CI baselines inside the same container image CI uses (`npx playwright test --update-snapshots` in the CI image), never commit local-OS baselines for a Linux CI. A flaky screenshot coordinate is a defect in the test, not a reason to delete the coordinate.

**Rationale:** Lines 128-130 mandate screenshot tests with zero guidance on the dominant failure mode of visual regression in practice: cross-platform font/AA rendering and animation flake. Without this doctrine the handler will produce snapshot suites that get deleted or tolerance-widened into uselessness within weeks — eroding the test-first mandate it exists to enforce.

### 4. No lint/static-analysis discipline — the only CSS handler standard not backed by a machine check

**Proposal:** Add to Environment Assumptions and Implementation Standards: "Stylelint is the CSS counterpart of the type checker. If the project lacks it, propose adding `stylelint` with `stylelint-config-standard-scss` (SCSS) or `stylelint-config-standard` (CSS), wired into the test script so the pipeline fails on violations. House rules to enable: `declaration-no-important` (warn), `selector-max-specificity: 0,3,0`, `selector-class-pattern` matching the project's BEM regex `^[a-z]([a-z0-9-]+)?(__[a-z0-9-]+)?(--[a-z0-9-]+)?$`, and `plugin/no-unsupported-browser-features` against the project browserslist. Run stylelint before declaring any style coordinate green — a lint violation in shipped CSS is a defect at the same severity the language handlers give a type error."

**Rationale:** handler-js gets type checking and ESLint culture for free from its ecosystem; handler-css names no static gate at all, so BEM naming (lines 174-178), specificity hygiene, and browser-support claims rest entirely on agent self-discipline. A deterministic lint gate is cheaper than a review finding and is standard practice in every serious CSS codebase.

### 5. Dark mode and design-token governance are demanded as coordinates but have no implementation doctrine

**Proposal:** Add an Implementation Standards subsection "Theming & dark mode": Tokens live in two tiers — primitive (`--blue-600`) and semantic (`--color-surface`, `--color-text`); components consume only semantic tokens. Dark mode redefines semantic tokens once, under `@media (prefers-color-scheme: dark)` (or the project's `[data-theme=dark]` attribute switch), never per-component overrides; set `color-scheme: light dark` on `:root` so form controls and scrollbars follow. Both themes carry the full contrast coordinate set — dark mode commonly fails 4.5:1 on muted text, so the contrast assertion runs once per theme. Test `forced-colors: active` (Windows High Contrast) at least for focus indicators and borders: anything conveyed only by `background-color` disappears there. Honour `prefers-reduced-motion: reduce` by disabling non-essential transitions at the token layer (`--motion-duration: 0ms`).

**Rationale:** The tooling banner (line 19-20) and the coordinates section (line 59) both name dark mode as a first-class test axis, and reduced-motion is listed as a coordinate (line 61) — yet the Implementation Standards (lines 142-178) contain no theming, color-scheme, forced-colors, or motion doctrine. The handler is told to test what it was never taught to build.

### 6. No browser-real accessibility tooling beyond jest-axe — contrast, focus, and target-size cannot currently be proven

**Proposal:** Add a "Browser-real a11y verification" subsection: jest-axe under jsdom covers structural rules only (roles, ARIA, labels, landmark order); render-dependent rules — color-contrast, target size, focus-visible appearance, reduced-motion behaviour — MUST run in a real browser. Standard pattern: `import AxeBuilder from '@axe-core/playwright'; const results = await new AxeBuilder({ page }).withTags(['wcag2a','wcag2aa','wcag22aa']).analyze(); expect(results.violations).toEqual([])` — one run per theme and per breakpoint that changes layout. Focus indicators get an explicit coordinate: Tab to the element and assert a non-`none` outline or a computed style delta vs the unfocused state. Target size gets a bounding-box assertion (`boundingBox()` width/height ≥ 24, house standard 44). If neither Playwright nor a browser is available in the stack, surface a BLOCKING gap to the phase agent — never report the a11y floor as met on jsdom evidence alone.

**Rationale:** This is the capability companion to the HIGH finding above: the handler's headline guarantee ("100% accessibility-violation-free", contrast non-negotiables) is currently unverifiable with the only tooling it teaches. @axe-core/playwright is already adjacent to the stack (Playwright MCP is in the tool list), so the uplift closes the gap with tooling the pipeline already carries.
