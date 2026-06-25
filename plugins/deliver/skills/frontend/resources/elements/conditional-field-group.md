# Conditional Field Group

## Description
A set of fields that **appears, hides, or changes** based on the value of a controlling field. Keeps screens cognitively light by showing only what's relevant now.

## When to use
Branching data shapes (e.g. book action = *sell* reveals price + availability; = *lend* reveals lend-duration). Reduces per-screen cognitive load.

## Anti-patterns
Hiding fields that carry committed data without warning; layout jump that disorients; deeply nested conditions that hide the model from the customer.

## Data contract
- **Controller:** one field's value selects which group renders.
- **Binding:** one-way; group renders as a pure function of controller value; hidden-field values handled explicitly (retain vs clear — declare which in a breadcrumb).
- **Validation:** only validate visible, relevant fields; never block on a hidden requirement.

## Vanilla-JS skeleton
```js
function ConditionalFieldGroup({ controller, value, onIntent }) {
  // pick group from controller; render its fields; emit field intents upward
  // declare retain-vs-clear policy for fields that leave view
}
```

## Accessibility checklist (WCAG 2.1 AA)
Reveal is announced (`aria-live`); focus moves predictably into newly revealed group; no focus trap; reduced-motion respected on transitions.

## Modality notes
- **Touch:** avoid large reflows that push targets under the thumb mid-tap.
- **Mouse:** smooth reveal; keep controller in view.
- **Keyboard-only:** after toggle, focus lands at the start of the revealed group.

## INTENT marker template
```html
<!--@front-end
element: conditional-field-group
philosophy: progressive-disclosure
paradigm: form-as-conversation
intent: show only the fields relevant to the customer's current choice, lowering per-screen load
customer: <...>
binding: one-way
render-trigger: [controller.changed]
modality: { touch: full, mouse: full, keyboard: full }
density: moderate
style: words
a11y: wcag-2.1-aa
improve?: "test whether retaining hidden values surprises customers; consider explicit clear"
breadcrumbs: [declare retain-vs-clear policy for fields leaving view; validate only visible fields]
-->
```

## Book-example
Setting a book's action to *sell* reveals **price** and **availability**; switching to *read* hides them and reveals **reading-progress**.
