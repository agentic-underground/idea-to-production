---
id: 110
title: "Add DELIVER + /flow to the i2p value-flow map"
status: PENDING
priority: LOW
added: 2026-06-17
depends_on: "#103 (i2p surfaces v2), #105"
---

# [110] Add DELIVER + /flow to the i2p value-flow map

**Brief Description**
Surface the new **DELIVER** lifecycle stage in the i2p front door. `i2p-flow` and `i2p-help` SHALL list the
DELIVER stage with **`/flow`** as its headline command and its artefact, so the value-flow map presents the
flow/DELIVER spine in its canonical slot (DISCOVER ▸ IDEATE ▸ **DELIVER** ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄
SECURE ▸ PUBLISH ▸ OPERATE↻).

### User Stories
- AS a user browsing the marketplace I WANT to see the DELIVER stage with `/flow` as its headline command
  SO THAT I know where flow sits in the idea-to-production pipeline and what to run.
- AS the owner I WANT the front door to reflect the v2 spine SO THAT the map matches the shipped surface.

### EARS Specification
**Ubiquitous**
- `i2p-flow` and `i2p-help` SHALL list the DELIVER stage with `/flow` as its headline command and its
  artefact whenever the flow plugin is installed.

**Event-driven**
- WHEN the flow plugin is installed AND `/i2p-flow` (or `/i2p-help`) is run THE SYSTEM SHALL place DELIVER in
  the value-flow map with `/flow` as the next command to run at that stage.

**Unwanted behaviour**
- IF the flow plugin is not installed THEN the map SHALL mark DELIVER as a dark stage (consistent with how
  i2p handles uninstalled plugins), never inventing a `/flow` surface that is not present.

### Acceptance Criteria
1. Given the flow plugin is installed, When `/i2p-flow` runs, Then DELIVER appears in the value-flow map
   with `/flow` as its headline command and its artefact.
2. Given the flow plugin is installed, When `/i2p-help` runs, Then the DELIVER stage is listed with `/flow`
   as the next command to run.
3. Given the flow plugin is NOT installed, When the map renders, Then DELIVER is shown as a dark stage.

### Implementation Notes
- Depends on [103] (i2p surfaces v2 — the front door is reworked for the new lifecycle) and [105] (the flow
  plugin exists to be placed on the map).
- Edit the i2p `flow` and `help` skills (the value-flow map renderers); both Mermaid and markdown render
  paths must include DELIVER.
- Keep i2p thin — it describes the flow plugin's headline command/artefact; it does not re-implement `/flow`.
- Align the DELIVER stage's placement with the lifecycle insertion done in Stream 2 ([100]–[104]).
