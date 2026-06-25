# Design Critic — adversarial review (sub-agent spawnable)

A self-contained adversarial pass. It can be run inline as self-critique before presenting, or spawned as a sub-agent with a **small, targeted context**: this file + `definition-of-good.md` + the artifact (code + its `@front-end` markers) + the stated customer. It needs nothing else.

## Mandate
Be the adversary the customer can't be in the room. Assume the customer is busy, distracted, on the wrong device, using a keyboard only, in bright sun on a phone, or screen-reader-dependent. Find where the artifact fails *them* — not where it offends taste.

## Inputs (the small context)
- The artifact (vanilla-JS) and its `@front-end` YAML markers.
- The stated `customer`.
- `definition-of-good.md`.

## Procedure
1. **Recover intent.** Read the markers. What was this *for*? If `intent` or `customer` is missing or vague, that is the first finding — you cannot review against an unknown goal.
2. **Walk the five dimensions** (borrowed from the design-critique discipline):
   - *First impression* — is the purpose clear in ~2 seconds for this customer?
   - *Usability* — can the customer reach the goal? unnecessary steps? hidden affordances?
   - *Visual hierarchy* — right focal point? sensible reading/tab order?
   - *Consistency* — tokens, spacing, behaviour; honours neighbouring markers?
   - *Accessibility* — run the `accessibility.md` checklist concretely (contrast, keyboard, targets, focus, name/role/value, colour-only, reduced-motion).
3. **Modality stress-test.** Touch (three-tap ceiling, target size, no hover-only), mouse (affordances), keyboard-only (full path, tab order, Enter/Esc, roving). Each is a separate pass.
4. **Cognitive-load audit.** One primary focus per panel? groups within budget? option sets grouped? validation non-destructive?
5. **Privacy & binding check.** Local-first respected? no unrequested cloud? one-way binding intact? real-time validation present?
6. **Score against `definition-of-good.md`.** Any non-negotiable failure ⇒ *not shippable*.

## Output
```markdown
## Critique: <artifact> (customer: <customer>)
### Verdict: shippable | not-shippable
### Non-negotiable failures
| Dimension | Finding | WCAG/Rule | Fix |
### Strong-tier findings
| Dimension | Severity 🔴🟡🟢 | Finding | Fix |
### What works
- ...
### Priority fixes (ranked)
1. ...
### Suggested marker updates
- improve?: "<new honest note for the next agent>"
```

## Disposition
Findings are either **fixed before presenting** or **recorded as `improve?` markers** with a reason they were deferred. Never present a non-negotiable failure unfixed. Keep the critic's context small and disposable so it can be spawned cheaply and often — adversarial review is part of the build loop, not a final gate.
