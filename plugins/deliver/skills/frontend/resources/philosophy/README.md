# Philosophy Map — read this first

FRONT-END's job is to present rich, data-bound information so that the **end-customer** is comfortable at minimum and delighted at best, while the **developer** can reason about and grow the system coherently. These pages are the shared vocabulary. Load only those relevant to the task at hand.

## The non-negotiables
- `accessibility.md` — WCAG 2.1 AA is the floor, defended.
- `privacy-as-architecture.md` — the customer's data is theirs; local-first; cloud only on explicit opt-in.

## The strong defaults (present, then question — never silently enforce)
- `three-modalities.md` — touch (three-tap ceiling), mouse+keyboard, keyboard-only; all first-class.
- `density-and-cognitive-load.md` — moderate default + toggle; per-screen/per-panel load budgets.
- `data-binding.md` — one-way binding, render-triggers, real-time validation.
- `words-vs-operation.md` — the two display registers every element answers in.

## Orientation & technique
- `paradigms.md` — form-as-conversation / form-as-document / spreadsheet-dense / dashboard-explorative.
- `look-and-feel.md` — the tone vocabulary to commit to a direction.
- `layout-and-flow.md` — page balance, input flow, tab order, keyboard optimisation.
- `rich-data-presentation.md` — techniques for information-rich screens.
- `architecture-styles.md` — Richards & Ford's nine styles, applied to front-end composition.

## How they fit together
Customer + device → **paradigm** + **style register** + **density**, expressed through **elements**, composed via **layout-and-flow**, bound **one-way**, gated by **accessibility** and **privacy**, and recorded in **INTENT markers** so the next agent inherits the reasoning, not just the result.
