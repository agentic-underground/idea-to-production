# Pill / Tag / Badge

## Description
A small token rendering a referenced or categorical value. **Pill/tag** = a selected reference (often dismissible); **badge** = a status or count. The operation-style counterpart to lookup fields.

## When to use
Show the output of a multi-select lookup; surface status (available / out of stock), counts, or categories at a glance.

## Anti-patterns
Colour-only status (fails contrast/colour-blind users — pair with text/icon); tags that look interactive but aren't; unbounded pill rows with no wrap/overflow handling.

## Data contract
- **Value:** a label + optional id + optional tone (neutral/positive/warn/danger).
- **Binding:** one-way; if dismissible, `remove(id)` emitted upward.

## Vanilla-JS skeleton
```js
function Pill({ label, tone, removable, onIntent, id }) {
  // token + optional ✕; ✕ => onIntent({type:'remove', id})
}
```

## Accessibility checklist (WCAG 2.1 AA)
Status conveyed by text/icon, not colour alone; non-text contrast ≥3:1; dismiss is a labelled ≥44×44px button; decorative pills not announced as interactive.

## Modality notes
- **Touch:** dismiss target large and separated from the label.
- **Mouse:** hover shows dismiss; tooltip for truncated labels.
- **Keyboard-only:** dismissible pills focusable; Delete/Backspace removes.

## INTENT marker template
```html
<!--@front-end
element: pill-tag-badge
philosophy: recognition-over-recall
paradigm: form-as-document
intent: render a reference or status as a glanceable token
customer: <...>
binding: one-way
render-trigger: [value.changed]
modality: { touch: full, mouse: full, keyboard: full }
density: moderate
style: operation
a11y: wcag-2.1-aa
improve?: "explore tone semantics shared across the app; test overflow (wrap vs +N more)"
breadcrumbs: [never signal status by colour alone]
-->
```

## Book-example
A book card shows an *Available* badge (green + text + dot) and genre **tags**; in the editor those same tags are dismissible pills from the multi-select lookup.
