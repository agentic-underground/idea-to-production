---
id: 111
title: "publish: surface a prose/document reviewer (copy-review)"
status: COMPLETE
priority: MEDIUM
added: 2026-06-17
completed: 2026-06-18
depends_on: "#96 (pressroom→publish rename)"
---

# [111] publish: surface a prose/document reviewer (copy-review)

**Brief Description**
PRESSROOM (→ `publish` in #96) ships a surfaced VISUAL design gate — the `design-reviewer` skill
(`/publish:design-review`) with four lenses (layout, typography, dataviz, image-aesthetic) — but **no
surfaced prose/document reviewer**. A capable prose reviewer already exists; it is just **buried** inside
the WRITER skill at `plugins/pressroom/skills/writer/agents/reviewer.md` (an adversarial line-editor
critiquing clarity, accuracy/precision, tone/vocabulary, punchiness, tangents). It only runs while
*authoring an article via WRITER* — there is no way to point a prose review at an arbitrary document.
Separately, `foundry`'s reviewer carries a general `DOCUMENT-REVIEWER` role
(`plugins/foundry/agents/reviewer.md`, ~line 594) for general-purpose document critique. The result: a
user who wants a prose review of any doc (a spec, a gap map, a README, a completion report) has **no
`/publish:*` entry point** — the words have no gate parallel to the page.

This item adds a `/publish:document-review` (a.k.a. copy-review) skill: the prose peer to
`design-reviewer`. It promotes WRITER's buried reviewer into a composable reviewer and/or composes
foundry's `DOCUMENT-REVIEWER`, reusable on **any** document — not only when authoring an article.

### The case — surface it vs leave it buried
- **Asymmetry.** The marketplace already states the split explicitly: `design-reviewer`'s own
  description says *"Complements WRITER's prose reviewer (which owns the words); this owns the page and
  the figure."* But only one half of that pair is invocable. The page has a slash command; the words do
  not. Surfacing the prose reviewer closes a stated, asymmetric gap.
- **Reach.** Buried in WRITER, the prose reviewer fires only on the article-authoring path. A spec, a
  gap map, a README, or a completion report — the documents `foundry` produces all day — get no prose
  gate from `publish`. The reviewing *capability* exists; only the *door* is missing.
- **Single source of truth (anti-`muda`).** Two prose-critique bodies already exist (WRITER's reviewer,
  foundry's `DOCUMENT-REVIEWER`). Surfacing one composable reviewer that both the WRITER loop and a
  standalone `/publish:document-review` invocation share — rather than authoring a third — eliminates
  the rediscovery waste rather than adding to it.
- **Scope boundary (anti-overlap).** The prose reviewer must NOT re-review what `design-reviewer`
  already owns. It judges the *words* (clarity, accuracy, tone, structure, cohesion); the page and the
  figure stay with `design-reviewer`. The two compose; they do not duplicate.

### User Stories
- AS the owner I WANT to run one command and get an adversarial prose critique of ANY document SO THAT a
  spec, README, gap map, or completion report gets the same kind of gate my charts and PDFs already get.
- AS a WRITER user I WANT the prose review I get during authoring to be the SAME reviewer I can invoke
  standalone SO THAT there is one prose-quality bar, not two that drift.
- AS a builder I WANT the prose reviewer to stay in its lane (words, not pixels) SO THAT it complements
  `design-reviewer` instead of re-reviewing layout and typography.

### EARS Specification
**Ubiquitous**
- The `publish` plugin SHALL expose an invocable prose/document reviewer (working name
  `/publish:document-review`, a.k.a. copy-review) as a first-class skill, parallel to
  `design-reviewer`.
- The reviewer SHALL be reusable on ANY document supplied to it (spec, gap map, README, completion
  report, article draft), not only on a draft authored in-session via WRITER.
- The reviewer SHALL draw on ONE composable prose-critique body shared with WRITER's authoring loop
  (promoting `skills/writer/agents/reviewer.md`) and/or compose foundry's `DOCUMENT-REVIEWER` role —
  never a freshly forked third copy of the same critique logic.

**Event-driven**
- WHEN invoked against a document THE SYSTEM SHALL return an adversarial prose critique (clarity,
  accuracy/precision, tone/vocabulary, punchiness/structure, tangents/cohesion) AND a single explicit
  verdict (MAJOR / MINOR / APPROVED, or equivalently PASS / NEEDS_REVISION / BLOCK).
- WHEN invoked it SHALL emit prioritised, evidence-citing findings (quote-and-locate the offending
  prose), in the adversarial-grounded style the WRITER reviewer already uses.

**Unwanted behaviour**
- IF the document is a rendered artefact whose concern is visual (PDF page layout, chart, figure) THEN
  THE SYSTEM SHALL defer that scope to `design-reviewer` and SHALL NOT re-review typography, layout, or
  data-viz — the prose reviewer judges the WORDS only and SHALL NOT duplicate `design-reviewer`'s visual
  scope.
- IF no document is supplied or the input is unreadable THEN THE SYSTEM SHALL exit with a clear message
  and produce no critique, never a vacuous "APPROVED".

### Acceptance Criteria
1. Given any document (e.g. a spec or README), When `/publish:document-review` is invoked on it, Then
   the user receives a prioritised, evidence-citing prose critique plus exactly one verdict
   (MAJOR/MINOR/APPROVED or PASS/NEEDS_REVISION/BLOCK).
2. Given the WRITER authoring loop, When its prose review runs, Then it invokes the SAME composable
   reviewer body the standalone command uses (verified: one source file, referenced from both), so the
   two cannot drift.
3. Given a rendered PDF or a chart, When passed to the prose reviewer, Then it reviews only the words it
   can read and explicitly defers visual concerns to `design-reviewer` — producing no typography/layout
   findings of its own.
4. Given no input, When invoked, Then it errors clearly and writes no critique.
5. The new skill is listed in the `publish` README component list and reachable via `/publish`, parallel
   to `design-reviewer`.

### Implementation Notes
- Land AFTER #96 so the surface is named `/publish:document-review` from the start (avoid a
  `/pressroom:*` → `/publish:*` rename churn).
- Prefer **promote-and-share** over copy: lift `plugins/pressroom/skills/writer/agents/reviewer.md` into
  a composable reviewer that both WRITER and the new skill reference (the same pattern `design-reviewer`
  uses with its lens agents). Optionally compose foundry's `DOCUMENT-REVIEWER`
  (`plugins/foundry/agents/reviewer.md`, ~line 594) by capability when `foundry` is present, so the
  general-document fallback is reused rather than re-implemented.
- Mirror `design-reviewer`'s shape: an invocable skill, a named-dimension rubric, an explicit terminating
  verdict, and the adversarial-grounded stance ("assume it fails the reader until each lens fails to
  break it").
- Make the complementarity explicit in BOTH skills' prose: `design-reviewer` already says it owns "the
  page and the figure"; the new prose reviewer states it owns "the words", and each points at the other.
- Update the `publish` README component list + `/publish` front-door deferral text to name the prose
  reviewer alongside `design-reviewer`.
- Reuse the existing convergent-loop framing where it authors (WRITER), but the standalone path is a
  single critique pass returning a verdict — it need not drive the full designer↔reviewer loop.
