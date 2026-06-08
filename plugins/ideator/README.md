# IDEATOR — Refine an idea into a build-ready IDEA package

> The bridge from *a candidate worth pursuing* to *a thing the conveyor can build*.

IDEATOR is the **REFINEMENT** phase of the `idea-to-production` marketplace. It takes a validated
opportunity (from [`market-scanner`](../market-scanner/)) or a raw idea you already have, refines it to
**knowledge-parity** through an adversarially-challenged dialogue, and emits the **IDEA package**.

## The IDEA package — two faces, one understanding

- **Agent-facing** (precise, high-clarity, for the conveyor): an **idea brief**, an **SMU-seed**, the
  **first vertical slice**, and a **handoff contract** — that satisfies FOUNDRY's **discovery exit
  criteria** (actionable problem, named actors, explicit scope, concrete constraints, testable success).
  This is what FOUNDRY ingests; it must be unambiguous to a fresh agent with no history.
- **User-facing** (rich, illustrated): the **IDEA dossier** — opportunity narrative, parameter scorecard,
  market/pricing/competition charts, a **user-flow**, and (for a UI idea) a **mockup screen** — rendered
  **by capability**: charts via [`pressroom`](../pressroom/)'s `/publish`, and flows/mockups via
  [`atelier`](../atelier/)'s `/mockup` (designed to the canon and **design-reviewed** before you see them —
  carefully composed, not first-draft). Degrades to structured markdown / Mermaid-source otherwise.

The two faces never disagree: a fact corrected in one is corrected in both. The package is **iterated with
you** until both are right, *then* handed off.

## Naming a product

Need a name? **`/ideator:name`** (the `name-search` skill) runs a marketing-grade **naming studio**:

1. **Discovery interview** — infer-first, then asks only the load-bearing gaps (audience, **brand
   archetype**, **name-type appetite**, power-adjacency, intellectual-humour appetite, risk appetite),
   one question at a time with a recommended answer + multiple choice.
2. **Wide-net generation** — not just coined words: the full **name-type taxonomy** (suggestive, metaphor,
   mythological, compound, portmanteau, coined, acronym/**backronym**, scientific-taxonomic, animal, …)
   layered with language/etymology veins, **affix hooks** (-ify, -ly, get-, …), and **phonosemantic**
   tuning to the archetype. The art-of-naming canon lives in [`knowledge/naming/`](knowledge/naming/).
3. **Deterministic verification** (zero per-name LLM tokens) — npm / PyPI / crates.io / GitHub with an
   adoption tier (CLEAR / LOW_ADOPTION / ABANDONED / TAKEN), plus opt-in **neighbour / typo-squat
   proximity** (no accidental visits), **domain availability** (RDAP: .com/.dev/.io/.ai), and a
   **cross-language connotation** screen.
4. **Scored challenge** — Neumeier's 7 criteria, Watkins' SMILE/SCRATCH, archetype-fit, sound-symbolism-fit
   — availability and challenge kept as separate verdicts.
5. **Ranked report** — where it searched, every name kept/rejected and why, the rubric scores, a top pick
   with confidence + residual risks. Use it to name a new product, an org, or to rename one.

> Tip: set `GITHUB_TOKEN` for a reliable neighbour pass (the GitHub search API is rate-limited; without a
> token, neighbour status is reported `unknown`, never guessed).

Where the challenge turns on a fact about the world — comparable **pricing**, whether an incumbent owns
the **wedge**, the current **stack** reality — IDEATOR validates against **web research** (built-in
WebSearch/WebFetch + a shipped, keyless Fetch MCP) before writing the answer into the package; what it
can't verify is recorded as an open question, not a guess. (Reuses market-scanner's evidence when handed
one; the marketplace's `PREREQUISITES/05-discovery.md` documents the discovery toolchain.)

## How it composes

- **market-scanner → IDEATOR**: a kept opportunity is refined here. Or bring your own raw idea — IDEATOR
  starts the dialogue from scratch.
- **IDEATOR → foundry**: the agent-facing package is handed to [`foundry`](../foundry/)'s IDEA station
  (by capability) → roadmap → `/loop /foundry` carries it to PRODUCTION. **IDEATOR supersedes FOUNDRY's
  inline ideator**, which remains as the graceful-degradation fallback when this plugin is absent.
- The arc: **DISCOVER (market-scanner) → IDEATE (ideator) → BUILD (foundry) → SECURE/PUBLISH
  (sentinel/pressroom)**. *Graceful enhancement* — no hard dependency in any direction.

## The feedback loop

When a downstream builder hits an ambiguity the IDEA package *should* have resolved, that feedback flows
back: the corresponding challenge axis or package field is **sharpened via a PR**, so every future
ideation, for all users, asks the missing question by default. The spark gets sharper over time.

## Governed by the marketplace covenant

IDEATOR holds the **three pillars** (knowledge-parity, quality-first, waste-elimination) under the
**token-efficiency** constraint, and the **SOLID self-improvement covenant**
([`knowledge/covenant.md`](knowledge/covenant.md)). Refinement to knowledge-parity *is* its whole job.

**Commands:** `/ideate` (refine an idea), **`/ideator:name`** (name a product), **`/ideator:inspect`**
(audit this plugin), `/ideator:self-improve` (sharpen it), `/ideator:check` (verify tools). Dual-licensed
**MIT OR Apache-2.0**.
