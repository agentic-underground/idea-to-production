---
name: ideate
description: >
  Refine an idea into a build-ready IDEA package. Trigger with /ideate (or "let's flesh out this idea",
  "turn this into a project", "I have an idea: …", "refine this opportunity", "make this build-ready").
  Accepts EITHER a validated opportunity from the market-scanner plugin OR a raw idea you already have,
  and refines it to knowledge-parity through an adversarially-challenged dialogue (infer-first, one
  question at a time with a recommended answer + multiple-choice). Produces the IDEA package — precise
  agent-facing handoff docs (brief + SMU-seed + first slice + handoff contract, satisfying FOUNDRY's
  discovery exit criteria) plus a rich illustrated user-facing dossier (via publish when installed) —
  iterated with the user, then handed to FOUNDRY. Use proactively whenever a user wants to make an idea
  real.
metadata:
  type: producer
  output: the IDEA package (agent-facing handoff docs + user-facing dossier) → FOUNDRY, or doc/idea/<slug>/
model: inherit
---

# IDEATOR — Refinement dialogue

The bridge from *a candidate worth pursuing* to *a thing the conveyor can build*. IDEATOR refines an idea
to **knowledge-parity** and emits the **IDEA package**. It **supersedes FOUNDRY's inline ideator**: when
this plugin is installed it owns ideation; FOUNDRY's inline skill is the graceful fallback when it isn't.

## How to run

1. **Take the input.** EITHER a **validated opportunity** handed from `/market-scan` (a scorecard +
   evidence — much is already known; refine, don't restart), OR a **raw idea** the user supplies (start
   the dialogue from scratch). Infer what you can from the input; confirm rather than re-interrogate.
   When the raw idea is a **product proposition** — "**By doing X I propose Y, and the value is Z**" (a
   problem/solution/value triad, the marketplace's raw-thesis entry lane) — recognise the triad and
   **pre-fill** the brief from it: X → the wedge/first slice, Y → the SOLUTION, Z → the SUCCESS-METRIC /
   value, and infer a PROBLEM and PRICE-BAND to confirm. Present what you pre-filled for confirmation;
   then challenge the gaps rather than asking the user to restate what they already said.
2. **Challenge it to parity.** Run the **challenge protocol**
   ([`../../knowledge/ideation/challenge-protocol.md`](../../knowledge/ideation/challenge-protocol.md)):
   walk the axes — problem · actor · scope · success · value&price · wedge · slice · stack-fit · risks —
   pressure-testing each, naming the hidden assumption, **disambiguating every shallow area out loud**.
   One focused question per turn, **each with a recommended answer + multiple-choice**. Where the idea
   isn't ready, say so — return to discovery or record an accepted risk; never paper over a soft idea.
3. **Assemble the IDEA package** to the contract
   ([`../../knowledge/ideation/idea-package.md`](../../knowledge/ideation/idea-package.md)):
   - **Agent-facing** (precise): the idea brief, the SMU-seed, the first vertical slice, the handoff
     contract — and **verify the exit gate** (actionable problem, named actors, explicit scope, concrete
     constraints, testable success, every open question answered-or-accepted). Do **not** hand off until
     it passes.
   - **User-facing** (rich): the IDEA dossier — narrative, scorecard table, market/pricing/competition
     charts, **a user-flow, and (for a UI idea) a mockup screen**. Render *by capability*: charts/diagrams
     via **publish `/publish`**; **user-flows and mockups via atelier `/mockup`** (designed to the canon
     and design-reviewed before the user sees them — carefully composed, not first-draft). Degrade to
     structured markdown / Mermaid-source otherwise, and say so. The flow/mockup must visualise the **first
     slice** (don't let them drift from it).
4. **Iterate with the user.** Present the package; ask "what needs adjusting?"; correct **both faces** in
   lock-step (they must never disagree). Re-display when a change is significant.
5. **Challenge the package independently — before handoff.** The challenge protocol in step 2 is *you*
   pressure-testing your own work; that is not adversarial review. Once the agent-facing package is
   drafted and the user is satisfied, spawn the **IDEA challenger** agent
   ([`${CLAUDE_PLUGIN_ROOT}/agents/challenger.md`](../../agents/challenger.md)) as a **fresh-context
   second party** — hand it the agent-facing package (brief + SMU-seed + first slice + handoff contract)
   and instruct it to *refute that it is build-ready and at knowledge-parity*. Resolve its verdict before
   handoff: **READY** → the package has earned the handoff, proceed; **NEEDS_REVISION** → close the named
   gaps in the dialogue and re-challenge (never hand off over open gaps); **NOT_READY** → the idea is
   still soft, return to discovery (or market-scanner) rather than paper over it. Only a package that
   survives the challenger is handed to FOUNDRY.
6. **Hand off.** When the user is satisfied and the exit gate passes: hand the agent-facing package to
   **FOUNDRY** if installed (its IDEA station receives it → roadmap → `/loop /foundry` builds it), else
   write the package to `doc/idea/<slug>/` and point the user at FOUNDRY/the inline dev system.

## Validate against live evidence — use web research

When the challenge turns on a fact about the world — **value & price** (what do comparable tools charge?),
the **wedge** (does an incumbent already do this?), **stack-fit** (current library/runtime reality) — use
**WebSearch / WebFetch** (built-in) and the **Fetch MCP** (`mcp__fetch__*`, shipped, when approved) to
check real pricing pages, competitor features, and current docs before you write the answer into the
package. An assumption confirmed against a live page is parity; an assumption you *couldn't* verify is an
**open question** recorded in the package, not a silent guess. Degrade to reasoning-from-the-user when web
tools are unavailable, and say so. (If `market-scanner` already gathered this evidence, reuse it — don't
re-fetch.)

## The dialogue discipline

Infer-first, one question per turn, **recommended answer + multiple-choice**, adversarial about the
substance. Never a wall of questions; never silent enforcement (present the default, name the trade-off,
let the user decide). The point is to reach parity fast *and* leave the user feeling the idea got sharper.

## Naming the product

When the idea needs a name — a new product, or a rename — use the dedicated **`name-search` skill**
(`/ideator:name`), which owns naming end-to-end: charter → wide-net generation → **deterministic**
availability verification (npm/PyPI/crates/GitHub + adoption tier, zero per-name LLM tokens) →
adversarial challenge → a ranked report with a top pick. Don't inline naming here — point at it, so a
naming exercise gets the full marketing-grade search rather than an ad-hoc check.

## Self-improvement covenant

Carries the KAIZEN self-improvement covenant ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)).
When a downstream builder hits an ambiguity this package *should* have resolved, that is not a per-idea
slip but a **challenge axis or package field that needs sharpening** — flag it for the `self-improve`
skill so a PR lands the fix for every future ideation.

## Product lifecycle (by capability)

When the IDEA package is complete and handed off (FOUNDRY's discovery exit criteria met), and the **i2p** plugin is installed, mark the **IDEATE** phase done so the marketplace
product lifecycle and the status line advance to DESIGN:

```bash
/i2p:lifecycle done IDEATE   # order-safe & idempotent — a no-op unless a lifecycle is running at IDEATE
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
