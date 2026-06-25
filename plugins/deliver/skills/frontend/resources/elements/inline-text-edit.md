# Inline Text Edit

## Description
Edit a value **in place** — click or focus turns display text into an input; blur or Enter commits, Esc cancels. Reduces context-switching and modal fatigue.

## When to use
Light, low-risk edits to a single text/number value where opening a separate form would be overkill (e.g. a book's title in a list).

## Anti-patterns
Inline-editing high-risk or multi-field data; silent commit with no confirmation affordance; losing the value on accidental blur without a recoverable state.

## Data contract
- **Value:** `string | number`.
- **Binding:** one-way; `commit(next)` / `cancel()` emitted upward; re-render on `value.changed`.
- **Validation:** real-time; show the error adjacent, keep focus, never destroy the in-progress value.

## Vanilla-JS skeleton
```js
function InlineTextEdit({ value, onIntent }) {
  // display mode: text + edit affordance; focus/click => edit mode (input)
  // Enter/blur => onIntent({type:'commit', value:next}); Esc => onIntent({type:'cancel'})
}
```

## Accessibility checklist (WCAG 2.1 AA)
Edit affordance is a real control with a name; mode change is predictable (no surprise navigation); error has text, not just colour; keyboard-operable; visible focus.

## Modality notes
- **Touch:** tap to edit; large commit/cancel affordances; avoid relying on blur alone.
- **Mouse:** hover reveals edit affordance; click to edit.
- **Keyboard-only:** focus + Enter to edit, Enter to commit, Esc to cancel.

## INTENT marker template
```html
<!--@front-end
element: inline-text-edit
philosophy: progressive-disclosure
paradigm: form-as-document
intent: let the customer fix a single value in place without a modal or page change
customer: <...>
binding: one-way
render-trigger: [value.changed]
modality: { touch: 2-tap, mouse: full, keyboard: full }
density: moderate
style: words
a11y: wcag-2.1-aa
improve?: "explore optimistic commit with undo toast vs confirm-on-blur"
breadcrumbs: [never discard in-progress text on accidental blur]
-->
```

## Book-example
In a seller's title list, click a book's title to correct a typo; Enter saves, the list re-renders from the new value.
