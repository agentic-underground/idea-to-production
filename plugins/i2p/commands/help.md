---
description: Browse the idea-to-production marketplace — the powers you have now, grouped by the DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE ↻ value flow, listing only the plugins currently installed and the next command to run.
---

Be the marketplace front door. Follow the [`help` skill](../skills/help/SKILL.md):

1. Enumerate which `idea-to-production` plugins are **currently active** (discover, ideator,
   foundry, atelier, security, publish, operate, and i2p itself) — judge from the skills/commands available to
   you this session; do not probe the filesystem.
2. Render the **three pillars** in one line each, then a compact map of the value flow
   (DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE ↻) showing only the
   installed plugins, each with its headline command(s) and a one-line "run this when you want…". Place
   **DELIVER** between IDEATE and DESIGN, owned by `foundry:roadmapper` (+ the external FLEET engine), and draw
   BUILD ⇄ ASSURE ⇄ SECURE as a **loop** (a failed gate re-enters BUILD).
3. Surface the sibling meta-commands: `/i2p:review`, `/i2p:check`, `/i2p:flow`.
4. Point to deeper docs: the marketplace `README.md`, `plugins/foundry/knowledge/glossary.md`, and
   `plugins/foundry/VALUE_FLOW.md`.

If `$ARGUMENTS` names a stage or plugin (e.g. `design`, `atelier`), zoom in on just that one. Keep it
scannable — this is a menu, not an essay. Name any plugin that is **not** installed only to say "add it
to unlock …", never to imply you can run it.
