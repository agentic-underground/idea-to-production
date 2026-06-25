# idea-to-production Marketplace — Improvement Plan

## Goal

Bring the marketplace to the point where a product can travel from the initial value-proposition statement — **"By doing X I propose Y and the value will be Z"** — through every lifecycle phase (DISCOVER ▸ IDEATE ▸ DELIVER ▸ DESIGN ▸ BUILD ⇄ ASSURE ⇄ SECURE ▸ PUBLISH ▸ OPERATE ↻) to a live, operating product, with **every advertised transition actually traversable at runtime** and **every entry/exit seam backed by a shared, worked contract** — not only by prose. The architecture is already sound; this plan closes the missing wires and reconciles the docs so the journey the marketplace describes is the journey it can actually run.

## The Journey This Plan Enables

Once every step below is complete, the intended journey reads end-to-end as follows:

1. **The user holds a raw thesis.** They open the repo (or run `/i2p:help`) and the Start-here block now shows an explicit lane: *"Already have an idea or proposition? → `/ideator:ideate \"By doing X I propose Y, value Z\"`."* They type it. (Step 7)
2. **DISCOVER (optional validation).** If they're unsure the thesis holds, `/discover:market-scan` now recognises a user-supplied thesis and *validates* it (rather than only proposing fresh candidates), writing a validated `doc/opportunities/<slug>.md`. (Step 7)
3. **IDEATE → handoff.** `/ideator:ideate` runs the challenged dialogue and writes a fully-specified IDEA package to a **documented file layout** — `doc/idea/<slug>/{brief.md, smu-seed.md, first-slice.md, handoff.md, dossier.md}` — matching a committed worked example the user can compare against. (Step 6)
4. **DELIVER.** The user types `/foundry:roadmapper` — which now **resolves to a real command** — and gets a `docs/roadmap/` FLEET v2 pipeline (EPIC/PLAN docs) shaped exactly like the committed **golden sample** under `references/`. (Steps 2, 8)
5. **DESIGN.** The reconciled docs state one truth: whether atelier gates BUILD or cross-cuts it, and the pipeline pauses for atelier at a **defined invocation point** so `done DESIGN` fires on a real boundary. (Step 5)
6. **BUILD.** FOUNDRY drains each PLAN through the 0–9 conveyor. The LEAD selects handlers via a **documented stack-detection table** (signal → handler), so an Ansible item routes to the now-registered `handler-ansible` instead of surprising the user at the missing-handler gate. (Steps 3, 4)
7. **BUILD ⇄ ASSURE ⇄ SECURE — the loop now turns.** On a built item, `/foundry:pr-review` calls `/i2p:lifecycle done ASSURE` on PASS (advancing to SECURE) or `/i2p:lifecycle fail ASSURE` on NEEDS_REVISION/BLOCK. `/security:scan-all` calls `/i2p:lifecycle done SECURE` on PASS or `/i2p:lifecycle fail SECURE` on BLOCK. The statusline `⇄ ×N` increments on every loop-back, and a **failure-recovery callout** tells the operator exactly which report to open, what to fix, and what to re-run. The loop is traversable for the first time. (Steps 1, 9)
8. **PUBLISH → OPERATE.** On all-green, `done SECURE` advances to PUBLISH and onward; OPERATE runs the gate.
9. **OPERATE ↻ DISCOVER — the cycle closes.** `/operate:iterate` writes an `OPPORTUNITY-<slug>.md` whose **path and schema match what DISCOVER consumes**, and `/market-scan` has an explicit ingest step that validates that returned thesis — closing the loop with a shared contract. (Step 10)

At the end, a product that began as one sentence has a roadmap, tested-and-reviewed code, a security verdict, published docs, an operating gate, and a learning loop that feeds the next idea — every transition driven, not narrated.

## Step-by-Step Plan

