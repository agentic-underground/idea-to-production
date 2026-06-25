# Three-Tap Action Menu

## Description
A menu structured so that **any record action is reachable within three taps** on touch — the human-centric ceiling for tapping — while collapsing to hover/click on mouse and a single keystroke chord on keyboard.

## When to use
Records with several actions (book: buy, rent, read, sell, lend, write) where surfacing all of them inline would overwhelm.

## Anti-patterns
Burying common actions below the three-tap line; identical depth for rare and frequent actions; menus that demand precise small targets on touch.

## Data contract
- **Value:** a list of `{ action, label, enabled }`.
- **Binding:** one-way; chosen action emits `intent`.

## Vanilla-JS skeleton
```js
function ActionMenu({ actions, onIntent }) {
  // trigger -> menu; promote frequent actions to depth-1; action => onIntent
}
```

## Accessibility checklist (WCAG 2.1 AA)
`role="menu"`/`menuitem`; focus trapped while open, restored on close; Esc closes; ≥44×44px items; visible focus.

## Modality notes
- **Touch:** tap trigger → tap action (2 taps for common, ≤3 for nested). Respect the ceiling.
- **Mouse:** click or hover-open; common actions also inline.
- **Keyboard-only:** trigger focus + Enter, arrow to item, Enter to fire; optional shortcut chords for power users.

## INTENT marker template
```html
<!--@front-end
element: three-tap-action-menu
philosophy: information-scent
paradigm: form-as-document
intent: keep every record action reachable without exceeding the touch three-tap ceiling
customer: <...>
binding: one-way
render-trigger: [actions.changed]
modality: { touch: 3-tap-ceiling, mouse: full, keyboard: full }
density: moderate
style: mixed
a11y: wcag-2.1-aa
improve?: "instrument which actions are used; promote frequent ones to depth-1"
breadcrumbs: [frequency should drive depth; never bury common actions]
-->
```

## Book-example
On a book, *read* and *buy* sit at depth-1 (two taps); *sell* and *lend* live one level deeper — still within three taps.
