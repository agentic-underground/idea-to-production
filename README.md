![idea-to-production masthead: the wordmark "idea → production" above the nine-plugin value cycle igniting beneath it — eight phase nodes (DISCOVER · IDEATE · DESIGN · BUILD · ASSURE · SECURE · PUBLISH · OPERATE), each labelled with its owning plugin (scanner, ideator, atelier, foundry, foundry, sentinel, pressroom, mission), light teal left-to-right in a build-up with the current phase pulsing amber; then the dashed return loop-arc glows teal as OPERATE's learnings re-enter DISCOVER and the loop closes, framed by the i2p front door and concierge greeter, settling on the complete cycle.](doc/images/masthead-cycle.gif)

# idea-to-production — a Claude Code plugin marketplace

> Carry software from **the spark of an IDEA to PRODUCTION** — discover what's worth building, refine it
> to a build-ready package, build it test-first, with security and publishing that switch on when you need them.

> **Start here →** install the suite, then run **`/i2p-help`** to browse every power you have, **`/i2p-flow`**
> to see the pipeline, and **`/i2p-review`** for one verdict from every reviewer. The **i2p** plugin is
> the marketplace front door; the **concierge** plugin greets whoever opens the repo.

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

This marketplace ships nine composable plugins — the **i2p** front door and the **concierge** greeter,
plus seven specialists spanning the whole arc — **DISCOVER → IDEATE → DESIGN → BUILD → ASSURE → SECURE →
PUBLISH → OPERATE ↻** (eight phases forming a cycle; OPERATE's learnings loop back to DISCOVER). **ASSURE**
(quality V&V, foundry) and **SECURE** (security, sentinel) are **separate first-class gates**; three
concerns **cross-cut** every phase — usability (atelier/DESIGN), quality (foundry/ASSURE, built-in not
inspected-in), security (sentinel/SECURE, baked in from the start). Start with **i2p** for `/i2p-help`; install **foundry** for the core production
discipline; add **market-scanner** and **ideator** to put a discovery-and-refinement front end *upstream*
of the build; add **atelier** to make and adversarially review the visuals; add **sentinel** and
**pressroom** to light up security gates and publication-grade output; add **mission-control** to operate
the live product (observe, respond to incidents, iterate, maintain) and loop its learnings back to
discovery; add **concierge** to give any repo a conversational front door that greets and routes whoever
opens it. Every plugin stands alone, and
each lights up the others automatically when present (*graceful enhancement*) — no hard dependency in
any direction.

## The plugins

| Plugin | What it does | Install when you want… |
|--------|--------------|------------------------|
| **[i2p](plugins/i2p/)** | The marketplace FRONT DOOR / meta-layer: `/i2p-help` browses every power you have (grouped by the value flow), `/i2p-review` fans out **every installed reviewer** — code, design, docs, security — into one verdict, `/i2p-check` consolidates readiness, `/i2p-flow` maps the pipeline and your next command. Introduces itself on session start. | A single front door to the whole suite — and one review that pulls in *all* the reviewers at once. |
| **[market-scanner](plugins/market-scanner/)** | The DISCOVERY front door: set a standing `/goal`, then `/market-scan` — an adversarially-challenged dialogue over a market parameter taxonomy (demand, willingness-to-pay, pricing power, competition, reachability, stack-fit) that proposes, scores, validates, and **kills weak ideas early**, until one candidate earns a keep verdict. | To find *what's worth building* before writing any code. |
| **[ideator](plugins/ideator/)** | The REFINEMENT phase: turns a validated opportunity (or a raw idea) into the **IDEA package** — precise agent-facing handoff docs (brief + SMU-seed + first slice + handoff contract) plus a rich, illustrated user-facing dossier — refined to knowledge-parity, then handed to foundry. | To turn a spark into a build-ready, unambiguous package. |
| **[foundry](plugins/foundry/)** | The value conveyor: IDEA ▶ ROADMAP ▶ PLAN ▶ EARS ▶ FEATURE ▶ TEST ▶ IMPLEMENT ▶ STORY ▶ SHIP, staffed by role-tuned agents and governed by three pillars (knowledge parity, quality-first + perf-delta gate, waste elimination). | A disciplined, test-first, vertical-slice production system. |
| **[sentinel](plugins/sentinel/)** | A pre-release security gate: PII, secrets/credentials, and dependency/supply-chain audits → one severity-ranked report with a PASS / REVIEW / BLOCK verdict. | To never ship a leaked key, a real person's data, or a vulnerable dependency. |
| **[pressroom](plugins/pressroom/)** | Publishing: narrative articles mined from git history & docs, standalone diagrams (Graphviz/Mermaid), and print-quality PDFs with A4-legible figures. | Documentation and release artefacts that look professionally published. |
| **[atelier](plugins/atelier/)** | The DESIGN studio: `/ui-review` crawls any SPA's routes (screenshot + accessibility snapshot) and writes a **scored, prioritised** critique citing named canon (Gestalt, the UX laws, Nielsen's heuristics, WCAG 2.2); `/mockup` composes polished screens and flows and runs a **convergent** designer↔reviewer loop until they clear a design-fitness rubric. | Visual work — UIs, mockups, user-flows — that is *artistic, elegant, and accessible*, not first-draft. |
| **[mission-control](plugins/mission-control/)** | The OPERATE phase: keep the live product healthy and feed the next cycle — `/operate-gate` runs go-live + steady-state readiness, `/observability` instruments the four golden signals and SLI→SLO→alerts, `/incident` drives severity-tiered response → runbook + blameless postmortem, `/maintain` keeps dependencies/CVEs/certs current, and `/iterate` turns a production signal into a new OPPORTUNITY that re-enters DISCOVER (↻). | To run what you shipped — observe it, respond to incidents, maintain it, and loop its learnings back to discovery. |
| **[concierge](plugins/concierge/)** | The ARRIVAL layer: a `SessionStart` hook renders a repo's maintainer-authored `.claude/welcome.md` so the agent greets whoever opens it and offers a conversational decision tree — operate the software, or evolve it — routing them to the right command, runbook, or plugin. **Smart-gated** (greets only on a cold/vague open; steps aside for a concrete task). `/concierge:define-welcome` reads a repo and writes its welcome for you. Also ships the idea-to-production **status line** — `/concierge:statusline` turns on a rich two-line bar (context & rate-limit gauges, the product-lifecycle phase, a ⚔ reviewer-catch tally). | Any repo to greet and orient whoever opens it next — plus a status bar that surfaces the whole suite at a glance. |

## How they compose

![Value flow: nine plugins across an eight-phase cycle from IDEA to PRODUCTION — DISCOVER (market-scanner) ▸ IDEATE (ideator) ▸ DESIGN (atelier) ▸ BUILD (foundry) ▸ ASSURE (foundry, a separate quality gate) ▸ SECURE (sentinel, a separate security gate) ▸ PUBLISH (pressroom) ▸ OPERATE (mission-control), whose learnings loop back to DISCOVER; i2p and concierge cross-cut as front door and greeter.](doc/images/diagrams/01-value-flow.png)

The next command at each phase: **DISCOVER** `/goal` · `/market-scan` → a kept OPPORTUNITY · **IDEATE** the IDEA
package (agent + user-facing faces) · **DESIGN** `/mockup` · `/ui-review` · **BUILD** IDEA ▶ … ▶ STORY ▶ SHIP ·
**ASSURE** `/pr-review` (quality V&V) · **SECURE** `/security-gate` → SECURITY-REPORT.md · **PUBLISH** `/publish`
articles & PDFs · **OPERATE** observe · respond · iterate.

Three cross-cutting concerns ride every phase: **usability** (atelier — `/ui-review` · `/mockup`, the convergent
designer↔reviewer loop), **quality** (foundry — built-in not inspected-in, certified at the ASSURE gate), and
**security** (sentinel — baked in from the start, certified at the SECURE gate). ASSURE (quality) and SECURE
(security) are deliberately **separate gates**; OPERATE (mission-control) keeps the live product healthy and
feeds the next cycle.

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
/plugin install i2p@idea-to-production
/plugin install market-scanner@idea-to-production
/plugin install ideator@idea-to-production
/plugin install foundry@idea-to-production
/plugin install sentinel@idea-to-production
/plugin install pressroom@idea-to-production
/plugin install atelier@idea-to-production
/plugin install mission-control@idea-to-production
/plugin install concierge@idea-to-production
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