### Step 1: Wire the BUILD ⇄ ASSURE ⇄ SECURE loop (the dead transitions)
- **Phase:** ASSURE, SECURE, BUILD (the flagship loop)
- **Plugin:** `plugins/foundry/skills/pr-review/SKILL.md`; `plugins/security/skills/scan-all/SKILL.md`
- **What to build:** Add a `## Product lifecycle (by capability)` section to `pr-review/SKILL.md` (mirroring the section every other phase-owning skill has) that calls `/i2p:lifecycle done ASSURE` on a PASS verdict and `/i2p:lifecycle fail ASSURE` on a NEEDS_REVISION/BLOCK verdict. Add the matching `/i2p:lifecycle fail SECURE` call to `scan-all/SKILL.md` on a REVIEW/BLOCK verdict (the `done SECURE` call on PASS already exists). Guard each call "by capability" per the existing degradation pattern.
- **Effort:** S
- **Unblocks:** The entire flagship loop the README/VALUE_FLOW/product-lifecycle advertise — moment 7 of the journey. Without this, the lifecycle stalls at ASSURE forever.
- **Done when:** `grep -rln 'done ASSURE\|fail ASSURE\|fail SECURE'` over `plugins/` (excluding `lifecycle/SKILL.md`) returns the two skill files; a PASS at ASSURE advances the lifecycle to SECURE and a NEEDS_REVISION renders the statusline `⇄ ×1`.

### Step 2: Make `/roadmapper` resolve (DELIVER entry point)
- **Phase:** DELIVER
- **Plugin:** `plugins/foundry/commands/roadmapper.md` (new); reconcile `plugins/foundry/README.md:60`
- **What to build:** Add a thin `plugins/foundry/commands/roadmapper.md` that invokes the existing roadmapper skill, so `/foundry:roadmapper` resolves (the higher-fidelity option given DELIVER's centrality). Then correct `foundry/README.md:60` so it no longer claims roadmapper has "no /command of their own". (If Claude Code already auto-exposes skills as `/<plugin>:<name>`, instead state that convention once at the top of SLASH_COMMANDS and drop the README claim — pick one and make catalog match disk.)
- **Effort:** S
- **Unblocks:** Journey moment 4 — the user types the single command every DELIVER doc tells them to and it works.
- **Done when:** A user can type `/foundry:roadmapper` and the roadmapper skill runs; no DELIVER-phase doc contradicts another on how to invoke it.

### Step 3: Register the orphan handler-ansible
- **Phase:** BUILD
- **Plugin:** `plugins/foundry/skills/builder/SKILL.md` (§8 VALUE_HANDLER_POOL); `plugins/foundry/knowledge/orchestration/agent-roster.md` ("Current handlers")
- **What to build:** Register `handler-ansible` in the §8 pool table and the roster's "Current handlers" list with a spawn-when trigger (e.g. `.yml` playbooks / `roles/` / `ansible.cfg`). Alternatively, delete `plugins/foundry/agents/handler-ansible.md` if Ansible is out of scope — an on-disk-but-unregistered handler is the worst of both worlds.
- **Effort:** S
- **Unblocks:** Journey moment 6 — an Ansible work item routes to its handler instead of falsely PAUSING at the missing-handler gate.
- **Done when:** `grep -li ansible` over `builder/SKILL.md` and `agent-roster.md` returns both files; the §8 table lists `handler-ansible` with a trigger.

### Step 4: Document the stack-detection algorithm (signal → handler table)
- **Phase:** BUILD
- **Plugin:** `plugins/foundry/skills/builder/SKILL.md` (co-located with §8); optionally `plugins/foundry/agents/handler-roadmap-decomposition.md`
- **What to build:** Add a documented stack-detection decision table mapping repo signals to handlers — e.g. `Cargo.toml`+`tauri.conf.json`→`handler-rust-tauri`, `pyproject`+fastapi→`handler-fastapi`, `package.json`+react→`handler-react`, `.github/workflows/`→`handler-github-actions`, `playbooks/`+`roles/`→`handler-ansible`. Either extend the roadmap-decomposition detector beyond its 4 coarse buckets (PYTHON/RUST/TS/JS/UNKNOWN) or explicitly state it is a coarse pre-filter the LEAD refines against this table. Model it on publish's illustrator intent→handler routing table.
- **Effort:** M
- **Unblocks:** Journey moment 6 — handler selection becomes a documented rule, not implicit judgement (the root cause that let the orphan in Step 3 go unreached).
- **Done when:** A reader can trace any repo signal to a specific handler from one co-located table; every §8 handler has a corresponding detection row.

### Step 5: Reconcile the DESIGN-phase ordering
- **Phase:** DESIGN
- **Plugin:** `plugins/i2p/knowledge/product-lifecycle.md`; `plugins/foundry/VALUE_FLOW.md`; `plugins/atelier/skills/mockup/SKILL.md`
- **What to build:** State in one place whether DESIGN is a gate BEFORE the engine builds or a cross-cut DURING build (or both). If both, define exactly when the roadmapper/FLEET pipeline pauses for atelier and how atelier's `done DESIGN` fires before the engine starts draining PLANs. Update product-lifecycle.md (phase ④, before BUILD) and VALUE_FLOW.md (station 6b, cross-cuts IMPLEMENT) to agree, and align atelier's `done DESIGN` trigger to the single defined boundary.
- **Effort:** M
- **Unblocks:** Journey moment 5 — `done DESIGN` fires on a real boundary instead of an undefined one in a FLEET pipeline.
- **Done when:** product-lifecycle.md and VALUE_FLOW.md describe DESIGN's position and ownership identically; atelier's `done DESIGN` trigger names a concrete pipeline boundary.

### Step 6: Define the IDEA-package filesystem schema + ship a worked example
- **Phase:** IDEATE
- **Plugin:** `plugins/ideator/knowledge/ideation/idea-package.md`; `plugins/ideator/examples/` (new directory)
- **What to build:** Add a one-line file manifest to idea-package.md naming each file in the standalone-written package — e.g. `doc/idea/<slug>/{brief.md, smu-seed.md, first-slice.md, handoff.md, dossier.md}` — with each field's home and format. Ship one committed worked example under `plugins/ideator/examples/` so a fresh agent reading a standalone package knows exactly where each field lives. Give the SMU-seed its own schema note (contrast FOUNDRY's full subject-matter-understanding.md template for the expanded SMU).
- **Effort:** M
- **Unblocks:** Journey moment 3 — the standalone IDEATE→DELIVER handoff (the least-specified path) becomes demonstrable, not only contractual.
- **Done when:** idea-package.md names every file in the package; a committed example exists at `plugins/ideator/examples/.../doc/idea/<slug>/` with all named files populated.

