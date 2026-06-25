# Browse Grid

## Description
A responsive grid of cards or tiles for exploring a collection comfortably. The composition layer above Data Card / Cover-Image Tile.

## When to use
Reader/seller collection views. Balances density against breathing room per the density philosophy.

## Anti-patterns
Fixed column counts that break on small screens; no keyboard roving; loading the whole collection eagerly (see ROADMAP virtualization for large sets).

## Data contract
- **Value:** an ordered list of record projections + paging/scroll state.
- **Binding:** one-way; `open(id)`, `loadMore()` emitted upward.

## Vanilla-JS skeleton
```js
function BrowseGrid({ records, onIntent }) {
  // responsive auto-fill grid of tiles/cards; roving tabindex; loadMore on demand
}
```

## Accessibility checklist (WCAG 2.1 AA)
Grid semantics or a labelled list; roving tabindex with arrow navigation; visible focus; reflow at 200% zoom without loss.

## Modality notes
- **Touch:** comfortable spacing; one tap opens; lazy-load on scroll.
- **Mouse:** hover affordances; click opens.
- **Keyboard-only:** arrow keys move between cells; Enter opens; Home/End jump.

## INTENT marker template
```html
<!--@front-end
element: browse-grid
philosophy: information-scent
paradigm: dashboard-explorative
intent: let the customer explore a collection comfortably across all three modalities
customer: <reader|seller>
binding: one-way
render-trigger: [collection.changed]
modality: { touch: full, mouse: full, keyboard: roving }
density: moderate
style: operation
a11y: wcag-2.1-aa
improve?: "large collections need virtualization (see ROADMAP); test density toggle here"
breadcrumbs: [responsive auto-fill, not fixed columns; lazy-load beyond first screen]
-->
```

## Book-example
The seller's catalogue and the reader's library are the same browse grid with different tile styles and density defaults.
