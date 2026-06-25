# Multi-Select Lookup (Tag Picker)

## Description
A field that holds **multiple references to records in another table** — rendered as dismissible pills, chosen from a searchable dropdown of existing records. The stored value is an **array of foreign-key integers** (`number[]`), never free text. Also known as: multi-select lookup, relational tag picker, referenced multi-select, constrained multi-combobox.

## When to use
- A field points to *many* rows in a reference table the customer maintains elsewhere (e.g. a `tags` table).
- Free-text entry would create dirty, unjoinable data.
- The customer benefits from **recognition over recall** — seeing the options beats remembering them.

## Anti-patterns
- Allowing free typing that creates new records silently (offer inline-create only behind an explicit confirm; record it in `improve?`).
- Storing labels instead of ids (breaks rename; the id is the contract).
- Unbounded dropdown with no search above ~12 options (consider a token-grid — see `improve?`).

## Data contract
- **Value:** `number[]` — ids referencing the source table.
- **Source of truth:** the referenced table (e.g. `tags`), edited elsewhere, not here.
- **Binding:** one-way. The field renders from `value`; user actions emit intents (`add(id)`, `remove(id)`) the host applies, which re-triggers render on `tags.changed` / `value.changed`.
- **Validation:** every id must resolve to a live source record; drop/flag dangling ids in real time.

## Vanilla-JS skeleton (illustrative contract, not production-final)
```js
// one-way: render(value, options) -> DOM; user actions emit intents upward
function MultiSelectLookup({ value, options, onIntent }) {
  // value: number[]  options: {id:number,label:string}[]
  // renders selected pills + a searchable, keyboard-navigable listbox
  // pill ✕ => onIntent({type:'remove', id})
  // option pick => onIntent({type:'add', id})
  // never mutates value directly
}
```
Use a native-feeling combobox: text input filters `options` (type-to-filter, **not** free entry); ↓/↑ move active option; Enter adds; Backspace on empty input removes last pill; Esc closes.

## Accessibility checklist (WCAG 2.1 AA)
- Input has a programmatic label (`aria-label`/`<label>`); listbox uses `role="listbox"`/`option` with `aria-activedescendant`.
- Each pill's remove control is a real button, ≥44×44px touch target, with `aria-label="Remove <label>"`.
- Visible focus on input, active option, and pills. Selection changes announced (`aria-live` polite).
- Fully operable by keyboard alone.

## Modality notes
- **Touch:** tap field → tap option → done (within three-tap ceiling); pills show a large ✕.
- **Mouse:** hover affordance on options and pill ✕; click to add/remove.
- **Keyboard-only:** focus field, type to filter, arrow + Enter to add, Backspace to remove last, Esc to close — no mouse needed.

## INTENT marker template
```html
<!--@front-end
element: multi-select-lookup
philosophy: recognition-over-recall
paradigm: form-as-document
intent: let the customer attach many existing tags without free typing or leaving the form
customer: <seller|reader|writer|analyst|...>
binding: one-way
render-trigger: [tags.changed, value.changed]
modality: { touch: 3-tap, mouse: full, keyboard: full }
density: moderate
style: words
a11y: wcag-2.1-aa
refs: [airtable-multi-select, notion-relation-field]
improve?: "above ~12 options consider token-grid; explore confirm-gated inline-create"
breadcrumbs: ["value is number[] of ids", "tags table is source of truth", "store ids not labels"]
-->
```

## Book-example
On a seller's catalogue editor, a book's **genres** field is a multi-select lookup into the seller's `genres` table: they tag *Fiction*, *Mystery*, *Translated* as pills, each an id. Renaming "Translated → In Translation" in the genres table updates every book instantly, because the field stored ids, not text.