### Step 7: Add the raw value-prop entry lane
- **Phase:** DISCOVER / IDEATE (entry)
- **Plugin:** `README.md` (Start-here block); `plugins/i2p/skills/help/SKILL.md`; `plugins/i2p/skills/flow/SKILL.md`; `plugins/discover/skills/market-scan/SKILL.md`
- **What to build:** Add an explicit "I already have an idea/proposition" lane to the README Start-here block and to `/i2p:help` and `/i2p:flow`, routing it to `/ideator:ideate \"...\"` (raw-idea mode). Add a short note to `/market-scan` that it also VALIDATES a user-supplied thesis, not only generates fresh candidates. Optionally have `/ideate` recognise the problem/solution/value triad ("By doing X I propose Y, value Z") and pre-fill the brief's PROBLEM / SUCCESS-METRIC / PRICE-BAND fields.
- **Effort:** M
- **Unblocks:** Journey moments 1–2 — the user holding a raw thesis finds a documented door instead of an unguided fork between meta/browse commands.
- **Done when:** The README Start-here block and `/i2p:help` both show a thesis lane routing to `/ideator:ideate`; `/market-scan` documents thesis-validation mode.

### Step 8: Ship a worked DELIVER golden sample (EPIC/PLAN/.pipeline)
- **Phase:** DELIVER
- **Plugin:** `plugins/foundry/skills/roadmapper/references/` or `plugins/foundry/examples/` (new sample); `README.md` + `docs/SLASH_COMMANDS.md` (DELIVER links)
- **What to build:** Ship at least one worked `EPIC_NNNN.md` / `PLAN_NNNN.md` / `.pipeline.md` golden sample so the DELIVER output is demonstrable, not only specified. State explicitly whether `docs/roadmap/` is meant to exist in the marketplace repo itself or only in consumer projects. Add a one-line link from the DELIVER sections of README and SLASH_COMMANDS to `fleet-pipeline-standard.md` so a new user finds the grammar without spelunking the skill folder.
- **Effort:** M
- **Unblocks:** Journey moment 4 — the central DELIVER→BUILD seam becomes verifiable from an example, not only narration.
- **Done when:** A committed EPIC/PLAN/.pipeline sample exists matching the fleet-pipeline-standard grammar; README and SLASH_COMMANDS DELIVER sections link to it.

