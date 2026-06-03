# Examples — worked artefacts of the dev system

Real, production-proven artefacts that show the FOUNDRY development system applied end-to-end:
**EARS spec → Gherkin features → implementation plan**. They are teaching exemplars — copy the
*shape*, not the contents.

> **Provenance:** These were produced while building the FOUNDRY tooling itself (the author's
> private `~/.claude` "FORGE" config repo — its auto-sync and phase-sensor features). They reference
> that `~/.claude` infrastructure **illustratively**; they are *examples of the method*, not
> operational instructions for this plugin. Treat the domain (a git-sync'd config repo) as the
> sample problem and study how each station's artefact is written.

| File | Station it exemplifies | Shows |
|---|---|---|
| [`forge-features.ears.md`](forge-features.ears.md) | **EARS** | A real requirement set with unique IDs and the five EARS forms (ubiquitous / event-driven / state-driven / unwanted / optional). |
| [`forge-sync.feature`](forge-sync.feature) | **FEATURE (BDD)** | Gherkin scenarios — happy / unhappy / abuse — tagged back to EARS IDs (`@EARS-NNN`). |
| [`phase-sensor.feature`](phase-sensor.feature) | **FEATURE (BDD)** | BDD for a state-machine / artifact-detection feature; Given–When–Then discipline. |
| [`forge-sync-plan.md`](forge-sync-plan.md) | **PLAN** | A per-feature plan: EARS↔scenario map, explicit risk analysis, an ordered implementation checklist. |
| [`phase-sensor-plan.md`](phase-sensor-plan.md) | **PLAN** | A plan that also captures design (artifact-based phase detection) — plan + architecture in one. |
| [`expansion-redaction-scrubber.md`](expansion-redaction-scrubber.md) | IDEA → expansion | A worked Mode-C idea expansion. |

How to read them together: start with `forge-features.ears.md` (what must be true), then the
matching `*.feature` (how the behaviour is proven), then the `*-plan.md` (how it gets built). That
is one slice carried from SPEC to a buildable plan — the same path `VALUE_FLOW.md` describes.

See also the narrative of how the system came to be: [`../docs/HISTORY.md`](../docs/HISTORY.md).
