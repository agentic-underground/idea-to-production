---
name: help
description: >
  The marketplace's front door. Use for /i2p-help (or "what can i2p do?",
  "what powers do I have now?", "browse the idea-to-production marketplace", "where do I
  start?"). Renders the three pillars and the DISCOVER ▸ IDEATE ▸ DESIGN ▸ BUILD ▸ ASSURE ▸
  SECURE ▸ PUBLISH ▸ OPERATE value flow, listing only the plugins currently installed with their
  headline commands and the next thing to run, then points at the deeper docs. Thin: it describes the
  specialists, it does not run them.
metadata:
  type: front-door
  output: a scannable capability menu (no files written)
  composes: [all seven specialist plugins, by capability — read-only]
model: inherit
---

# i2p — Help / Browse the marketplace

One place to answer "I installed this suite — **what can I do now, and where do I start?**" The honest
job here is **knowledge-parity**: close the gap between the powers a user has and the powers they know
about. Describe only what is actually installed.

> **Stance — show, don't oversell.** List installed plugins as live powers; list absent ones only as
> "add it to unlock …". Never imply you can run a command from a plugin that isn't present.

---

## 1. Detect what's active (model-driven)

Judge which `idea-to-production` plugins are active **from the skills and commands available to you this
session** — this is the marketplace's established capability-detection pattern. Do **not** shell out or
probe the filesystem. The plugins to look for:

| Plugin | Stage | Headline commands |
|---|---|---|
| **market-scanner** | DISCOVER | `/discovery-goal`, `/market-scan` |
| **ideator** | IDEATE | `/ideate` |
| **atelier** | DESIGN (+ usability cross-cuts) | `/ui-review`, `/mockup` |
| **foundry** | BUILD + ASSURE (quality gate) | `/foundry`, `/pr-review`, `/coverage-loop`, `/roadmapper`… |
| **security** | SECURE (security gate) | `/scan-all`, `/scan-for-secrets`, `/scan-for-pii`, `/scan-dependencies` |
| **pressroom** | PUBLISH | `/publish`, `/pressroom:design-review` |
| **operate** | OPERATE | *(add to unlock — observe, respond to incidents, iterate the live product)* |
| **i2p** | front door | `/i2p-help`, `/i2p-review`, `/i2p-check`, `/i2p-flow`, `/i2p-lifecycle` |
| **concierge** | arrival | `/concierge:define-welcome`, `/concierge:statusline` |

## 2. Render the menu

Keep it scannable — a menu, not an essay:

1. **The three pillars**, one line each: knowledge-parity · quality-first · waste-elimination
   (overarching constraint: token-efficiency; the suite is self-improving via PRs). See
   `knowledge/covenant.md`.
2. **The value flow** with only installed plugins placed on it, each with its headline command and a
   one-line "run this when you want…". Mark dark stages as "▫ add `<plugin>` to unlock …".
3. **The meta-commands**: `/i2p-review` (one verdict from every reviewer), `/i2p-check` (consolidated
   readiness), `/i2p-flow` (the flow + your next command), `/i2p-lifecycle` (start/track the lifecycle).
4. **Go deeper**: marketplace `README.md`; `plugins/foundry/knowledge/glossary.md` (every term);
   `plugins/foundry/VALUE_FLOW.md` (the system).

## 3. The product lifecycle — explain, then offer to kick one off

Always include a short **Product Lifecycle** section, because it is the spine the whole suite is organised
around. Summarise the model from [`../../knowledge/product-lifecycle.md`](../../knowledge/product-lifecycle.md):

> **idea-to-production is the *creation arc*** of a product — it begins with **the search for an idea**
> and carries it into **OPERATE** (realised, live, and kept alive). **Eight phases forming a cycle**, each
> owned by one plugin:
> **DISCOVER ①** (market-scanner) → **IDEATE ②** (ideator) → **DESIGN ③** (atelier) → **BUILD ④** (foundry)
> → **ASSURE ⑤** (foundry — quality V&V) → **SECURE ⑥** (security — security) → **PUBLISH ⑦** (pressroom)
> → **OPERATE ⑧** (operate — observe, respond, iterate) ↻ loops back to DISCOVER. **ASSURE and
> SECURE are separate first-class gates** (quality ≠ security). Three concerns **cross-cut** every phase:
> usability (atelier), quality (foundry — built-in not inspected-in), security (security — baked in from
> the start). (The marketing *market life cycle* — introduction→growth→maturity→decline — runs alongside
> OPERATE.)

Then **offer to kick one off**: ask if they'd like to start a product lifecycle for this project. If yes,
run `/i2p-lifecycle init` (sets phase DISCOVER) and route them to the first installed owner
(`/market-scan`, or `/ideate` if they already have a validated idea). If a `.i2p/lifecycle.json` already
exists, report the current phase instead and offer `advance`. Mention that the **status line** shows the
live phase — offer `/concierge:statusline` if it isn't enabled.

## 4. Focus mode

If `$ARGUMENTS` names a stage or plugin (`design`, `atelier`, `security`…), zoom in: that plugin's
commands, what each produces, and a "next command" suggestion. Otherwise show the whole menu.

---

## Self-improvement covenant

Inherits the front door covenant (`knowledge/covenant.md`). When a user couldn't find a power they had,
that is a gap in this menu — add the missing line or a tip, fixed upstream once, so every future
`/i2p-help` surfaces it.
