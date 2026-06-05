# idea-to-production — a Claude Code plugin marketplace

> Carry software from **the spark of an IDEA to PRODUCTION** — discover what's worth building, refine it
> to a build-ready package, build it test-first, with security and publishing that switch on when you need them.

## What governs everything — the three pillars

A disciplined, test-first conveyor that carries **VALUE** from **IDEA** to **PRODUCTION**, governed by
**three pillars** under one overarching constraint:

| Pillar | also called | in one line |
|---|---|---|
| 🧭 **Knowledge-parity** | knowledge-alignment | understand the ask **completely before acting** — recurring questions become written answers, asked once. |
| 🛡️ **Quality-first** | quality-confidence | quality is **built in, not inspected in** — every station, strengthened by a performance-delta gate; a gate is never weakened to make progress. |
| ♻️ **Waste-elimination** | — | remove waste in every form, *including rediscovery* — a bug caught in development is far cheaper than one in production. |

> **Overarching constraint — token-efficiency:** *thin skills, fat references; define once, reference
> many; load only what a station needs.* And the marketplace is **self-improving**: when an element
> learns from a mistake, it folds the fix back into itself — *self-cleaving* into smaller, sharper
> parts where needed — and **raises a PR so every user inherits the improvement**.

The philosophy is the [first-principles spine](plugins/foundry/knowledge/first-principles.md); the
operation is [VALUE_FLOW](plugins/foundry/VALUE_FLOW.md).

---

This marketplace ships six composable plugins spanning the whole arc — **DISCOVER → IDEATE → BUILD →
SECURE / PUBLISH**, with **DESIGN** cross-cutting throughout. Install **foundry** for the core production
discipline; add **market-scanner** and **ideator** to put a discovery-and-refinement front end *upstream*
of the build; add **atelier** to make and adversarially review the visuals; add **sentinel** and
**pressroom** to light up security gates and publication-grade output. Every plugin stands alone, and
each lights up the others automatically when present (*graceful enhancement*) — no hard dependency in
any direction.

## The plugins

| Plugin | What it does | Install when you want… |
|--------|--------------|------------------------|
| **[market-scanner](plugins/market-scanner/)** | The DISCOVERY front door: set a standing `/goal`, then `/market-scan` — an adversarially-challenged dialogue over a market parameter taxonomy (demand, willingness-to-pay, pricing power, competition, reachability, stack-fit) that proposes, scores, validates, and **kills weak ideas early**, until one candidate earns a keep verdict. | To find *what's worth building* before writing any code. |
| **[ideator](plugins/ideator/)** | The REFINEMENT phase: turns a validated opportunity (or a raw idea) into the **IDEA package** — precise agent-facing handoff docs (brief + SMU-seed + first slice + handoff contract) plus a rich, illustrated user-facing dossier — refined to knowledge-parity, then handed to foundry. | To turn a spark into a build-ready, unambiguous package. |
| **[foundry](plugins/foundry/)** | The value conveyor: IDEA ▶ ROADMAP ▶ PLAN ▶ EARS ▶ FEATURE ▶ TEST ▶ IMPLEMENT ▶ STORY ▶ SHIP, staffed by role-tuned agents and governed by three pillars (knowledge parity, quality-first + perf-delta gate, waste elimination). | A disciplined, test-first, vertical-slice production system. |
| **[sentinel](plugins/sentinel/)** | A pre-release security gate: PII, secrets/credentials, and dependency/supply-chain audits → one severity-ranked report with a PASS / REVIEW / BLOCK verdict. | To never ship a leaked key, a real person's data, or a vulnerable dependency. |
| **[pressroom](plugins/pressroom/)** | Publishing: narrative articles mined from git history & docs, standalone diagrams (Graphviz/Mermaid), and print-quality PDFs with A4-legible figures. | Documentation and release artefacts that look professionally published. |
| **[atelier](plugins/atelier/)** | The DESIGN studio: `/ui-review` crawls any SPA's routes (screenshot + accessibility snapshot) and writes a **scored, prioritised** critique citing named canon (Gestalt, the UX laws, Nielsen's heuristics, WCAG 2.2); `/mockup` composes polished screens and flows and runs a **convergent** designer↔reviewer loop until they clear a design-fitness rubric. | Visual work — UIs, mockups, user-flows — that is *artistic, elegant, and accessible*, not first-draft. |

## How they compose

```
   "let's come up with a new idea"
        │
   DISCOVER ──▶ IDEATE ───────▶ BUILD ──────────────────────────────▶ SECURE / PUBLISH
   market-scanner  ideator      foundry (core, emits markdown)         sentinel · pressroom
        │            │             │
   /goal +      IDEA package   IDEA ▶ ROADMAP ▶ … ▶ STORY ▶ SHIP
   /market-scan (2 faces:          │  SECURITY  ── if sentinel installed ─▶ SECURITY-REPORT.md
   → a kept     agent-facing +     │  PUBLISHING ── if pressroom installed ─▶ articles / PDFs
   OPPORTUNITY  user-facing)       │
        ▲                          ▼
        └──── ideation-feedback ◀── a downstream ambiguity sharpens the front end (self-improve → PR)

   DESIGN (atelier) ── cross-cutting ──▶ /ui-review critiques any rendered SPA · /mockup makes polished
        screens & flows · the convergent designer↔reviewer loop raises both to a design-fitness rubric;
        IDEATOR calls it so user-flows & mockups are design-reviewed, not first-draft.
```

No plugin *requires* another. When the `ideator` plugin is installed, foundry's IDEA station **receives
the IDEA package by capability** (the inline `ideator` skill is the graceful fallback when it is absent);
when `sentinel` is installed, foundry's SECURITY station runs the gate before delivery; when `pressroom`
is installed, the PUBLISHING station upgrades markdown into articles, diagrams, and PDFs; when `atelier`
is installed, user-flows and mockups are **design-reviewed by capability** before anyone sees them, and
any SPA can be put under `/ui-review`. Absent any companion, each stage degrades cleanly and notes that
the richer step was skipped. And the loop closes: an ambiguity a builder hits downstream flows back as
**ideation-feedback** that sharpens market-scanner / ideator for every future idea.

## Install

Add the marketplace, then install whichever plugins you want:

```
/plugin marketplace add whatbirdisthat/idea-to-production
/plugin install market-scanner@idea-to-production
/plugin install ideator@idea-to-production
/plugin install foundry@idea-to-production
/plugin install sentinel@idea-to-production
/plugin install pressroom@idea-to-production
/plugin install atelier@idea-to-production
```

Each plugin works on its own — `market-scanner` and `ideator` need no build system to help you find and
shape an idea, and `sentinel` and `pressroom` are useful on any repository, not just foundry projects.

## Concepts & glossary

New here? [`plugins/foundry/knowledge/glossary.md`](plugins/foundry/knowledge/glossary.md) names every
concept, plugin, agent, skill, and command, draws the conceptual-domain tree, and settles the
**foundry vs forge vs founder** question. The system itself is described in
[`plugins/foundry/VALUE_FLOW.md`](plugins/foundry/VALUE_FLOW.md).

## License

Dual-licensed under **MIT OR Apache-2.0**. See [LICENSE](LICENSE).
