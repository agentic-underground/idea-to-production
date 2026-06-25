# Golden sample — a worked FLEET v2 pipeline (TaskFlow)

A small, **on-disk worked example** of the DELIVER → FLEET handoff: what `/foundry:roadmapper`
emits in `local_file` mode for a tiny capability, in the exact grammar the FLEET engine parses.
Use it as the reference shape when authoring real EPIC/PLAN docs; the full version-pinned contract
is in [`../fleet-pipeline-standard.md`](../fleet-pipeline-standard.md).

The product: **TaskFlow**, a minimal task manager. This golden sample carries the EPIC and its
**first** vertical slice.

| File | What it is |
|---|---|
| [`pipeline.md`](./pipeline.md) | the `.pipeline.md` **manifest** — one row per EPIC; **state lives here** (the engine owns the `state` column). Named `pipeline.md` here so it is not a hidden file in the sample dir; in a real project it is `docs/roadmap/.pipeline.md`. |
| [`EPIC_0001.md`](./EPIC_0001.md) | the **EPIC** — the capability, its `## Plans` table, shared-infra map, and `depends_on`. |
| [`PLAN_0001.md`](./PLAN_0001.md) | the first **PLAN** — one reviewable vertical slice (EARS + acceptance + Construction process), self-contained so a fresh agent or the engine can build it. |

> **What the engine reads.** It scrapes the manifest's `state` column (awk `$4` keyed on `$2`), each
> EPIC's section-scoped `## Plans` table, and the single-line `**Branch**` value
> (`grep -oE 'pipeline/[0-9]{4}-[A-Za-z0-9-]+'`). `order` is always exactly 4 digits. Those shapes are
> load-bearing — match them exactly.
