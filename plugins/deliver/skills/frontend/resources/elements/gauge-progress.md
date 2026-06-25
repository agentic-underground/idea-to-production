# Gauge / Progress

## Description
Operation-style display of a **bounded quantity** — a gauge, bar, or ring — read at a glance. The instrument register's workhorse.

## When to use
Progress (reading completion, upload), capacity (stock vs target), or any value with a meaningful min/max. Part of dashboards and reporting UI.

## Anti-patterns
Gauges for unbounded values (use a readout/stat instead); precision the data doesn't have; animation that obscures the current value.

## Data contract
- **Value:** `{ current, min, max }` plus optional target.
- **Binding:** one-way; re-render on `value.changed`.

## Vanilla-JS skeleton
```js
function Gauge({ current, min, max, label, onIntent }) {
  // draw bar/ring scaled to (current-min)/(max-min); expose value as text too
}
```

## Accessibility checklist (WCAG 2.1 AA)
Use `role="progressbar"` with `aria-valuenow/min/max`; always show the value as text, not shape alone; non-text contrast ≥3:1; respect reduced-motion.

## Modality notes
- **Touch/mouse:** tap/hover reveals exact value + target.
- **Keyboard-only:** focusable if interactive; value read by screen reader regardless.

## INTENT marker template
```html
<!--@front-end
element: gauge-progress
philosophy: information-scent
paradigm: dashboard-explorative
intent: let the customer judge a bounded quantity instantly, with exact value on demand
customer: <writer|seller|...>
binding: one-way
render-trigger: [value.changed]
modality: { mouse: full, keyboard: full }
density: moderate
style: operation
a11y: wcag-2.1-aa
improve?: "explore target/threshold markers; test colour-independent state cues"
breadcrumbs: [only for bounded values; always expose numeric value as text]
-->
```

## Book-example
A writer's dashboard shows manuscript **completion** as a ring (62%) and a **revenue-share** bar against a monthly target.
