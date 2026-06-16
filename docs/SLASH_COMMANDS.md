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

The marketplace carries software along one lifecycle. Each phase has an owning plugin; the two
entry points sit above the spine.

| | Phase | Plugin | Jump |
|---|---|---|---|
| **▸** | *entry* — front door | `i2p` | [↓](#i2p--front-door) |
| **▸** | *entry* — session greeter | `concierge` | [↓](#concierge--session-greeter) |
| **1** | DISCOVER | `market-scanner` | [↓](#market-scanner--discover) |
| **2** | IDEATE | `ideator` | [↓](#ideator--ideate) |
| **3** | DESIGN | `atelier` | [↓](#atelier--design) |
| **4** | BUILD · ASSURE | `foundry` | [↓](#foundry--build--assure) |
| **5** | SECURE | `sentinel` | [↓](#sentinel--secure) |
| **6** | PUBLISH | `pressroom` | [↓](#pressroom--publish) |
| **7** | OPERATE ↻ | `mission-control` | [↓](#mission-control--operate) |

## Common to every plugin

Three verbs repeat across the marketplace and are **not** relisted in each table below:

| Command | What it does |
|---|---|
| `/<plugin>:check` | Verify that plugin's external tools are installed — a ✓/✗ table (`--strict` to fail) |
| `/<plugin>:inspect` | Audit the plugin itself for drift, gaps, and duplication → a ranked report |
| `/<plugin>:self-improve` | Fold feedback back into the plugin and split over-broad parts |

Every plugin ships `check` and `inspect`; all except `concierge` ship `self-improve`. (`i2p`
spells its own as `/i2p:i2p-check` — see its table.)

---

## i2p — front door

The marketplace's map and consolidated front desk.

| Command | What it does |
|---|---|
| `/i2p:i2p-help` | Browse the powers you have now, grouped by lifecycle phase |
| `/i2p:i2p-flow` | Show the value flow and the next command at each stage |
| `/i2p:i2p-lifecycle` `[init·status·done·advance·set]` | Start or report the 8-phase product lifecycle |
| `/i2p:i2p-check` | Consolidated readiness across every installed plugin |
| `/i2p:i2p-review` | Cross-plugin adversarial review → one PASS / NEEDS_REVISION / BLOCK verdict |
| `/i2p:inspect` · `/i2p:self-improve` | Audit / improve the front door itself |

## concierge — session greeter

The conversational welcome and the status line.

| Command | What it does |
|---|---|
| `/concierge:define-welcome` | Author this repo's welcome experience and routing lanes |
| `/concierge:statusline` `[off]` | Turn the idea-to-production status line on (or off) |
| `/concierge:statusline-widgets` | Lay out the status line's line-2 widgets to fit your terminal |

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

## atelier — DESIGN

Design the interface before it's built.

| Command | What it does |
|---|---|
| `/atelier:mockup` | Design a reviewed UI mockup, wireframe, or user-flow — not a first draft |
| `/atelier:ui-review` | Adversarially review a running SPA or screenshot → a scored, prioritised critique |

## foundry — BUILD · ASSURE

The production cycle: roadmap → product, with the quality gates.

| Command | What it does |
|---|---|
| `/foundry:foundry` `[scaffold·gate·deploy·verify]` | Run the production cycle — drive roadmap items idea→product |
| `/foundry:vertical-slice` | Cut and drive one thin, end-to-end, shippable increment |
| `/foundry:roadmapper` | Manage `ROADMAP.md` — read it, add features, drive them through stages |
| `/foundry:phase-sensor` | Detect each in-progress feature's phase and install the next skill |
| `/foundry:coverage-loop` | Loop until every behaviour is pinned by a test |
| `/foundry:pr-review` `[PR#·diff]` | Adversarial PR/diff review → PASS / NEEDS_REVISION / BLOCK |
| `/foundry:code-quality` | Deep analysis across Clean Code, SOLID, DDD, 12-Factor, … |
| `/foundry:frontend` | Build information-rich, data-bound web apps in vanilla JS |
| `/foundry:rust-webapp-rollout` | One-shot full-Rust web app + serverless API, empty dir → production |
| `/foundry:scorecard` | Emit measured scorecards for the product and the marketplace |
| `/foundry:prerequisites` `[--fix]` | Generate a project-local `PREREQUISITES.md` |

> foundry also ships internal conveyor skills — `builder`, `lifecycle-states`, `handoff-protocol`,
> `reviewer-gate`, `value-station-handoff`, `development-system-core`, `founder-method` — that run
> automatically inside `/foundry:foundry`. They are building blocks, not meant for direct use.

## sentinel — SECURE

The pre-release security audits.

| Command | What it does |
|---|---|
| `/sentinel:security-gate` `[full·quick·path]` | Run all three audits → SECURITY-REPORT.md with a PASS / REVIEW / BLOCK verdict |
| `/sentinel:dependency-audit` | Audit dependencies — CVEs, unpinned versions, abandoned packages, typosquats |
| `/sentinel:secret-scan` `[tree·git·history]` | Scan tree, git history, and artefacts for committed secrets |
| `/sentinel:pii-audit` | Audit for PII across data, source, git history, and frontend |

## pressroom — PUBLISH

Turn the work into articles, diagrams, and print-quality documents.

| Command | What it does |
|---|---|
| `/pressroom:publish` `[src] [markdown·pdf·docx·diagrams]` | The front door — article, diagrams, or print PDF |
| `/pressroom:writer` | Write an article, post, narrative, retrospective, or release notes |
| `/pressroom:illustrate` `[docs·this·file]` | Find the highest-impact figure-sites and render each (skill: `illustrator`) |
| `/pressroom:diagram-studio` | Author Graphviz/Mermaid diagrams → SVG, PNG, or PDF for any target |
| `/pressroom:mermaid-specialist` | Author and render across Mermaid's full diagram taxonomy |
| `/pressroom:rich-pdf-with-diagrams` | Produce a print-quality PDF with embedded diagrams |
| `/pressroom:design-reviewer` | Adversarially review the visual design of a rendered doc or chart |
| `/pressroom:model-survey` · `/pressroom:craft-study` | Survey image models / discover image-craft techniques on the ComfyUI backend (loop-driven) |

## mission-control — OPERATE ↻

Keep the live product alive and improving.

| Command | What it does |
|---|---|
| `/mission-control:operate-gate` `[readiness·health·path]` | Go-live readiness + steady-state health → READY / WATCH / NOT-READY |
| `/mission-control:observability` | Four golden signals, three pillars, SLI→SLO→alert definitions |
| `/mission-control:incident` `[declare·runbook·postmortem]` | Declare severity & roles, mitigate, then runbook + blameless postmortem |
| `/mission-control:maintain` | Upkeep cadence — deps, CVE patching, cert/secret rotation, tech debt |
| `/mission-control:iterate` | Turn a production signal into a new opportunity that re-enters DISCOVER |
| `/mission-control:flow` `[ping·status·start·stop·url·build]` | The roadmap flow board + flow-server MCP control |
| `/mission-control:flow-setup` | Finish the flow-server MCP one-time setup (pre-cache, approve, verify) |
| `/mission-control:wiki-publisher` | Publish per-item docs to the origin's GitHub wiki (opt-in) |

---

## Appendix — MCP servers

The marketplace ships four MCP servers. These expose **tools** (and one first-party board), **not**
slash commands — there are no `/mcp__…` commands to type.

| Server | Shipped by | What it provides |
|---|---|---|
| `context7` | foundry | Fetch current documentation for a library, framework, SDK, or CLI |
| `fetch` | ideator, market-scanner | Retrieve and read web page content |
| `playwright` | atelier, foundry | Drive a real browser — navigate, screenshot, accessibility snapshot |
| `flow-server` | mission-control | The roadmap flow board — a first-party, pinned Rust binary |

The **flow-server** verbs are tools the plugin calls for you (reached through
`/mission-control:flow`, never typed directly): `render_roadmap`, `list_items`, `get_item`,
`post_status`, `set_wait_go`, `append_spend`, `set_item_model`, `validate_connection`,
`mutate_connection`, `annotate`, `request_rewrite`, `append_sysmsg`, `list_events`, `ping`.

---

*Source of truth: this catalog is hand-kept from `plugins/*/commands/` and `plugins/*/skills/`.
When a command is added, renamed, or retired there, update this file. Agent-internal skills are
omitted by design.*
