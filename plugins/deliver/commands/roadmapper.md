---
description: Manage a project ROADMAP.md / FLEET v2 pipeline — capture an idea, write EARS specs, decompose into dependency-ordered EPIC/PLAN slices, and drive features through a test-first development system. The DELIVER station's front door.
---

Manage the roadmap. Follow the [`roadmapper` skill](../skills/roadmapper/SKILL.md):

1. **Resolve the roadmap surface** (skill §1): the FLEET v2 pipeline (`docs/roadmap/` —
   `.pipeline.md` manifest + `EPIC_NNNN.md` + `PLAN_NNNN.md`, the canonical surface, read through
   the external `pipeline` plugin when present), else the legacy `.i2p/roadmap/` tree, else a
   single-file `ROADMAP.md`.
2. **Dispatch by what `$ARGUMENTS` (or the conversation) asks for** (skill §2 / §11):
   - capture / "add to the roadmap" → §3 CAPTURE (author EPIC + PLAN + manifest as a value task,
     §3.5; commit after every roadmap write, §3.4)
   - "what's on the roadmap?" / "what's next" / "check status" → §5 QUERY
   - GO hook ("ship it", "build N", "green light") → §11.4: for a v2 project this **kicks the
     external FLEET engine off** for the resolved item (roadmapper authors; the engine builds and
     owns the manifest `state`); for a legacy `ROADMAP.md` project it drives DEV_SYSTEM Steps 0–9.
   - DISCUSS hook ("talk through", "spec it", "plan it") → §11.5 refine the spec
   - RESUME hook ("pick it up", "where were we") → §11.6
3. **Conform to the FLEET v2 grammar** before committing — the engine parses it with regex/awk, so
   the shape is load-bearing: leading-`|` manifest rows, 4-digit `order`, single-line `**Branch**`,
   `## Plans` = `order | plan | state`. The full contract is vendored at
   [`../skills/roadmapper/references/fleet-pipeline-standard.md`](../skills/roadmapper/references/fleet-pipeline-standard.md);
   worked golden artifacts are in
   [`../skills/roadmapper/references/examples/`](../skills/roadmapper/references/examples/).

`$ARGUMENTS` may carry the feature request, a roadmap item reference (number or name), or a mode
hook. With no arguments, surface the GO-hook reference card (skill §11.8) and the current roadmap.
