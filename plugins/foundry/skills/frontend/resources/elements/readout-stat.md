# Readout / Stat

## Description
A single salient number with a label and optional trend — the unbounded-quantity counterpart to the gauge. Operation-style instrument for reporting UI.

## When to use
Headline metrics (titles sold, total revenue share, words written today) where there is no fixed max.

## Anti-patterns
Crowding many stats with equal weight (nothing is salient then); trend arrows without a reference period; precision beyond the data's truth.

## Data contract
- **Value:** `{ number, label, unit?, trend? }`.
- **Binding:** one-way; re-render on `value.changed`.

## Vanilla-JS skeleton
```js
function Readout({ number, label, unit, trend }) {
  // big number + label + optional trend (with text, not arrow alone)
}
```

## Accessibility checklist (WCAG 2.1 AA)
Number + label associated; trend conveyed in text (e.g. "+12% vs last week"), not colour/arrow alone; sufficient contrast.

## Modality notes
- **Mouse/touch:** tap/hover reveals the comparison detail.
- **Keyboard-only:** focusable if it links to detail; otherwise read by SR.

## INTENT marker template
```html
<!--@front-end
element: readout-stat
philosophy: information-scent
paradigm: dashboard-explorative
intent: surface one headline number the customer cares about, with honest context
customer: <writer|seller>
binding: one-way
render-trigger: [value.changed]
modality: { mouse: full, keyboard: full }
density: moderate
style: operation
a11y: wcag-2.1-aa
improve?: "establish a one-primary-stat-per-panel rule to preserve salience"
breadcrumbs: [trend needs a stated reference period; describe trend in text]
-->
```

## Book-example
A writer's panel leads with **Words today: 1,240 (+18% vs daily avg)** as the one primary readout, supporting stats smaller beneath.
