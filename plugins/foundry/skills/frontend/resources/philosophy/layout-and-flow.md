# Layout, Balance & Flow

## Page balance
Establish a clear visual hierarchy: one focal point per screen/panel, deliberate reading order, effective whitespace. Group related fields; separate unrelated ones. Keep card/tile rhythm uniform in grids.

## Single vs. multi-column
- Single-column: linear, mobile-friendly, lowest cognitive load — default for form-as-conversation and phones.
- Multi-column: scannable, denser — for form-as-document on large screens. Keep a logical tab order across columns (don't make keyboard users zig-zag confusingly).

## Input flow (words-style)
Type-tab-type-tab must feel effortless: logical tab order, sensible default focus, required fields prominent, validation inline without stealing focus. Group into ≤~5-field chunks (see `density-and-cognitive-load.md`).

## Keyboard optimisation
- Tab/Shift-Tab follow visual order.
- Arrow-key roving in grids, listboxes, menus.
- Enter commits, Esc cancels/closes — consistently, everywhere.
- Offer shortcut chords for power-user repetitive toil (and document them).

## Flow optimisation for repetitive toil
Where the customer does the same thing many times, shorten the path: smart defaults, keyboard-only completion, batch actions, and "stay in flow" patterns (inline edit over modal). Instrument it (Feedback Marker) and let the design-critic flag friction.

## Output/display flow
Prefer scroll with lazy-load for browse; reserve aspect-ratio boxes to prevent layout shift; fix headers where scanning long lists. Large datasets/canvases → `../ROADMAP.md`.
