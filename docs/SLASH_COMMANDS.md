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
>
> I want to merge the i2p and concierge together into "i2p" it's quicker
> more simplified to remember the mnemonic "i2p"
> the "front door greeting" etc are just 'things that happen' we don't need
> a special fancy product name for it
>

| **1** | DISCOVER | `market-scanner` | [↓](#market-scanner--discover) |
| **2** | IDEATE | `ideator` | [↓](#ideator--ideate) |

> **3** DELIVER: delivery is the moment where IDEAS are formally moved into the roadmap
> the act of moving IDEAS into the roadmap is where these ideas are built into 
> EARS and FEATURES, and the work is analysed and decomposed into atomic items of work
> (or dependent value-chains of work items - "b needs a" or "z needs y needs x" etc)
> SO: this is all DELIVERY - each of these sub-items is a part of the DELIVERY
> stage
| **x** | DESIGN | `atelier` | [↓](#atelier--design) |
| **x** | BUILD · ASSURE | `foundry` | [↓](#foundry--build--assure) |
> split BUILD and ASSURE
| **x** | SECURE | `sentinel` | [↓](#sentinel--secure) |
> BUILD / ASSURE / SECURE are a looping feedback mechanism
> which continues to feed back on itself until all three
> stages are "satisfied" and the roadmap items are complete

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


> change it to /i2p:check because consistency is mandated
> also, what of the AUTOMATED "encounter issue, write-back learnings"
> self-improvement? (e.g. KAIZEN.md et-al) is this happening?
> I see, from time to time, value-handlers encountering problems
> but they don't make moves to self-improve like I expect they ought
> DIRECTIVE: investigate the self-improvement / learning mechanisms
> and make sure we have autonomous self-improvement built in

---

> MERGE i2p and concierge

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

> retire the "concierge" concept

The conversational welcome and the status line.

| Command | What it does |
|---|---|
| `/concierge:define-welcome` | Author this repo's welcome experience and routing lanes |
| `/concierge:statusline` `[off]` | Turn the idea-to-production status line on (or off) |
| `/concierge:statusline-widgets` | Lay out the status line's line-2 widgets to fit your terminal |

> MERGE i2p and concierge


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

> FOUNDRY to be moved to FLOW
> 

## foundry — BUILD · ASSURE

The production cycle: roadmap → product, with the quality gates.

| Command | What it does |
|---|---|
> "/foundry:foundry" is non-sensical and doesn't come to mind when the user is 
> thinking about driving the flow system: "I want to pull from the backlog" does not
> translate to "foundry:foundry (something)" 
> and what are the optional arguments? they don't look like the kinds of verbs
> that drive value, or the production of value ... 
> "/flow pull" is more intuitive
> DIRECTIVE: re-examine the meanings of the "foundry" slash-commands and what they
> claim to be "doing" ... which ones are user-facing versus agent-facing
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


> SENTINEL - retire this "salesy" name. 
> this should become "/security"

## sentinel — SECURE

The pre-release security audits.

| Command | What it does |
|---|---|
> rename "security-gate" to "scan-all"
| `/sentinel:security-gate` `[full·quick·path]` | Run all three audits → SECURITY-REPORT.md with a PASS / REVIEW / BLOCK verdict |

> rename "dependency-audit" to "scan-dependencies"
| `/sentinel:dependency-audit` | Audit dependencies — CVEs, unpinned versions, abandoned packages, typosquats |

> rename "secret-scan" to "scan-for-secrets"
| `/sentinel:secret-scan` `[tree·git·history]` | Scan tree, git history, and artefacts for committed secrets |
> rename "pii-audit" to "scan-for-pii"
| `/sentinel:pii-audit` | Audit for PII across data, source, git history, and frontend |


> pressroom is another "salesy" name
> but it's pragmatic too. recommend alternative names
> pressroom is a cross-cutting concern that strides across
> marketing and delivery
## pressroom — PUBLISH

Turn the work into articles, diagrams, and print-quality documents.

| Command | What it does |
|---|---|
| `/pressroom:publish` `[src] [markdown·pdf·docx·diagrams]` | The front door — article, diagrams, or print PDF |
| `/pressroom:writer` | Write an article, post, narrative, retrospective, or release notes |
| `/pressroom:illustrate` `[docs·this·file]` | Find the highest-impact figure-sites and render each (skill: `illustrator`) |
| `/pressroom:diagram-studio` | Author Graphviz/Mermaid diagrams → SVG, PNG, or PDF for any target |
> is the mermaid-specialist a user-facing or agent-facing capability?
> it looks to me like it should be a value-handler rather than 
> a slash command? why is it a slash command? make the case for it
| `/pressroom:mermaid-specialist` | Author and render across Mermaid's full diagram taxonomy |
| `/pressroom:rich-pdf-with-diagrams` | Produce a print-quality PDF with embedded diagrams |
> we have a design-reviewer, but where is the pressroom "copy reviewer"
> or "document reviewer" ?
> is it missing or obscured?
| `/pressroom:design-reviewer` | Adversarially review the visual design of a rendered doc or chart |
| `/pressroom:model-survey` · `/pressroom:craft-study` | Survey image models / discover image-craft techniques on the ComfyUI backend (loop-driven) |


> mission-control is much too salesy
> rename "mission-control" to "operate"
> or "operations" .. make the case for your recommendation

## mission-control — OPERATE ↻

Keep the live product alive and improving.

| Command | What it does |
|---|---|
| `/mission-control:operate-gate` `[readiness·health·path]` | Go-live readiness + steady-state health → READY / WATCH / NOT-READY |
| `/mission-control:observability` | Four golden signals, three pillars, SLI→SLO→alert definitions |
| `/mission-control:incident` `[declare·runbook·postmortem]` | Declare severity & roles, mitigate, then runbook + blameless postmortem |
| `/mission-control:maintain` | Upkeep cadence — deps, CVE patching, cert/secret rotation, tech debt |
| `/mission-control:iterate` | Turn a production signal into a new opportunity that re-enters DISCOVER |
> this should not be buried in mission-control
> it should be "/flow ping" or "/flow status" etc
> move to DELIVER
| `/mission-control:flow` `[ping·status·start·stop·url·build]` | The roadmap flow board + flow-server MCP control |
> move to DELIVER
> surface "/flow setup" and give it more prominence
> if this needs user-intervention in order to set it up
> then the user needs to be prompted to set it up
> with instructions
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
> the flow-server is RETIRING because it's "too hard for claude to figure out"
> the MCP will not be serving web pages (that will be another project entirely, not in idea-to-production)
> the mcp will answer questions like "what is on the roadmap"
> and other deterministism-layer (CPU on the client machine) actions
> that do not require the model to reason about / interpret or otherwise
> interact with data that is acquired / presented by the "flow mcp"
| `flow-server` | mission-control | The roadmap flow board — a first-party, pinned Rust binary |

> ALL of the below (unless specifically for the HTTP server)
> are in fact MCP bindings and as such should be documented
> and integrated with "flow"
> "flow-server" is to be retired as a name
> "flow-mcp" is the new name, and the flow-mcp is a connection that 
> operates these CPU / deterministic actions
The **flow-server** verbs are tools the plugin calls for you (reached through
`/mission-control:flow`, never typed directly): `render_roadmap`, `list_items`, `get_item`,
`post_status`, `set_wait_go`, `append_spend`, `set_item_model`, `validate_connection`,
`mutate_connection`, `annotate`, `request_rewrite`, `append_sysmsg`, `list_events`, `ping`.

---

> DIRECTIVE: write a comprehensive migration plan for the changes
> above, and use /roadmapper to create an epic containing atomic
> work items (or dependency streams) to accomplish the above
> to settle ambiguities, or to gain steering, ask the user
> and present carefully thought-out choices for the direction of 
> travel


*Source of truth: this catalog is hand-kept from `plugins/*/commands/` and `plugins/*/skills/`.
When a command is added, renamed, or retired there, update this file. Agent-internal skills are
omitted by design.*
