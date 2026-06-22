# Legacy backlog → v2: an IN-SESSION authoring task (NOT an engine EPIC)

The 49 pre-v2 roadmap items live in `.i2p/roadmap/backlog/` (kept as history). Migrating them into the
v2 `docs/roadmap/` pipeline is **roadmap authoring**, which runs **in-session under `/roadmapper`** (its
§3.5 authoring value task: `builder-lead` + `handler-roadmap-decomposition` carve a batch into
conformant `EPIC_NNNN.md`/`PLAN_NNNN.md` docs, gated by `verify-prereqs.sh` check P).

> **Why this is NOT a FLEET engine EPIC.** An earlier attempt filed the migration as `EPIC_0003` with
> PLANs whose Construction process appended rows to `.pipeline.md` and authored new EPIC docs. The FLEET
> engine **forbids a build agent from touching `.pipeline.md` (its `forbidden_mutation`) or the epic doc
> it is building** — so every build calamitied and the circuit breaker paused the pipeline. This is the
> architecture's decision **D3** working as intended: *authoring runs in-session; the engine only ever
> consumes finished, conformance-passing docs.* The engine builds **feature** EPICs; it does not author
> the roadmap.

## How to migrate (when you want to)
Run `/roadmapper` and point it at a theme's legacy items; it emits v2 EPIC/PLAN docs + updates
`.pipeline.md` in-session, then commits per the git workflow. The engine then picks up the new,
build-ready feature EPICs on its next tick. Suggested batches (each its own authoring pass):

| Batch | Legacy `.i2p/roadmap/backlog/` items |
|---|---|
| foundry / core | 32, 34 (child of 32), 35, 43, 44, 46 |
| publish | 50–58 |
| security | 59–67 |
| frontend / atelier | 68–72 |
| comfyui-mcp (already umbrella-shaped) | 49, 73 (EPIC) + 74–80 |
| code-quality (already umbrella-shaped) | 81–86, 87 (EPIC) + 88–91 |

These are authoring batches, not pipeline rows — the manifest gains a row only when `/roadmapper`
emits a real, build-ready feature EPIC.
