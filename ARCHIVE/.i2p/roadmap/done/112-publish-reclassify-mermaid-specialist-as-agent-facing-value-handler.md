---
id: 112
title: "publish: reclassify mermaid-specialist as an agent-facing value-handler"
status: COMPLETE
priority: LOW
added: 2026-06-17
completed: 2026-06-18
depends_on: "#96 (pressroom→publish rename)"
---

# [112] publish: reclassify mermaid-specialist as an agent-facing value-handler

**Brief Description**
Mermaid logic lives in PRESSROOM (→ `publish` in #96) in **two** places: a user-facing skill
(`plugins/pressroom/skills/mermaid-specialist/`, triggering on "mermaid…", "sequence/state/sankey…") AND
an agent-facing value-handler (`plugins/pressroom/agents/handler-mermaid.md`) that the `illustrator`
orchestrator spawns to emit a Mermaid figure. That is duplication — two homes for one capability.

By contrast, **Graphviz** has only ONE home: the value-handler `handler-graphviz.md`, reached through the
`diagram-studio` skill — there is no `graphviz-specialist` user skill. The patterns are inconsistent: a
user reaches Mermaid through a *dedicated slash command* but reaches Graphviz through the *general front
door*. The owner's question — *"is mermaid-specialist user- or agent-facing? it should be a
value-handler"* — resolves in favour of the Graphviz precedent: consolidate onto the handler and let the
`diagram-studio` skill be the user-facing door for both engines.

This item reclassifies `mermaid-specialist` as an agent-facing value-handler: consolidate the Mermaid
logic onto `agents/handler-mermaid.md`, route the `diagram-studio` skill to that handler (the Graphviz
pattern), and thin/remove the standalone user-facing skill so users reach Mermaid via
`diagram-studio` / `/publish`, not a dedicated `/publish:mermaid-specialist` command.

### The case
- **Duplication (`muda`).** Two artefacts carry overlapping Mermaid knowledge (diagram-type selection,
  theming, the shared 4×9 charting matrix, mmdc rendering). Both already declare they *share* —
  `../rich-pdf-with-diagrams/references/charting-matrix.md` — yet the prose/logic is maintained twice.
  One source of truth removes the rediscovery waste.
- **Orchestration consistency.** The `illustrator` orchestrator already spawns `handler-mermaid` as a
  value-handler to fill a Mermaid figure-slot. A user-facing skill that re-states the same capability is
  a second, parallel surface for what the value-handling paradigm says should be one handler the
  orchestrator (or a routing skill) calls.
- **The Graphviz precedent.** Graphviz is correctly modelled: `handler-graphviz.md` (the value-handler)
  reached via `diagram-studio` (the user door). No `graphviz-specialist`. Mirroring that for Mermaid
  makes the two engines symmetric — one user door (`diagram-studio` / `/publish`), one handler each.
- **Discoverability is not lost.** Removing the dedicated command does NOT hide Mermaid: `diagram-studio`
  already advertises both engines, and its description already says it defers Mermaid-specific work. The
  user keeps full Mermaid reach through the general front door — they just stop having a redundant
  dedicated command.

### What "reclassify" entails
1. **One source of truth.** Move/merge the Mermaid logic (full diagram taxonomy + "when each fits",
   theming discipline, ELK layout, accTitle/accDescr accessibility, mmdc rendering) so it lives on the
   value-handler `handler-mermaid.md`. The handler becomes the single authority; the
   `references/mermaid-taxonomy.md` reference is retained and pointed at by the handler.
2. **Route `diagram-studio` to the handler.** `diagram-studio` selects the engine (Graphviz **or**
   Mermaid) and, for Mermaid-specific work (taxonomy choice, theming, ELK), routes to / spawns
   `handler-mermaid` — exactly as it reaches Graphviz via `handler-graphviz`.
3. **Thin or remove the user-facing skill.** Reduce `skills/mermaid-specialist/` to nothing more than a
   pointer at `diagram-studio` (or remove it outright), so there is no standalone
   `/publish:mermaid-specialist` slash command competing with the front door.
4. **Update the deferral + component text.** Revise `diagram-studio`'s deferral prose (it currently
   defers Mermaid-specific work to the `mermaid-specialist` skill — it should defer to / drive
   `handler-mermaid`), and remove the `mermaid-specialist` row from the `publish` README component list,
   folding Mermaid under `diagram-studio`.

