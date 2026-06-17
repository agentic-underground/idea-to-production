# Slash commands

Every slash command the **idea-to-production** marketplace makes available, across its nine
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
| **1** | DISCOVER | `market-scanner` | [↓](#market-scanner--discover) |
| **2** | IDEATE | `ideator` | [↓](#ideator--ideate) |
| **3** | DELIVER | `flow` (+ `foundry:roadmapper`) | [↓](#flow--deliver) |
| **4** | DESIGN | `atelier` | [↓](#atelier--design) |
| **5** | BUILD ⇄ ASSURE | `foundry` | [↓](#foundry--build--assure) |
| **6** | SECURE | `security` | [↓](#security--secure) |
| **7** | PUBLISH | `publish` | [↓](#publish--publish) |
| **8** | OPERATE ↻ | `operate` | [↓](#operate--operate-) |

**DELIVER** is the moment IDEAS are formally moved into the roadmap — written into EARS and
features, then analysed and decomposed into atomic work items (or dependency chains: "b needs a",
"z needs y needs x"). `/flow:pull` is the intuitive verb that carries the next backlog item into
build; `foundry:roadmapper` does the intake → EARS/feature → decomposition.

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

## market-scanner — DISCOVER

Find something worth building.

| Command | What it does |
|---|---|
| `/market-scanner:market-scan` | Adversarial dialogue that proposes, scores, and kills ideas until one survives |
| `/market-scanner:discovery-goal` | Set or refine the standing goal scans run over (niche, edge, price band) |

## ideator — IDEATE

Turn a validated opportunity into a build-ready idea.

| Command | What it does |
|---|---|
| `/ideator:ideate` | Refine an idea into a build-ready IDEA package, then hand off to foundry |
| `/ideator:name` | Coin a distinctive, availability-checked product name (skill: `name-search`) |

## flow — DELIVER

Move ideas into the roadmap and carry them toward build. The DELIVER plugin; ships the `flow-mcp`
roadmap MCP binary.

| Command | What it does |
|---|---|
| `/flow:pull` | Pull the next backlog item and drive it to a delivered increment (wraps foundry's builder) |
| `/flow:flow` `[carry·report·ping]` | Carry an item to its next lane (who/what/cost), or report the flow state |
| `/flow:flow-setup` | Finish the `flow-mcp` one-time setup — pre-cache the binary, approve, verify |

The roadmap intake half of DELIVER — turning a captured idea into EARS specs, `.feature` files, and
a dependency-ordered decomposition — is `/foundry:roadmapper` (listed under foundry below).

## atelier — DESIGN

Design the interface before it's built.

| Command | What it does |
|---|---|
| `/atelier:mockup` | Design a reviewed UI mockup, wireframe, or user-flow — not a first draft |
| `/atelier:ui-review` | Adversarially review a running SPA or screenshot → a scored, prioritised critique |

## foundry — BUILD ⇄ ASSURE

The production cycle: roadmap → product, with the quality gates. (BUILD ⇄ ASSURE ⇄ SECURE is a
loop — a failed gate re-enters BUILD.)

| Command | What it does |
|---|---|
| `/foundry:foundry` `[scaffold·gate·deploy·verify]` | The internal BUILD engine — drives roadmap items idea→product (the intuitive verb is `/flow:pull`, which wraps it) |
| `/foundry:roadmapper` | Manage `ROADMAP.md` / `.i2p/roadmap/` — capture, write EARS specs, decompose, drive through stages (the DELIVER intake) |
| `/foundry:vertical-slice` | Cut and drive one thin, end-to-end, shippable increment |
| `/foundry:phase-sensor` | Detect each in-progress feature's phase and install the next skill |
| `/foundry:coverage-loop` | Loop until every behaviour is pinned by a test |
| `/foundry:pr-review` `[PR#·diff]` | Adversarial PR/diff review → PASS / NEEDS_REVISION / BLOCK |
| `/foundry:code-quality` | Deep analysis across Clean Code, SOLID, DDD, 12-Factor, … |
| `/foundry:frontend` | Build information-rich, data-bound web apps in vanilla JS |
| `/foundry:rust-webapp-rollout` | One-shot full-Rust web app + serverless API, empty dir → production |
| `/foundry:scorecard` | Emit measured scorecards for the product and the marketplace |
| `/foundry:prerequisites` `[--fix]` | Generate a project-local `PREREQUISITES.md` |

*foundry also ships internal conveyor skills — `builder`, `lifecycle-states`, `handoff-protocol`,
`reviewer-gate`, `value-station-handoff`, `development-system-core`, `founder-method` — that run
automatically inside `/foundry:foundry`. They are building blocks, not meant for direct use.*

## security — SECURE

The pre-release security audits.

| Command | What it does |
|---|---|
| `/security:scan-all` `[full·quick·path]` | Run all the audits → SECURITY-REPORT.md with a PASS / REVIEW / BLOCK verdict |
| `/security:scan-dependencies` | Audit dependencies — CVEs, unpinned versions, abandoned packages, typosquats |
| `/security:scan-for-secrets` `[tree·git·history]` | Scan tree, git history, and artefacts for committed secrets |
| `/security:scan-for-pii` | Audit for PII across data, source, git history, and frontend |

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

The roadmap **flow board** and its MCP control moved to the `flow` plugin (DELIVER) — see
`/flow:flow` and `/flow:flow-setup` above.

---

## Appendix — MCP servers

The marketplace ships four MCP servers. These expose **tools**, **not** slash commands — there are
no `/mcp__…` commands to type.

| Server | Shipped by | What it provides |
|---|---|---|
| `context7` | foundry | Fetch current documentation for a library, framework, SDK, or CLI |
| `fetch` | ideator, market-scanner | Retrieve and read web page content |
| `playwright` | atelier, foundry | Drive a real browser — navigate, screenshot, accessibility snapshot |
| `flow-mcp` | flow | The roadmap deterministic layer — local CPU compute over `.i2p/roadmap/` (no model reasoning over its data) |

The **flow-mcp** verbs are tools the plugin calls for you (reached through `/flow:flow` and
`/flow:pull`, never typed directly): `render_roadmap`, `list_items`, `get_item`, `post_status`,
`set_wait_go`, `append_spend`, `set_item_model`, `validate_connection`, `mutate_connection`,
`annotate`, `request_rewrite`, `append_sysmsg`, `list_events`, `ping`. `render_roadmap` answers
"what's on the roadmap" by local compute at ~0 tokens.

---

*Source of truth: this catalog is hand-kept from `plugins/*/commands/` and `plugins/*/skills/`.
When a command is added, renamed, or retired there, update this file. Agent-internal skills are
omitted by design.*
</content>
</invoke>
