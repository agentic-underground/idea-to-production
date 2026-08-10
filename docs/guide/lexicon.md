# The standard lexicon — phrase it this way and the right context loads

*A user-facing reference.* The idea-to-production marketplace has a **context-fulfilment router**:
when you phrase an instruction in the marketplace's standard jargon, the agent loads exactly the
plugin-sections that instruction needs — and leaves the rest dormant. This page is the dictionary of
that jargon. What is **proven deterministically** by the pre-push gate
([`verify-routing.sh`](../../scripts/verify-routing.sh), see [`routing-tests.md`](./routing-tests.md))
is the **wiring**: every section named here exists and is reachable, no `/command` here is a dead
route (R1/R2/R3), the exact-phrase collisions are declared (R4), and this page stays in step with the
machine ledger [`scripts/routing/collisions.tsv`](../../scripts/routing/collisions.tsv) (R8). The
**intent-level** disambiguation in §4 (which wording should route where) is asserted by maintainers and
checked *behaviourally* only by the opt-in Layer-2 eval — not the pre-push gate. So: the routes are
proven to exist; the routing *judgment* is proven by the eval when you run it.

> **How to use this page.** Say what you want in the phrasing of the table you need. Reach for a
> `/command` when you want to be unambiguous; reach for a natural phrase when you want the agent to
> route by intent. When an intent is shared by several sections (§4), name the *distinguishing* thing
> (the artefact, the phase, the scope) and the router lands the right one.

## 1. The two conventions that govern everything

- **Casing** ([`glossary.md`](../../plugins/deliver/knowledge/glossary.md)): **UPPERCASE** = a STATION,
  PHASE, or certified gate (IDEA, EARS, TEST, DEPLOY). **lowercase** = an installable artefact you can
  invoke — a plugin, skill, agent, or `/command` (`deliver`, `roadmapper`, `/publish`).
- **`plugin:section`** names any routable thing: `discover:market-scan` (a skill), `deliver:reviewer`
  (an agent), `/i2p:help` (a command). This is the vocabulary the routing tags and this lexicon use.

## 2. The phases — the coarse dial (say a PHASE to set the room)

```
DISCOVER → IDEATE → DELIVER → DESIGN → BUILD ⇄ ASSURE ⇄ SECURE → PUBLISH → OPERATE ↻
```

Declaring a phase with **`/i2p:focus <PHASE>`** (once the FOCUS layer lands — see
[`context-routing.md`](./context-routing.md)) steers the agent to treat out-of-phase skills as
dormant. Each phase is owned by one plugin; three concerns (usability `design`, quality `deliver`,
security `secure`) cross-cut the workflow.

| Phase | Say this | Loads (owning plugin) |
|---|---|---|
| **DISCOVER** | "find something worth building", "scan for a niche", `/discover:market-scan` | `discover` (`goal-setter`, `market-scan`) |
| **IDEATE** | "turn this into a build-ready package", "refine this idea", `/ideate:ideate` | `ideate` (`ideate`, `name-search`) |
| **DELIVER** | "add to the roadmap", "what's on the roadmap", `/deliver:roadmapper` | `deliver` (`roadmapper`, `scorecard`) |
| **DESIGN** | "mock up this screen", "review this UI", `/design:mockup`, `/design:ui-review` | `design` (`mockup`, `ui-review`) |
| **BUILD** | "run DELIVER", "build the backlog", "cut a vertical slice", `/deliver:build` | `deliver` (`builder`, `vertical-slice`, handlers) |
| **ASSURE** | "review this PR", "chase coverage", `/deliver:pr-review`, `/deliver:coverage-loop` | `deliver` (`pr-review`, `code-quality`) |
| **SECURE** | "run the security gate", "scan for secrets", `/secure:scan-all` | `secure` (`scan-*`) |
| **PUBLISH** | "write this up", "illustrate the docs", "print-quality PDF", `/publish` | `publish` (`writer`, `illustrator`, …) |
| **OPERATE** | "keep the lights on", "declare an incident", `/operate:operate-gate` | `operate` (`maintain`, `incident`, …) |

## 3. Core concept terms (the vocabulary a task uses)

From [`glossary.md`](../../plugins/deliver/knowledge/glossary.md) §"Core language" — a routing-tag or
instruction that uses these words routes cleanly:

