# Accessibility — WCAG 2.2 AA + the evaluation method

> The floor that is never traded for aesthetics. An inaccessible screen is a *broken* screen, however
> beautiful — it simply breaks for people the designer didn't picture. DESIGN holds **WCAG 2.2 AA**, and
> knows that tools see only a fraction, so it *judges the rest*.

## The non-negotiables (WCAG 2.2 AA, the working subset)

| Area | The bar | How to check |
|---|---|---|
| **Contrast** | Body text ≥**4.5:1**; large text (≥24px, or ≥19px bold) and UI components/graphics ≥**3:1** (1.4.3 / 1.4.11). | Sample fg/bg from the screenshot; compute ratio. Flag near-misses (e.g. 3.9:1) explicitly. |
| **Keyboard** | Every action operable by keyboard; **no traps** (2.1.1/2.1.2); a visible **focus indicator** (2.4.7); focus **not obscured** by sticky bars (2.4.11, new in 2.2). | Read the accessibility tree / tab order; confirm focus is always visible and reachable. |
| **Target size** | Interactive targets ≥**24×24px** (2.5.8, new in 2.2); ≥44×44px is the comfortable touch bar (Fitts). | Measure controls; flag crowded/tiny taps. |
| **Name / role / value** | Every control exposes an accessible name, correct role, current value/state (4.1.2). | Inspect the a11y snapshot: unnamed buttons, icon-only controls without labels, custom widgets with wrong roles. |
| **Text alternatives** | Meaningful images have alt text; decorative ones are hidden (1.1.1). | Check `alt`/`aria` in the snapshot. |
| **Don't rely on colour** | Information is never conveyed by colour alone (1.4.1). | Errors/states also carry text/icon/shape. |
| **Forms & errors** | Labels tied to inputs; errors identified in text with guidance (3.3.1/3.3.2); no destructive surprises. | Inspect label associations; trigger/inspect error states. |
| **Structure & order** | Logical heading structure; reading and focus order match visual order (1.3.1/1.3.2/2.4.3). | Read the DOM/a11y tree order vs the screenshot. |
| **Motion** | Respect `prefers-reduced-motion`; no content flashing >3×/s (2.3.1); motion isn't the only cue. | Check for reduced-motion handling. |
| **Consistent help & focus** | Help in a consistent place (3.2.6, new in 2.2); consistent navigation. | Compare across crawled routes. |

## The method (why judgment is required)

> **Automated tools catch only ~30–57% of WCAG issues** (axe-core ~57% by volume; ~30% of success
> criteria are machine-checkable at all). The rest — meaningful alt text, logical reading order, whether
> a label actually describes its control, whether an error message is *useful* — needs a human-or-agent
> judgment. DESIGN does both:

1. **Automated pass (when available):** run `axe-core` via the chrome-devtools MCP (`mcp__chrome-devtools__*`) or
   note that it's unavailable. Treat its findings as a *floor*, not a ceiling.
2. **Structural pass:** read the **accessibility snapshot** (the a11y tree) — names, roles, states, focus
   order, headings. This is what assistive tech actually exposes; it catches what a screenshot can't.
3. **Visual pass:** read the screenshot for contrast, focus visibility, target size, colour-only signals,
   and layout/reading-order coherence.
4. **Judgment pass:** ask the questions tools can't — *Is this alt text meaningful? Does the focus order
   tell the same story as the layout? Is this error message actually actionable?*

> **Severity.** A WCAG-AA failure is at minimum a **HIGH** finding in the
> [`design-critique-loop`](../protocols/design-critique-loop.md) and a **non-negotiable** in the rubric:
> the loop does not converge to PASS while one stands. Aesthetics are never weighed against the floor.

---

> **Sources (the canon to cite):** W3C **WCAG 2.2** (cite the SC number — *1.4.3*, *2.4.11*, *2.5.8*…);
> Deque/axe-core coverage studies; WAI-ARIA Authoring Practices; the EAA (EU Accessibility Act, in force
> June 2025) for why this is table-stakes, not optional. Always cite the success-criterion number.
