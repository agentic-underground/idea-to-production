# Cover-Image Tile

## Description
An image-forward browse unit — cover dominant, minimal text — optimised for delightful visual scanning in a grid.

## When to use
Reader-facing browse experiences where the image is the primary scent (book covers, album art). Operation-style; comfort/delight first.

## Anti-patterns
Tiny covers drowned in metadata; non-uniform aspect ratios that break the grid; missing alt text; layout shift as images load.

## Data contract
- **Value:** `{ image, title, id }` minimal projection.
- **Binding:** one-way; `open(id)` emitted upward.

## Vanilla-JS skeleton
```js
function CoverTile({ image, title, id, onIntent }) {
  // reserve aspect-ratio box (no layout shift); cover + caption; tap/click => open
}
```

## Accessibility checklist (WCAG 2.1 AA)
Meaningful alt (title) on the cover; focusable, Enter opens; visible focus ring; reserved space prevents shift; ≥44×44px hit area.

## Modality notes
- **Touch:** whole tile is the target (one tap to open).
- **Mouse:** hover lifts/zooms subtly for delight.
- **Keyboard-only:** arrow-key roving within the grid; Enter opens.

## INTENT marker template
```html
<!--@front-end
element: cover-image-tile
philosophy: information-scent
paradigm: dashboard-explorative
intent: make browsing a collection feel comfortable and, at best, delightful
customer: reader
binding: one-way
render-trigger: [record.changed]
modality: { touch: 1-tap, mouse: full, keyboard: roving+enter }
density: spacious
style: operation
a11y: wcag-2.1-aa
improve?: "explore subtle hover lift and staggered load reveal for delight without jank"
breadcrumbs: [reserve aspect-ratio box to prevent layout shift]
-->
```

## Book-example
The reader's library is a wall of cover tiles; arrow keys rove, Enter opens, hover gives a gentle lift — browsing as pleasure.
