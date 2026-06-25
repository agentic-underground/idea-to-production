---
description: Adversarially review the PROSE of any document (copy-review) — clarity, accuracy, tone, punchiness, tangents — and return prioritised, evidence-citing findings plus one verdict. The prose peer to design-review (it owns the WORDS; design-review owns the PAGE). Invocable on a spec, README, gap map, or completion report — not only an article.
---

Run PUBLISH's prose quality gate over a document, following the
[`document-review` skill](../skills/document-review/SKILL.md).

Parse `$ARGUMENTS` for the **document** to review:
- a **file path** (a spec, README, gap map, completion report, article draft) — read and review it;
- **`this`** or empty — review the document currently in context (the one just discussed or open);
- a **pasted body** of text — review it as supplied.

**If nothing readable is supplied, stop with a clear message and produce no critique** — never a vacuous
"APPROVED".

Then:

1. **Recover intent** — what is this document *for*, and for whom? Review against the right bar and register
   (a spec, a README, and a completion report differ). When `deliver` is installed and the document is a
   typed pipeline artefact, **compose** its `DOCUMENT-REVIEWER` role by capability for the stage-aware
   completeness checklist.
2. **Load the reviewer persona** — read [`../skills/writer/agents/reviewer.md`](../skills/writer/agents/reviewer.md)
   and follow it exactly. This is the **same** adversarial prose reviewer WRITER's authoring loop uses — one
   prose bar, two doors — so the standalone review and the authoring review cannot drift.
3. **Critique through the five lenses** — clarity · accuracy/precision · tone/vocabulary · punchiness/
   structure · tangents/cohesion. Every finding **quotes the offending prose and locates it** (file +
   section/line), names the reader cost, and gives the concrete fix.
4. **Stay in your lane (HARD constraint).** This reviewer owns the **WORDS**; `design-review` owns the
   **PAGE and the FIGURE**. Do **not** review typography, layout, or data-viz. If handed a rendered artefact
   (a PDF page, a chart), review only the words you can read and **explicitly defer** the visual concerns to
   the [`design-reviewer` skill](../skills/design-reviewer/SKILL.md).
5. **Issue exactly one verdict** — `MAJOR CHANGES NEEDED` ≡ **BLOCK**, `MINOR CHANGES NEEDED` ≡
   **NEEDS_REVISION**, or `APPROVED WITH NOTES` ≡ **PASS** — with prioritised findings ordered
   most-critical-first.

Report the verdict, the prioritised evidence-citing findings, and the single highest-leverage improvement
that would take the document from correct to memorable.

> **Parallel to `/publish:design-review`.** The page has a gate; now the words do too. `design-review` owns
> the page and the figure; this owns the words. The two compose — they do not duplicate.
