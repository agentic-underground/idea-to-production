# Feedback Marker

## Description
An embedded "how can we improve this?" hook — both a subtle in-UI affordance for the end-customer and a code-level `improve?` marker for future agents. The instrument of the Human-in-the-Loop *second-way* optimisation.

## When to use
Anywhere worth improving — which is everywhere. Pairs the customer-facing feedback channel with the agent-facing marker so optimisation can be data-driven.

## Anti-patterns
Nagging modals; feedback with no follow-through; collecting customer data that violates the privacy stance (keep it local/opt-in).

## Data contract
- **Customer-facing:** optional lightweight signal (e.g. 👍/👎 + free note), stored per the privacy policy (local-first; opt-in to share).
- **Agent-facing:** the `improve?` field in the `@front-end` marker.

## Vanilla-JS skeleton
```js
function FeedbackMarker({ context, onIntent }) {
  // unobtrusive affordance; emits {type:'feedback', context, signal, note?}
  // never blocks the task; respects privacy (local unless customer opts to share)
}
```

## Accessibility checklist (WCAG 2.1 AA)
Affordance labelled and keyboard-operable; never a focus trap; not auto-popping in a way that disrupts.

## Modality notes
Consistent, small, reachable in all three modalities; never the primary focus of a screen.

## INTENT marker template
```html
<!--@front-end
element: feedback-marker
philosophy: human-in-the-loop
paradigm: dashboard-explorative
intent: capture improvement signal from both the customer and future agents
customer: "both: developer + end-customer"
binding: one-way
render-trigger: [n/a]
modality: { touch: full, mouse: full, keyboard: full }
density: moderate
style: operation
a11y: wcag-2.1-aa
improve?: "close the loop: route signal into design-critic scoring; keep all of it privacy-safe"
breadcrumbs: [feedback is local-first and opt-in to share; never block the task]
-->
```

## Book-example
On the reader's browse grid, a quiet 👍/👎 lets readers shape the experience; in the code, every tile carries an `improve?` note for the next agent — together they drive the delight roadmap.
