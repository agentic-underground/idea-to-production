# idea-to-production — a Claude Code plugin marketplace

> Carry software from **IDEA to PRODUCTION** — with security and publishing that switch on when you need them.

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

This marketplace ships three composable plugins. Install **foundry** for the core production
discipline; add **sentinel** and **pressroom** to light up security gates and publication-grade
output. They are independent — foundry runs perfectly alone and emits markdown — but when the
companions are present, foundry uses them automatically (*graceful enhancement*).

## The plugins

| Plugin | What it does | Install when you want… |
|--------|--------------|------------------------|
| **[foundry](plugins/foundry/)** | The value conveyor: IDEA ▶ ROADMAP ▶ PLAN ▶ EARS ▶ FEATURE ▶ TEST ▶ IMPLEMENT ▶ STORY ▶ SHIP, staffed by role-tuned agents and governed by three pillars (knowledge parity, quality-first + perf-delta gate, waste elimination). | A disciplined, test-first, vertical-slice production system. |
| **[sentinel](plugins/sentinel/)** | A pre-release security gate: PII, secrets/credentials, and dependency/supply-chain audits → one severity-ranked report with a PASS / REVIEW / BLOCK verdict. | To never ship a leaked key, a real person's data, or a vulnerable dependency. |
| **[pressroom](plugins/pressroom/)** | Publishing: narrative articles mined from git history & docs, standalone diagrams (Graphviz/Mermaid), and print-quality PDFs with A4-legible figures. | Documentation and release artefacts that look professionally published. |

## How they compose

```
                 ┌─────────────── foundry (core, emits markdown) ───────────────┐
   IDEA ▶ … ▶ SHIP                                                              │
                 │  SECURITY gate ── if sentinel installed ─▶ SECURITY-REPORT.md │
                 │  PUBLISHING    ── if pressroom installed ─▶ articles / PDFs    │
                 └───────────────────────────────────────────────────────────────┘
```

`foundry` never *requires* the companions. When `sentinel` is installed, foundry's SECURITY
station can run the security gate before delivery; when `pressroom` is installed, foundry's
PUBLISHING station can upgrade markdown into articles, diagrams, and PDFs. Absent, foundry
delivers clean markdown and notes that the richer step was skipped.

## Install

Add the marketplace, then install whichever plugins you want:

```
/plugin marketplace add whatbirdisthat/idea-to-production
/plugin install foundry@idea-to-production
/plugin install sentinel@idea-to-production
/plugin install pressroom@idea-to-production
```

Each plugin works on its own — `sentinel` and `pressroom` are useful on any repository, not just
foundry projects.

## Concepts & glossary

New here? [`plugins/foundry/knowledge/glossary.md`](plugins/foundry/knowledge/glossary.md) names every
concept, plugin, agent, skill, and command, draws the conceptual-domain tree, and settles the
**foundry vs forge vs founder** question. The system itself is described in
[`plugins/foundry/VALUE_FLOW.md`](plugins/foundry/VALUE_FLOW.md).

## License

Dual-licensed under **MIT OR Apache-2.0**. See [LICENSE](LICENSE).
