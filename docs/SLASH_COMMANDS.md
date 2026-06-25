# Slash commands

Every slash command the **idea-to-production** marketplace makes available, across its eight
plugins. In Claude Code both a plugin's `commands/` and its user-facing `skills/` are typed the
same way — `/<plugin>:<name>` — so they are listed together here. Bracketed `[a·b·c]` after a
command shows its common arguments; most also accept free-form scope text.

> **This file is a feedback surface.** It is plain, git-tracked markdown — edit a row, strike a
> command, or drop a `> note:` inline and **commit**. Your change shows up in `git diff`/`git log`,
> which is how you give feedback on the idea-to-production "API"; an agent reads it back from there.
> For the full detail behind any entry, open its source under `plugins/<plugin>/commands/` or
> `plugins/<plugin>/skills/`.

## Quick map

The marketplace carries software along one lifecycle. Each phase has an owning plugin; the front
door (`i2p`) — which also greets whoever opens a repo — sits above the spine. **BUILD ⇄ ASSURE ⇄
SECURE is a loop**: a failed quality or security gate re-enters BUILD, and the three only release
together once all are satisfied and the roadmap item is complete.

| | Phase | Plugin | Jump |
|---|---|---|---|
| **▸** | *front door* (+ session greeter) | `i2p` | [↓](#i2p--front-door) |
| **1** | DISCOVER | `discover` | [↓](#discover--discover) |
| **2** | IDEATE | `ideate` | [↓](#ideate--ideate) |
| **3** | DELIVER | `deliver:roadmapper` (+ external FLEET engine) | [↓](#deliverroadmapper--deliver) |
| **4** | DESIGN | `design` | [↓](#design--design) |
| **5** | BUILD ⇄ ASSURE | `deliver` | [↓](#deliver--build--assure) |
| **6** | SECURE | `secure` | [↓](#secure--secure) |
| **7** | PUBLISH | `publish` | [↓](#publish--publish) |
| **8** | OPERATE ↻ | `operate` | [↓](#operate--operate-) |

**DELIVER** is the moment IDEAS are formally moved into the roadmap — the **FLEET v2 pipeline**
(`docs/roadmap/` EPIC/PLAN docs), written into EARS and features and decomposed into dependency-ordered
vertical slices. **`/roadmapper`** authors that pipeline (intake → EARS/feature → decomposition, modelled
as a value task); the external **FLEET continuous-delivery engine** then drains it, building each slice
through DELIVER's PLAN-scope entry.

> **Citation form.** Commands are listed in their canonical `/<plugin>:<skill>` form. Short aliases
> (e.g. `/ideate`, `/market-scan`) also work when unambiguous.

## Common to every plugin

Three verbs repeat across the marketplace and are **not** relisted in each table below:

| Command | What it does |
|---|---|
| `/<plugin>:check` | Verify that plugin's external tools are installed — a ✓/✗ table (`--strict` to fail) |
| `/<plugin>:inspect` | Audit the plugin itself for drift, gaps, and duplication → a ranked report |
| `/<plugin>:self-improve` | Fold feedback back into the plugin and split over-broad parts |

Every plugin ships `check`, `inspect`, and `self-improve` (consistently named — `i2p` spells its
own consolidated readiness as `/i2p:check`).

---

## i2p — front door

The marketplace's map and consolidated front desk — and the session greeter (welcome + status
line), folded in so the whole front door lives under one mnemonic.

| Command | What it does |
|---|---|
| `/i2p:help` | Browse the powers you have now, grouped by lifecycle phase |
| `/i2p:flow` | Show the value flow and the next command at each stage |
| `/i2p:lifecycle` `[init·status·done·advance·set]` | Start or report the 9-phase product lifecycle |
| `/i2p:check` | Consolidated readiness across every installed plugin |
| `/i2p:review` | Cross-plugin adversarial review → one PASS / NEEDS_REVISION / BLOCK verdict |
| `/i2p:define-welcome` | Author this repo's welcome experience and routing lanes |
| `/i2p:statusline` `[off]` | Turn the idea-to-production status line on (or off) |
| `/i2p:statusline-widgets` | Lay out the status line's line-2 widgets to fit your terminal |

## discover — DISCOVER

Find something worth building.

| Command | What it does |
|---|---|
| `/discover:market-scan` | Adversarial dialogue that proposes, scores, and kills ideas until one survives |
| `/discover:discovery-goal` | Set or refine the standing goal scans run over (niche, edge, price band) |

## ideate — IDEATE

Turn a validated opportunity into a build-ready idea.

| Command | What it does |
|---|---|
| `/ideate:ideate` | Refine an idea into a build-ready IDEA package, then hand off to deliver |
| `/ideate:name` | Coin a distinctive, availability-checked product name (skill: `name-search`) |

## deliver:roadmapper — DELIVER

Move ideas into the roadmap and let the pipeline carry them toward build. DELIVER is owned by
**`/roadmapper`** (which authors the FLEET v2 `docs/roadmap/` pipeline) plus the **external FLEET
continuous-delivery engine** (a separate marketplace plugin — `/pipeline:run`, `/pipeline:status`,
`/pipeline:unattended` — that drains the pipeline and builds each slice through DELIVER's PLAN-scope
entry).

| Command | What it does |
|---|---|
| `/roadmapper` | Author / refine the v2 pipeline: capture an idea → EARS/feature → dependency-ordered EPIC/PLAN decomposition (a value task); a GO hook kicks the FLEET engine off for the resolved item |
| `/pipeline:status` *(external FLEET plugin)* | Read "what's on the roadmap" from the deterministic pipeline surface |
| `/pipeline:run` *(external FLEET plugin)* | Start/resume the engine draining the pipeline continuously |

The EPIC/PLAN/`.pipeline.md` grammar the engine parses (the DELIVER → FLEET handoff contract) is
vendored at
[`../plugins/deliver/skills/roadmapper/references/fleet-pipeline-standard.md`](../plugins/deliver/skills/roadmapper/references/fleet-pipeline-standard.md),
with a worked golden sample in
[`../plugins/deliver/skills/roadmapper/references/examples/`](../plugins/deliver/skills/roadmapper/references/examples/).

*(The legacy in-repo `flow` plugin — `/flow:pull`, `/flow:flow`, the `flow-mcp` server — has been
retired; the FLEET engine supersedes it.)*

## design — DESIGN

Design the interface before it's built.

| Command | What it does |
|---|---|
| `/design:mockup` | Design a reviewed UI mockup, wireframe, or user-flow — not a first draft |
| `/design:ui-review` | Adversarially review a running SPA or screenshot → a scored, prioritised critique |

## deliver — BUILD ⇄ ASSURE

The production cycle: roadmap → product, with the quality gates. (BUILD ⇄ ASSURE ⇄ SECURE is a
loop — a failed gate re-enters BUILD.)

| Command | What it does |
|---|---|
| `/deliver:build` `[scaffold·gate·deploy·verify]` | The standalone BUILD cycle — drives a whole `ROADMAP.md` idea→product. For a v2 pipeline, day-to-day delivery is the external FLEET engine draining a `/roadmapper`-authored `docs/roadmap/` pipeline (engine → DELIVER PLAN-scope per slice); this command remains for a one-off cycle or estimate-only run |
| `/deliver:roadmapper` | Manage `ROADMAP.md` — capture, write EARS specs, decompose, drive through stages (the DELIVER intake) |
| `/deliver:vertical-slice` | Cut and drive one thin, end-to-end, shippable increment |
| `/deliver:phase-sensor` | Detect each in-progress feature's phase and install the next skill |
| `/deliver:coverage-loop` | Loop until every behaviour is pinned by a test |
| `/deliver:pr-review` `[PR#·diff]` | Adversarial PR/diff review → PASS / NEEDS_REVISION / BLOCK |
| `/deliver:code-quality` | Deep analysis across Clean Code, SOLID, DDD, 12-Factor, … |
| `/deliver:frontend` | Build information-rich, data-bound web apps in vanilla JS |
| `/deliver:rust-webapp-rollout` | One-shot full-Rust web app + serverless API, empty dir → production |
| `/deliver:scorecard` | Emit measured scorecards for the product and the marketplace |
| `/deliver:prerequisites` `[--fix]` | Generate a project-local `PREREQUISITES.md` |

*deliver also ships internal conveyor skills — `builder`, `lifecycle-states`, `handoff-protocol`,
`reviewer-gate`, `value-station-handoff`, `development-system-core`, `founder-method` — that run
automatically inside `/deliver:build`. They are building blocks, not meant for direct use.*

## secure — SECURE

The pre-release security audits.

| Command | What it does |
|---|---|
| `/secure:scan-all` `[full·quick·path]` | Run all the audits → SECURITY-REPORT.md with a PASS / REVIEW / BLOCK verdict |
| `/secure:scan-dependencies` | Audit dependencies — CVEs, unpinned versions, abandoned packages, typosquats |
| `/secure:scan-for-secrets` `[tree·git·history]` | Scan tree, git history, and artefacts for committed secrets |
| `/secure:scan-for-pii` | Audit for PII across data, source, git history, and frontend |

## publish — PUBLISH

Turn the work into articles, diagrams, and print-quality documents — a cross-cutting concern that
strides across marketing and delivery.

| Command | What it does |
|---|---|
| `/publish:publish` `[src] [markdown·pdf·docx·diagrams]` | The front door — article, diagrams, or print PDF |
| `/publish:illustrate` `[docs·this·file]` | Find the highest-impact figure-sites and render each (skill: `illustrator`) |
| `/publish:document-review` `[file·this]` | Adversarially review a document's PROSE — the copy reviewer (peer to design-review) |
| `/publish:writer` | Write an article, post, narrative, retrospective, or release notes |
| `/publish:diagram-studio` | Author Graphviz/Mermaid diagrams → SVG, PNG, or PDF for any target |
| `/publish:design-reviewer` | Adversarially review the visual design of a rendered doc or chart |
| `/publish:rich-pdf-with-diagrams` | Produce a print-quality PDF with embedded diagrams |
| `/publish:model-survey` · `/publish:craft-study` | Survey image models / discover image-craft techniques on the ComfyUI backend (loop-driven) |

Diagram rendering across Mermaid's full taxonomy is handled by an internal value-handler (the
`handler-mermaid` agent the illustrator/diagram pipeline spawns), not a user-facing slash command.

## operate — OPERATE ↻

Keep the live product alive and improving.

| Command | What it does |
|---|---|
| `/operate:operate-gate` `[readiness·health·path]` | Go-live readiness + steady-state health → READY / WATCH / NOT-READY |
| `/operate:observability` | Four golden signals, three pillars, SLI→SLO→alert definitions |
| `/operate:incident` `[declare·runbook·postmortem]` | Declare severity & roles, mitigate, then runbook + blameless postmortem |
| `/operate:maintain` | Upkeep cadence — deps, CVE patching, cert/secret rotation, tech debt |
| `/operate:iterate` | Turn a production signal into a new opportunity that re-enters DISCOVER |
| `/operate:gemba` | Capture a learning at the workface, route it by identity, raise a tracked feedback issue |
| `/operate:wiki-publisher` | Publish per-item docs to the origin's GitHub wiki (opt-in) |

The roadmap itself is the **FLEET v2 pipeline** (`docs/roadmap/`), authored by `/roadmapper` (DELIVER)
and drained by the external FLEET continuous-delivery engine — see the deliver:roadmapper section above.

---

## Appendix — MCP servers

The marketplace ships two MCP servers. These expose **tools**, **not** slash commands — there are
no `/mcp__…` commands to type.

| Server | Shipped by | What it provides |
|---|---|---|
| `context7` | deliver | Fetch current documentation for a library, framework, SDK, or CLI |
| `fetch` | ideate, discover | Retrieve and read web page content |

Browser driving (navigate, screenshot, accessibility snapshot — used by design and the deliver web
handlers) is **not** shipped: per the ONE BROWSER cutover the marketplace uses the **host-provided
`chrome-devtools`** MCP, pointed at the system Chromium, and bundles no browser server of its own.

The roadmap deterministic layer ("what's on the roadmap" at ~0 LLM tokens) is now provided by the
**external FLEET `pipeline` plugin** (`/pipeline:status`, `pipeline-cron.sh`) over the v2
`docs/roadmap/` pipeline — the in-repo `flow-mcp` server that previously served it has been retired.

---

*Source of truth: this catalog is hand-kept from `plugins/*/commands/` and `plugins/*/skills/`.
When a command is added, renamed, or retired there, update this file. Agent-internal skills are
omitted by design.*
</content>
</invoke>
