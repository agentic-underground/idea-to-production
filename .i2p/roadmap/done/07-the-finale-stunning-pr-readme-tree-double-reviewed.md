---
id: 7
title: "The finale — stunning PR, README tree, double-reviewed screenshots"
status: COMPLETE
priority: MEDIUM
added: 2026-06-13
depends_on: "#1, #2, #3, #4, #5, #6, #8"
---

# [7] The finale — stunning PR, README tree, double-reviewed screenshots

**Brief Description**
Once the roadmap is empty, the `flow-tracking-ui` branch becomes the source of the issue/PR: a rich markdown
document that *sells* the PR — complete with stunning, 4×-adversarially-reviewed SVG diagrams, a detailed PR
message, and a carefully planned README tree linked back to (and traversable from) the root README, which
gains awesome, double-reviewed screenshots of the UI. If the screenshots are not excellent, we are not at MVP.

### User Stories
- AS the maintainer I WANT the PR to read as a compelling, illustrated case SO THAT the work's value is
  unmistakable.
- AS a future reader I WANT a README tree linked from the root README SO THAT I can navigate into and out of
  the feature's docs.
- AS the maintainer I WANT double-reviewed screenshots SO THAT the UI quality is proven, not asserted.

### EARS Specification
**Event-driven**
- WHEN the roadmap reaches zero open tickets THE SYSTEM (operator) SHALL raise an issue/PR from
  `flow-tracking-ui` with the rich markdown, the reviewed diagrams, and the README tree.
**Unwanted behaviour**
- IF any shipped SVG diagram or screenshot fails its adversarial review THEN it SHALL NOT be considered MVP
  and SHALL be re-drafted until it passes.

### Acceptance Criteria
1. Given the roadmap is empty, Then a PR exists from `flow-tracking-ui` with a selling markdown body, the
   reviewed diagrams, and a README tree linked from the root README.
2. Given the diagrams, Then each has survived 4 adversarial design reviews (draft# ≥ 4 recorded).
3. Given the screenshots, Then each has passed two ATELIER ui-design-reviewer passes.

### Implementation Notes
- Diagrams via PRESSROOM illustrator (dark-mode, transparent, A/B-until-best); screenshots via ATELIER
  ui-review on the running UI; root-README screenshots embedded and link-checked by `scripts/verify-prereqs.sh`.

### Human Interface Test Plan
- [Root README → feature README]: from the root README, follow the flow-tracking-ui link → verify it reaches
  the feature README tree → verify a link back to the root README resolves.

### Development Plan Reference
`doc/FLOW_TRACKING_FINALE_PLAN.md`