- **value-station** / **the gate** — a conveyor stage with a mandatory exit certificate.
- **vertical-slice** — one thin, end-to-end, reviewable increment ("cut a slice", "next slice").
- **coordinate** ≡ pin ≡ proof-obligation — a failing test that locates the code to write.
- **coverage density** — happy/unhappy/abuse per behaviour (100% is the floor).
- **graceful enhancement** — deliver uses secure/publish/design *if installed*, else degrades.
- **KAIZEN** — the lean canon (muda · mura · muri; halve-the-distance).
- **routing-tag** — the `Phase` + `Loads` lines a roadmap item carries so it lights up its own skills.

## 4. Disambiguation — when one intent could load several sections

These are the **declared collision families** (the machine copy is `kind=collision` rows in the
ledger). If your phrasing is ambiguous, add the **distinguishing axis** and the router lands the right
section. Family ids are the ledger keys R8 keeps in sync.

| Family (ledger id) | The ambiguous phrase | Say *also*… → to hit |
|---|---|---|
| `C0-idea-intake` | "I have an idea" | *raw idea* → `ideate:ideate`; *find one first* → `discover:market-scan`; *put it on the roadmap* → `deliver:roadmapper` |
| `C1-self-improve` | "fold this feedback in / self-improve" | name the **element**: `/deliver:self-improve <path>` (only `deliver` has the command today — see §5) |
| `C2-check` | "check readiness / are my tools installed" | a plugin (`/secure:check`) or **all** (`/i2p:check`) |
| `C3-inspect` | "inspect this / run the inspector" | the plugin: `/deliver:inspect`, `/design:inspect`, … |
| `C4-review-critique` | "review this / critique this" | the **artefact**: PR → `deliver:pr-review`; architecture/code → `deliver:code-quality`; running UI → `design:ui-review`; chart/PDF → `publish:design-reviewer`; prose → `publish:document-review`; everything → `i2p:review` |
| `C5-chart-diagram` | "make a chart / a diagram" | the **verb**: produce → `publish:diagram-studio`; place in a doc → `publish:illustrator`; review → `publish:design-reviewer` |
| `C6-coverage-loop` | "chase coverage" | `/deliver:coverage-loop` (command) drives the `deliver:code-quality` skill |
| `C7-name` | "name my product" | `/ideate:name` delegates to `ideate:name-search` |
| `C8-publish-wiki` | "publish this" | article/PDF → `/publish`; GitHub wiki → `operate:wiki-publisher` |
| `C9-lifecycle-phase` | "what phase are we in" | product lifecycle → `i2p:lifecycle`; SDLC gates → `deliver:lifecycle-states`; within-BUILD → `deliver:phase-sensor` |
| `C10-ship-build` | "ship it / build this" | the **scope**: whole backlog → `deliver:builder`; one increment → `deliver:vertical-slice` |
| `C11-opportunity` | "find an opportunity" | cold start → `discover:market-scan`; from a live signal → `operate:iterate` |
| `C12-security-review` | "security check / scan" | `secure:scan-all` (standalone); `deliver:pr-review` composes it during review |

## 5. Known dead routes (honest caveats — tracked defects)

These slash commands are **named in a skill's description but do not exist as command files** — typing
them does nothing today. They are tracked in the ledger (`kind=defect`) and are the first backlog
items for the trigger-discipline slices; the skill itself still auto-activates on its description.

| Say instead… | Dead slash (tracked) |
|---|---|
| describe the design feedback in context | `publish:design-review` |
| name the element for `/deliver:self-improve` | `design:self-improve`, `discover:self-improve`, `i2p:self-improve`, `ideate:self-improve`, `operate:self-improve`, `publish:self-improve`, `secure:self-improve` |

## 6. How this is proven

`bash scripts/verify-routing.sh` (the pre-push gate) checks — deterministically, token-free — that
every phrase here reaches a real section (R1/R2/R3), that every **exact shared phrase** is declared
(R4 — note this covers identical quoted phrases, a subset of §4's intent-level families), and that this
page and the ledger never drift (R8). The behavioural half — that natural wording actually *routes* to
the intended section and leaves others dormant, which is what §4 is really about — is the opt-in eval
in [`routing-tests.md`](./routing-tests.md). So the routes here are **proven to exist** by the gate;
run the eval to prove the **routing judgment**.

---

**See also:** [`routing-tests.md`](./routing-tests.md) (how the router is tested + how to extend it),
[`context-routing.md`](./context-routing.md) (the tripwire/FOCUS design),
[`glossary.md`](../../plugins/deliver/knowledge/glossary.md) (the full concept glossary).