### Step 9: Add the operator failure-recovery UX
- **Phase:** ASSURE / SECURE (failure path)
- **Plugin:** `plugins/foundry/README.md`; `plugins/security/README.md`; `plugins/foundry/skills/pr-review/SKILL.md` (non-PASS output); `plugins/security/skills/scan-all/SKILL.md` (non-PASS output)
- **What to build:** Add an operator-facing failure-recovery callout (mirroring the well-specified AWAITING_MERGE prompt block) to the foundry and security READMEs and the pr-review/scan-all non-PASS output: open the report (`PR_REVIEW.md` / `SECURITY-REPORT.md`) → address the named findings in BUILD → re-run `/pr-review` or `/scan-all` → the loop exits only when all three gates are green. Tie the message to the `lifecycle.sh fail` transition wired in Step 1 so UX and state machine agree.
- **Effort:** S
- **Unblocks:** Journey moment 7 — a human operator hitting NEEDS_REVISION/BLOCK knows the concrete next step instead of facing a merge halt with no instruction.
- **Done when:** A non-PASS verdict from `/pr-review` or `/scan-all` prints a recovery procedure naming the report, the fix-in-BUILD step, and the re-run command; the foundry/security READMEs carry the same callout.

### Step 10: Align the OPERATE ↻ DISCOVER re-entry contract
- **Phase:** OPERATE ↻ DISCOVER (cycle close)
- **Plugin:** `plugins/operate/skills/iterate/SKILL.md` + operate-canon (or a shared knowledge doc); `plugins/discover/skills/market-scan/SKILL.md`
- **What to build:** Define the `OPPORTUNITY-<slug>.md` schema in ONE place and align its path + fields with discover's `doc/opportunities/<slug>.md` opportunity-brief shape, so the re-entry artifact is literally the same contract DISCOVER already consumes. Add an explicit ingest step to `/market-scan` ("if handed an `OPPORTUNITY-*.md` from `/iterate`, validate that thesis rather than proposing fresh") and ship one worked production-learning → new-opportunity round-trip example.
- **Effort:** M
- **Unblocks:** Journey moment 9 — the "↻ re-enters DISCOVER" promise gets a shared data handoff, closing the cycle.
- **Done when:** `/iterate`'s output path and schema match what `/market-scan` documents ingesting; `/market-scan` has an explicit OPPORTUNITY-file ingest step; one round-trip example is committed.

### Step 11: Fix the i2p:review broken delegation + mermaid-specialist naming drift
- **Phase:** ASSURE (cross-plugin review) / documentation
- **Plugin:** `plugins/i2p/skills/review/SKILL.md` (lines 7, 14, 43); `plugins/foundry/VALUE_FLOW.md`; `plugins/foundry/knowledge/glossary.md`; `plugins/ideator/knowledge/ideation/idea-package.md`
- **What to build:** Correct the i2p:review DOCS-lens delegation to `/publish:design-reviewer` (visual/layout gate) or `/publish:document-review` (prose) — whichever lens is intended — to match the actual publish surface (nothing named `design-review` exists). Global-replace `mermaid-specialist` → `handler-mermaid` in VALUE_FLOW.md, glossary.md, and idea-package.md (the publish inspector already identifies the correct name).
- **Effort:** S
- **Unblocks:** A working cross-plugin review (the DOCS lens stops invoking a non-existent command) and accurate capability naming across four live docs.
- **Done when:** `/i2p:review`'s DOCS lens invokes a publish command that resolves; `grep -rl mermaid-specialist plugins/` returns nothing.

### Step 12: Fix the retired-flow drift in glossary + product-lifecycle
- **Phase:** Documentation (canonical name source)
- **Plugin:** `plugins/foundry/knowledge/glossary.md:89`; `plugins/i2p/knowledge/product-lifecycle.md:87`
- **What to build:** In glossary.md:89 replace `flow` with `i2p` in the eight-specialist list and re-map DELIVER ownership to `foundry:roadmapper` + the external FLEET engine (drop "the roadmap board + intake" surface). Rewrite product-lifecycle.md:87 to name DELIVER's owner as `foundry:roadmapper` (authoring) + external FLEET continuous-delivery engine (draining). These are the last two live stale `flow` references.
- **Effort:** S
- **Unblocks:** A trustworthy glossary (cited by CLAUDE.md as the canonical name-disambiguation source) so the drift stops propagating.
- **Done when:** `grep -rn '\bflow\b' glossary.md product-lifecycle.md` returns only correct historical/retirement references; the glossary names `i2p` and omits `flow` from the live-owner list.