### User Stories
- AS the owner I WANT Mermaid modelled like Graphviz — one value-handler, reached through
  `diagram-studio` — SO THAT the two engines are symmetric and the capability has a single home.
- AS a maintainer I WANT one source of truth for the Mermaid taxonomy/theming/rendering logic SO THAT a
  fix or lesson lands once, not in two places that drift.
- AS a user I WANT to ask `diagram-studio` / `/publish` for a Mermaid diagram and get the full
  specialist capability SO THAT I lose nothing by losing the dedicated command.

### EARS Specification
**Ubiquitous**
- The Mermaid value-handling logic (taxonomy selection, theming, ELK layout, accessibility, mmdc
  rendering) SHALL have exactly ONE authoritative home: the value-handler `agents/handler-mermaid.md`.
- Mermaid SHALL be modelled consistently with Graphviz: a value-handler reached through the
  `diagram-studio` skill, with no engine-specific user-facing slash command.

**Event-driven**
- WHEN a user requests a Mermaid diagram (or Mermaid-specific work: a sequence/state/sankey/timeline
  diagram, theming, or an ELK layout) via `diagram-studio` / `/publish` THE SYSTEM SHALL route to /
  spawn `handler-mermaid` and deliver the full specialist capability.
- WHEN the `illustrator` orchestrator needs a Mermaid figure THE SYSTEM SHALL spawn the same
  `handler-mermaid` value-handler — the single authority — not a separate skill body.

**Unwanted behaviour**
- IF Mermaid logic would be duplicated across both a user-facing skill and the handler THEN THE SYSTEM
  SHALL NOT ship that duplication — the standalone `mermaid-specialist` skill SHALL be thinned to a
  pointer or removed, leaving no second authority.
- IF a reference to `/publish:mermaid-specialist` (or the standalone skill) remains in deferral text or
  the README after reclassification THEN that SHALL be treated as drift and corrected to point at
  `diagram-studio` / `handler-mermaid`.

### Acceptance Criteria
1. Given the reclassification is complete, When the repo is searched, Then the Mermaid taxonomy/theming/
   rendering logic exists in exactly one authoritative place (`handler-mermaid.md`), with the shared
   references unforked.
2. Given a user asks `diagram-studio` / `/publish` for a Mermaid (e.g. sequence) diagram, When the
   request is handled, Then `handler-mermaid` produces it with the full specialist capability — taxonomy
   choice, theming, accessibility — losing nothing versus the old dedicated skill.
3. Given the change is merged, When the `publish` surface is inspected, Then there is no standalone
   `/publish:mermaid-specialist` slash command, and Mermaid is reached the same way Graphviz is (via
   `diagram-studio`).
4. Given `diagram-studio`'s deferral text and the `publish` README component list, When inspected, Then
   neither references the removed standalone skill — both point at `diagram-studio` / `handler-mermaid`.
5. Given the `illustrator` orchestrator, When it fills a Mermaid figure-slot, Then it spawns
   `handler-mermaid` (unchanged behaviour, now the single authority).

### Implementation Notes
- Land AFTER #96 so all surface text is authored against the `publish` name.
- Files in play: `plugins/pressroom/agents/handler-mermaid.md` (the destination authority),
  `plugins/pressroom/skills/mermaid-specialist/` (thin to a pointer or remove, keep
  `references/mermaid-taxonomy.md` and have the handler point at it),
  `plugins/pressroom/skills/diagram-studio/SKILL.md` (route Mermaid-specific work to `handler-mermaid`;
  update deferral prose), `plugins/pressroom/README.md` (drop the `mermaid-specialist` component row;
  fold Mermaid under `diagram-studio`).
- Mirror `handler-graphviz` ↔ `diagram-studio` exactly so the two engines read as one consistent pattern.
- Preserve the SHARED charting-matrix + lessons log link (`../rich-pdf-with-diagrams/references/...`) —
  consolidation must not fork it.
- Verify no other skill, agent, command, or doc links to the standalone `mermaid-specialist` skill before
  removing it (grep the marketplace); convert any such links to `diagram-studio` / `handler-mermaid`.
- This is the Mermaid half of the broader taxonomy-reorg toward the value-handling paradigm (cf. #44);
  keep the framing consistent with that item.
