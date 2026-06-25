# Data Card

## Description
A compact, scannable summary of one record. For a book: cover, title, author, year, plus contextual actions. The composable unit of browse grids and lists.

## When to use
Collections the customer scans and acts on; the bridge between a row of data and a full detail view.

## Anti-patterns
Cramming every field onto the card (defeats scannability); inconsistent card heights that break the grid rhythm; action overload past the three-tap budget.

## Data contract
- **Value:** a record projection (only the fields the card shows).
- **Binding:** one-way; actions emit intents (`open`, `buy`, `lend`...).
- **Validation:** n/a for display; show graceful fallbacks for missing cover/field.

## Vanilla-JS skeleton
```js
function DataCard({ record, actions, onIntent }) {
  // cover + title + author + year + action affordances
  // action => onIntent({type:action, id:record.id})
}
```

## Accessibility checklist (WCAG 2.1 AA)
Card is a labelled region; cover has alt text (or empty alt if decorative + visible title); actions are real buttons; logical focus order; ≥44×44px targets.

## Modality notes
- **Touch:** whole card tappable to open; secondary actions in a three-tap menu.
- **Mouse:** hover elevates/reveals secondary actions.
- **Keyboard-only:** card focusable; Enter opens; actions reachable in order.

## INTENT marker template
```html
<!--@front-end
element: data-card
philosophy: information-scent
paradigm: form-as-document
intent: give the customer a scannable, actionable summary of one record
customer: <reader|seller|...>
binding: one-way
render-trigger: [record.changed]
modality: { touch: 1-tap-open, mouse: full, keyboard: full }
density: moderate
style: mixed
a11y: wcag-2.1-aa
improve?: "for readers, explore cover-forward delight; for sellers, surface price/availability density"
breadcrumbs: [keep card heights uniform to preserve grid rhythm]
-->
```

## Book-example
A reader's browse view renders each title as a cover-forward card (delight); the same record on the seller's screen becomes a denser card showing price and stock.
