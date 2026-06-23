---
name: ui-review
description: >
  Adversarially review the design of any running app or screenshot — and write a scored, prioritised
  critique. Trigger with /ui-review (or "review the UI", "critique this design/screen", "design review",
  "what does the UI look like", "audit the accessibility of this page"). Crawls the navigable routes of an
  SPA via the chrome-devtools MCP (screenshot + accessibility snapshot per route), or critiques a screenshot you
  paste. Grounds every finding in named design canon (Gestalt, the UX laws, Nielsen's heuristics, WCAG
  2.2) and scores it on the design-fitness rubric. Use proactively whenever someone wants to know whether a
  UI is good — and why.
metadata:
  type: producer
  output: a scored, prioritised design-review report (docs/guide/design/review/<date>/design-review.md)
model: inherit
---

# ATELIER — UI review (crawl + adversarial critique)

The user-invokable design critic. It answers "is this UI good?" with evidence: a **fitness score**, a
**prioritised list of findings each citing a named principle**, and the **biggest quick win** — for a
whole SPA or a single pasted screenshot. It is adversarial by stance and grounded by canon.

> **Stance — adversarial, grounded, kind to the user (not the design).** Assume the design is wrong until
> each canon lens fails to break it; a clean pass is *earned*. But never invent findings to look busy, and
> never critique against an unknown goal — recover the intent first. (Covenant:
> [`../../knowledge/covenant.md`](../../knowledge/covenant.md); canon:
> [`../../knowledge/canon/README.md`](../../knowledge/canon/README.md).)

## Modes

| You have… | Path |
|---|---|
| A running app / dev-server URL | **Crawl** — enumerate navigable routes, screenshot + a11y-snapshot each, critique all. |
| One or a few screenshots (pasted or on disk) | **Ad-hoc** — `Read` the image(s) and critique immediately. No crawl, no server. |
| A foundry-built UI with `@front-end` INTENT markers | **Compose** — read the markers (by capability) to recover intent, then critique the *rendered* result and extend the build-time `design-critic`. |

## How to run (crawl mode)

1. **Recover intent + scope the target.** What is this app *for*, and for *whom*? Read `@front-end` INTENT
   markers if foundry is present. **Find the dev-server URL** (ask, or detect a running server). **If it is
   ambiguous which graphical elements/routes to review** — many routes, auth-walled areas, embedded
   canvases/maps/charts — **ask the user** which surfaces matter (offer a sensible default: all top-level
   nav routes + their primary states). Never guess the scope of a review.
2. **Enumerate the navigable surface.** Prefer the **chrome-devtools MCP** (`mcp__chrome-devtools__*`): navigate to
   the base URL, read the **accessibility snapshot** + same-origin links/nav to discover routes, and visit
   each. Capture, per route: a **screenshot** (desktop 1440×900 **and** mobile 375×812) and the **a11y
   tree**. For a committed snapshot instead, run the crawler script (below). If the MCP is unavailable,
   say so and fall back to the script or to pasted screenshots.
3. **Run `axe-core` when available** (via the MCP) for the automated accessibility floor — then judge the
   ~50%+ it misses ([`../../knowledge/canon/accessibility.md`](../../knowledge/canon/accessibility.md)).
4. **Critique each surface against the canon**, in order of human impact: visual-foundations →
   interaction-laws → accessibility. For every finding name **(a)** the principle, **(b)** the violation,
   **(c)** the user cost, **(d)** the fix, **(e)** the rubric dimension. Score each surface on the
   **design-fitness rubric** ([`../../knowledge/protocols/design-critique-loop.md`](../../knowledge/protocols/design-critique-loop.md)).
5. **Synthesise.** Identify 3–5 **systemic themes** (patterns across surfaces, not repeated singletons),
   the **overall fitness score**, and the single **biggest quick win** (highest impact / lowest effort).
6. **Write the report** (see Output). Offer to drive the **convergent loop** (`/mockup`-style: apply
   HIGH+MED, re-render, re-score until CONVERGED or diminishing-returns) — fixes are proposals only until
   the user approves them.

## The committed-snapshot crawler (optional, no MCP needed)

```bash
BASE_URL=http://localhost:5173 node ${CLAUDE_PLUGIN_ROOT}/skills/ui-review/scripts/crawl.mjs
# optional: ROUTES="/,/dashboard,/settings"  OUT=docs/guide/design/review/$(date +%F)  VIEWPORTS=desktop,mobile
```
It discovers same-origin links from the base URL (or uses an explicit `ROUTES` list), screenshots each at
the requested viewports, and writes a screenshot **gallery** `README.md` + `screenshots/`. It is
**target-agnostic** — no hardcoded panels, selectors, or ports. The crawler emits *only* that gallery; the
scored **critique** `design-review.md` is written by **this skill** (step 6, Output), alongside it. Then
critique the saved PNGs with `Read` (built-in vision, no API key). See
[`references/crawl-config.md`](references/crawl-config.md).

## Output

Write `docs/guide/design/review/<date>/design-review.md`:

```markdown
# Design Review — <date>   ·   Fitness: <score>/100
> Adversarial critique grounded in named design canon. Suggestions are proposals — approve what to apply,
> then run the convergent loop to verify the score rises.

## Executive summary
- **Fitness:** <score>/100   ·   **Accessibility gate:** PASS | FAIL (n WCAG-AA failures)
- **Systemic themes (3–5):** …
- **Biggest quick win:** …

## Per-surface findings
### <Route / screen>   ·   <sub-score>/100   ![](screenshots/<file>.png)
| Pri | Finding (principle → violation → user cost) | Fix | Dimension |
|-----|---------------------------------------------|-----|-----------|
| HIGH | Fitts's Law — primary CTA is 28px on touch, crowded by a destructive action → mis-taps | enlarge to ≥44px; separate destructive action | usability |
…
```

Then report: surfaces reviewed, the score + gate verdict, the count of HIGH/WCAG findings, and an offer to
run the convergent improvement loop or to critique any pasted screenshot ad-hoc.

## Self-improvement

Carries the KAIZEN covenant. When a shipped design proves weak in a way this review *missed*, that is a
**canon or rubric gap** — flag it for the `self-improve` skill so a PR sharpens the canon and every future
review catches it ([`../self-improve/SKILL.md`](../self-improve/SKILL.md)).