### Step 13: Add the lifecycle-driver CI guard (KAIZEN)
- **Phase:** Self-improvement / governance
- **Plugin:** `scripts/verify-prereqs.sh` (or a new `foundry:inspect` lens)
- **What to build:** Add a check that, for each row in the lifecycle advance table (`lifecycle/SKILL.md:77-86`), greps the named owner plugin for a `done <PHASE>` call (and, for ASSURE/SECURE, a `fail <PHASE>` call) and fails if absent — turning the dead-wiring class of bug (rank 1) into a deterministic gate. Extend it to assert every `done <PHASE>` has exactly one caller.
- **Effort:** M
- **Unblocks:** Permanent prevention — the class of bug that left the flagship loop unwired can never silently recur.
- **Done when:** The check fails the build if any advance-table row lacks its driver call; it passes once Step 1 is complete and would have caught the original defect.

### Step 14: Cosmetic / consistency cleanups (LOW)
- **Phase:** Documentation polish
- **Plugin:** `plugins/foundry/knowledge/protocols/handler-annotation.md` (optional rename); `VALUE_FLOW.md` + `product-lifecycle.md` (one clarifying sentence); `README.md` + `docs/SLASH_COMMANDS.md` + i2p front-door skills (citation form)
- **What to build:** (a) Optionally rename `handler-annotation.md` → `annotation-protocol.md` to remove the collision with the `handler-` agent prefix (no functional fix needed). (b) Add one sentence to VALUE_FLOW/product-lifecycle clarifying the cross-phase loop is realised by composition (`/pr-review` folds in `/scan-all` + `/i2p:lifecycle fail`) and is distinct from the lifecycle-orchestrator's internal step-0..9 item loop, so readers audit the right artifact. (c) Pick one canonical citation form (namespaced `/<plugin>:<name>`) and apply it consistently across README, SLASH_COMMANDS, and every i2p front-door skill, noting the short alias once.
- **Effort:** S
- **Unblocks:** A new user's first command stops being a coin-flip; auditors audit the right loop artifact.
- **Done when:** Citation form is consistent across the front-door surfaces; the loop-realisation sentence is present; the optional rename is applied or explicitly deferred.

## What This Does NOT Cover

- **Building the missing mainstream-stack handlers** (Go, Java/Kotlin, C#/.NET, Ruby, PHP, Swift/iOS, Android, Elixir, Docker, Terraform, Next.js, Vue, Svelte, DB-migration — rank 14). The missing-handler gate already handles the absent case well; this plan only makes coverage **transparent** (a documented "stacks we handle natively today" list belongs in Step 4). Actually authoring new handlers is a separate, larger body of work prioritised by demand (Go and a generic DB-migration handler first, per the audit).
- **Building a user-facing handler-selection override** (rank 15). This plan recommends at minimum *documenting* the current posture (handler selection is LEAD-owned, not user-overridable); designing and shipping an override mechanism is deferred as a feature, not a wiring fix.
- **Re-architecting any sound subsystem.** The BUILD engine, the orchestration hierarchy, the lifecycle state machine (`lifecycle.sh`), the missing-handler gate, the context-sentinel/handoff layer, and the DELIVER→FLEET contract are all confirmed strong and are explicitly **not** touched except where a thin wire or doc reconciliation is added. No abstraction is being redesigned.
- **Token-fairness / scheduler work.** The token-aware scheduler now lives in the standalone `token-fairness` marketplace and is out of scope here.
- **External FLEET-engine internals.** This plan covers the marketplace's side of the DELIVER→FLEET handoff (the contract, the command, the golden sample). The external FLEET continuous-delivery engine that drains the pipeline is a separate system and is not modified.
- **New lifecycle phases or plugins.** The nine-phase model is accepted as-is; this plan completes its wiring rather than extending it.
