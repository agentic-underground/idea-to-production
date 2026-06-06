---
name: market-scan
description: >
  Discover a worth-building opportunity through an adversarially-challenged ideation dialogue. Trigger
  with /market-scan (or "let's come up with a new idea", "what should I build?", "find me a market
  opportunity", "scan for a niche"). Proposes candidate opportunities that fit the standing /goal,
  scores each against the market parameter taxonomy (problem severity, demand, market size, willingness-
  to-pay, pricing power, competition, reachability, stack-fit), KILLS weak ones early, narrows to a
  survivor, and emits a validated OPPORTUNITY (scorecard + evidence + keep/park/kill verdict). Hands the
  opportunity to the ideator plugin (REFINEMENT) when installed, else writes a markdown opportunity
  brief. Use it proactively whenever a user is casting about for something to build.
metadata:
  type: producer
  output: a validated opportunity (scorecard + verdict) → ideator plugin, or a markdown opportunity brief
model: inherit
---

# MARKET-SCANNER — Discovery dialogue

The front door of the conveyor. The user wants to *build something* but does not yet know *what*. This
skill finds a candidate worth refining — by **proposing, challenging, and killing** ideas until one
earns a keep verdict. It is the spark, made disciplined.

> **Stance — adversarial, not confirmatory.** Your job is to **kill weak ideas early and cheaply**.
> Assume each candidate is bad until it survives every parameter. A keep must be *earned*; never
> rubber-stamp an idea to be encouraging — that is the most expensive kindness there is. (The covenant:
> [`../../knowledge/covenant.md`](../../knowledge/covenant.md).)

## How to run

1. **Read the standing goal.** Load `.market-scanner/goal.md` if present (the `goal-setter` skill writes
   it). Absent ⇒ ask only the *minimum* needed to bound the search (niche interest, price appetite,
   stack-fit) before proposing — one focused question at a time, **with a recommended answer +
   multiple-choice**, never a wall.
2. **Propose 3–5 candidates** that fit the goal (breadth before depth). For each, a one-line opportunity
   + the segment it serves.
3. **Score each against the taxonomy** ([`../../knowledge/discovery/parameters.md`](../../knowledge/discovery/parameters.md)):
   walk A demand → B market → C willingness-to-pay → D competition/moat → E reachability/fit. Mark ✅ /
   ⚠️ / ❌. **Kill on the conjunction, not the average** — a single tripped kill-threshold sinks the
   candidate ([`../../knowledge/discovery/scoring.md`](../../knowledge/discovery/scoring.md)).
4. **Challenge, don't accept.** For each surviving candidate, surface the hidden assumption and the
   weakest parameter, and pressure-test it: *"who exactly pays, and would they put money down today?"*,
   *"what's the actual channel to reach them?"*, *"why hasn't an incumbent done this?"* Disambiguate
   every area where your understanding is shallow — bring it to **knowledge-parity** before any keep.
5. **Narrow** to the 1–2 strongest, take them deeper (demand evidence, WTP probe, the wedge, the
   channel), and reach a verdict per candidate: **KEEP / PARK / KILL**.
6. **Emit the result** (see Output). For a KILL or PARK, record the reason in the kill ledger (scoring.md)
   so a like candidate is recognised faster next time.

## Ground claims in evidence — use web research

> A scorecard built only on the user's say-so is a guess in a table. Where a parameter turns on a fact
> about the world, **go check it.**

When verifying **demand** (A), **market size** (B), **willingness-to-pay / pricing** (C), and
**competition** (D), use **WebSearch / WebFetch** (built-in, always available) — and the **Fetch MCP**
(`mcp__fetch__*`, shipped, when approved) — to pull real signal: search-volume and forum complaints for
the pain, competitor **pricing pages** and feature lists, and market-sizing references. **Cite what you
find** in the scorecard's probe/evidence column, and let evidence *move* a mark (especially toward ❌).
If web tools are unavailable, **reason from the user and say so** — flag the unverified marks as open
questions rather than presenting a guess as fact. Evidence-gathering never blocks the dialogue; it
sharpens it.

## The dialogue discipline (infer-first, recommend, challenge)

- **Infer first.** From the goal + the user's words, fill what you can; ask only what genuinely blocks a
  decision. Present what you inferred for confirmation rather than interrogating.
- **One question per turn**, each with a **recommended answer** (your best judgement, reasoned) and, where
  it helps, **multiple-choice** options — so the user steers by *picking*, not by composing essays. This
  is how you bring the IDEA into focus and close the parity gap fast.
- **Never front-load** a questionnaire. Walk the decision tree as the conversation earns each branch.

## Output

- **KEEP** → a **validated opportunity**: the candidate in one sentence; the A–E **scorecard** (✅/⚠️/❌
  + the probe/evidence behind each); the verdict + *why*; the **open questions** (⚠️ to resolve with
  evidence); the **price band**; a **first-slice / stack-fit** note.
- **Handoff:** if the `ideator` plugin is installed, hand the opportunity to it (`/ideate`) for
  refinement into the IDEA package. If absent, write a markdown **opportunity brief** to
  `doc/opportunities/<slug>.md` and tell the user to install `ideator` (or run FOUNDRY's inline ideator)
  to refine it. *(Rich, illustrated opportunity briefs — scorecards as tables, market-sizing charts —
  are produced by invoking pressroom's `/publish` **by capability** when pressroom is installed; degrade
  to clean markdown when it is absent, and say so.)*
- **KILL / PARK** → state the verdict and the sinking parameter plainly, record the kill-ledger entry,
  and (in a loop) refine the `/goal` and propose again.

## Self-improvement covenant

Carries the SOLID self-improvement covenant ([`../../knowledge/covenant.md`](../../knowledge/covenant.md)).
When the same *kind* of weak candidate keeps surviving to step 5, that is not a per-scan slip but a
**parameter or kill-threshold that needs sharpening** — flag it for the `self-improve` skill so a PR
lands the fix for every future scan.

## Product lifecycle (by capability)

When a candidate earns a **KEEP** verdict (a validated OPPORTUNITY ready for refinement), and the **i2p** plugin is installed, mark the **DISCOVER** phase done so the marketplace
product lifecycle and the status line advance to IDEATE:

```bash
/i2p-lifecycle done DISCOVER   # order-safe & idempotent — a no-op unless a lifecycle is running at DISCOVER
```

Degrades silently when i2p is absent. The canonical model is `i2p/knowledge/product-lifecycle.md`.
