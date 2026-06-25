# Element Registry

This directory holds one markdown page per UI element. The `-help` command renders this list, grouped by **purpose**, each element tagged with **style** (words / operation), **modality** support, and default **density**.

## How to render `-help`

Emit the grouping below. For each element, show: name · one-line purpose · style · modalities · file. Keep it scannable. When new element pages are added here, add them to the correct group so `-help` stays current.

---

## Capture — get data in
| Element | Purpose | Style | Modalities | Page |
|---|---|---|---|---|
| Multi-Select Lookup | Pick many referenced records (tags) without free text | words | touch·mouse·kbd | `multi-select-lookup.md` |
| Single Lookup | Pick one referenced record from a constrained list | words | touch·mouse·kbd | `single-lookup.md` |
| Inline Text Edit | Click/focus to edit a value in place, blur/Enter to save | words | touch·mouse·kbd | `inline-text-edit.md` |
| Conditional Field Group | Show/hide fields based on another field's value | words | touch·mouse·kbd | `conditional-field-group.md` |

## Display — show data out
| Element | Purpose | Style | Modalities | Page |
|---|---|---|---|---|
| Data Card | Compact record summary (e.g. a book: cover, title, author, year) | mixed | touch·mouse·kbd | `data-card.md` |
| Pill / Tag / Badge | Render a referenced or categorical value as a token | operation | touch·mouse·kbd | `pill-tag-badge.md` |
| Gauge / Progress | Show a bounded quantity at a glance | operation | mouse·kbd | `gauge-progress.md` |
| Cover-Image Tile | Image-forward browse unit for a grid | operation | touch·mouse·kbd | `cover-image-tile.md` |

## Navigate — move through data
| Element | Purpose | Style | Modalities | Page |
|---|---|---|---|---|
| Three-Tap Action Menu | Reach any record action within the touch three-tap ceiling | mixed | touch·mouse·kbd | `three-tap-action-menu.md` |
| Browse Grid | Comfortable/delightful exploration of a collection | operation | touch·mouse·kbd | `browse-grid.md` |

## Instrument — measure & feed back
| Element | Purpose | Style | Modalities | Page |
|---|---|---|---|---|
| Readout / Stat | Single salient number with label and trend | operation | mouse·kbd | `readout-stat.md` |
| Feedback Marker | "How can we improve this?" hook for HIL optimization | operation | touch·mouse·kbd | `feedback-marker.md` |

---

Each page follows a shared anatomy: **Description · When to use · Anti-patterns · Data contract · Vanilla-JS skeleton · Accessibility checklist · Modality notes (touch/mouse/keyboard) · INTENT marker template · Book-example.**
