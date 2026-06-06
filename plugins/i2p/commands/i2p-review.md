---
description: Cross-plugin adversarial review — fan out EVERY installed specialist reviewer (code, design, rendered docs, security) and synthesise ONE verdict (PASS / NEEDS_REVISION / BLOCK) in I2P_REVIEW.md, naming what could not be reviewed.
---

Run the marketplace-wide adversarial review. Follow the [`review` skill](../skills/review/SKILL.md):

1. **Scope** `$ARGUMENTS` — a PR number, a `base..head` range, a running URL, a path, or (empty) the
   current branch vs its merge-base with main. Decide which lenses are in scope (code / UI / rendered
   docs / security).
2. **Fan out, by capability** — delegate to the specialist plugins that are installed; never
   re-implement their logic:
   - code → foundry **`/pr-review`**
   - UI (a running SPA or screenshot) → atelier **`/ui-review`**
   - rendered docs / figures → pressroom **`/pressroom:design-review`**
   - security → sentinel **`/security-gate`**
3. **Adversarially verify** each HIGH/CRITICAL finding (a second pass tries to refute it).
4. **Synthesise one verdict** with the marketplace rule (BLOCK > NEEDS_REVISION > PASS; verdict = highest
   *unresolved* severity across all lenses) and write **`I2P_REVIEW.md`**.
5. Present the verdict, the findings table, and **explicitly what was NOT reviewed** — including any lens
   whose plugin is not installed (a gap, never a silent PASS).

This command **reports**; it does not merge. All reviewers carry the SOLID self-improvement covenant.
