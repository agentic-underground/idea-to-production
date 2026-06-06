---
name: help
description: >
  The marketplace concierge's front door. Use for /i2p-help (or "what can i2p do?",
  "what powers do I have now?", "browse the idea-to-production marketplace", "where do I
  start?"). Renders the three pillars and the DISCOVER ▸ IDEATE ▸ BUILD ▸ DESIGN ▸ SECURE ▸
  PUBLISH value flow, listing only the plugins currently installed with their headline
  commands and the next thing to run, then points at the deeper docs. Thin: it describes the
  specialists, it does not run them.
metadata:
  type: concierge
  output: a scannable capability menu (no files written)
  composes: [all six specialist plugins, by capability — read-only]
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
| **market-scanner** | DISCOVER | `/goal`, `/market-scan` |
| **ideator** | IDEATE | `/ideate` |
| **foundry** | BUILD | `/foundry`, `/pr-review`, `/coverage-loop`, `/roadmapper`… |
| **atelier** | DESIGN (cross-cutting) | `/ui-review`, `/mockup` |
| **sentinel** | SECURE | `/security-gate`, `/secret-scan`, `/pii-audit`, `/dependency-audit` |
| **pressroom** | PUBLISH | `/publish`, `/pressroom:design-review` |
| **i2p** | concierge | `/i2p-help`, `/i2p-review`, `/i2p-check`, `/i2p-flow` |

## 2. Render the menu

Keep it scannable — a menu, not an essay:

1. **The three pillars**, one line each: knowledge-parity · quality-first · waste-elimination
   (overarching constraint: token-efficiency; the suite is self-improving via PRs). See
   `knowledge/covenant.md`.
2. **The value flow** with only installed plugins placed on it, each with its headline command and a
   one-line "run this when you want…". Mark dark stages as "▫ add `<plugin>` to unlock …".
3. **The meta-commands**: `/i2p-review` (one verdict from every reviewer), `/i2p-check` (consolidated
   readiness), `/i2p-flow` (the flow + your next command).
4. **Go deeper**: marketplace `README.md`; `plugins/foundry/knowledge/glossary.md` (every term);
   `plugins/foundry/VALUE_FLOW.md` (the system).

## 3. Focus mode

If `$ARGUMENTS` names a stage or plugin (`design`, `atelier`, `security`…), zoom in: that plugin's
commands, what each produces, and a "next command" suggestion. Otherwise show the whole menu.

---

## Self-improvement covenant

Inherits the concierge covenant (`knowledge/covenant.md`). When a user couldn't find a power they had,
that is a gap in this menu — add the missing line or a tip, fixed upstream once, so every future
`/i2p-help` surfaces it.
