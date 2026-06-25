---
description: Adversarially review the design of any running SPA or screenshot — crawl the navigable routes (screenshot + accessibility snapshot per route), critique each against named design canon (Gestalt, UX laws, Nielsen's heuristics, WCAG 2.2), score it on the design-fitness rubric, and write a prioritised report. Asks which surfaces to review when ambiguous.
---

Review a UI with DESIGN. Follow the [`ui-review` skill](../skills/ui-review/SKILL.md):

1. **Recover intent + scope.** What is the app for, and for whom (read deliver `@front-end` markers by
   capability if present)? Find the dev-server URL. **If which routes / graphical elements to review is
   ambiguous, ask the user** (default: all top-level nav routes + their primary states).
2. **Crawl** via the chrome-devtools MCP (`mcp__chrome-devtools__*`) — screenshot (desktop + mobile) and read the
   **accessibility tree** per route; run `axe-core` when available. Or critique a **pasted screenshot**
   ad-hoc. Committed-snapshot fallback: `BASE_URL=… node ${CLAUDE_PLUGIN_ROOT}/skills/ui-review/scripts/crawl.mjs`.
3. **Critique** each surface against the canon (visual-foundations → interaction-laws → accessibility),
   every finding naming its principle + fix + rubric dimension; **score** the design-fitness rubric.
4. **Write** `docs/guide/design/review/<date>/design-review.md` — executive summary (score + a11y gate + systemic
   themes + biggest quick win) and per-surface prioritised findings.

Suggestions are proposals — the user approves what to apply, then the **convergent loop** verifies the
score rises. Verify tools with `/design:check`.
