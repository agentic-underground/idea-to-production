# Single Lookup

## Description
Pick exactly **one** referenced record from a constrained, searchable list. Stored value is a single foreign-key integer (`number | null`). The single-select sibling of the multi-select lookup.

## When to use
A field points to one row in a reference table (e.g. a book's `journal` or `publisher`). Recognition over recall; no free text.

## Anti-patterns
Free typing that forks the canonical list; storing label instead of id; a giant unsearchable dropdown.

## Data contract
- **Value:** `number | null` (id).
- **Source of truth:** the referenced table, maintained elsewhere.
- **Binding:** one-way; `select(id)` / `clear()` emitted upward; re-render on `value.changed`.
- **Validation:** id must resolve; flag dangling in real time.

## Vanilla-JS skeleton
```js
function SingleLookup({ value, options, onIntent }) {
  // renders current label + searchable listbox; pick => onIntent({type:'select', id})
  // clear control => onIntent({type:'clear'})
}
```

## Accessibility checklist (WCAG 2.1 AA)
Labelled combobox; `role="listbox"`/`option`; visible focus; selection announced; ≥44×44px controls; keyboard-operable.

## Modality notes
- **Touch:** tap → tap option (≤3 taps).
- **Mouse:** hover + click.
- **Keyboard-only:** type-to-filter, ↓/↑, Enter, Esc.

## INTENT marker template
```html
<!--@front-end
element: single-lookup
philosophy: recognition-over-recall
paradigm: form-as-document
intent: let the customer choose one existing record without free text
customer: <...>
binding: one-way
render-trigger: [value.changed]
modality: { touch: 3-tap, mouse: full, keyboard: full }
density: moderate
style: words
a11y: wcag-2.1-aa
improve?: "consider showing the chosen record's secondary detail inline"
breadcrumbs: [value is one id or null; store id not label]
-->
```

## Book-example
A book's **publisher** field: one id into the seller's `publishers` table. Rename the publisher once, every book reflects it.
