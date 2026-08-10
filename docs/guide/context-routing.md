# Context routing & the tripwire layer — keeping the doors phase-clean

*A design RFC for the marketplace.* Its companion,
[`context-building-pipeline.md`](./context-building-pipeline.md), explains the **doors** text uses
to reach a Claude Code agent and what each costs. This document explains the next problem: once
several plugins are installed, **how do you keep only the phase you are working in present in the
agent's attention** — so that enabling all eight plugins does not pollute a DISCOVER session with
DELIVER, DESIGN, and OPERATE surfaces.

Like its companion, this is maintainer-facing material for people working *on* the marketplace. It
is not shipped to or read by installed plugins at runtime. It specifies a layer to be built in
slices; **no plugin surface is changed by this document itself.**

---

## 1. The problem, and the reframe

The intuition that motivates this work is: *"when I enable all eight plugins, I flood my context
with information I don't need, and when I want to FOCUS on one thing I categorically do not want the
others in my mind."* That intuition is correct about the symptom but wrong about the cause, and the
difference decides the fix. A three-part audit of the marketplace found:

**What is already defended (do not touch):**

- **Skill bodies are lazy.** A `SKILL.md` body loads only when the skill is invoked. The three
  heaviest — [`roadmapper`](../../plugins/deliver/skills/roadmapper/SKILL.md) (1069 lines),
  [`builder`](../../plugins/deliver/skills/builder/SKILL.md) (819),
  [`reviewer`](../../plugins/deliver/agents/reviewer.md) (702) — are **not** in context until they
  fire. The fear "big single-skill files are always loaded" is unfounded; see door 4 in the
  companion doc.
- **Truly always-on content is tiny and cached.** Across all eight plugins the only guaranteed
  per-session injection is `KAIZEN.md` (~2.4 KB), deduped to a single copy by the atomic `mkdir`
  lock in [`inject-kaizen.sh`](../../plugins/deliver/hooks/inject-kaizen.sh), plus i2p's
  `session-intro` (~0.26 KB) and
  [`roadmap-routing.sh`](../../plugins/i2p/hooks/scripts/roadmap-routing.sh) (~1.3 KB). ~4 KB,
  one-time, in the cached prefix. Prompt caching makes this effectively free.

**What actually pollutes (the real target):**

1. **The always-on routing catalog.** Every enabled plugin's skill / command / agent
   `description:` frontmatter is *always* in the prefix — that is the menu Claude reads to decide
   what to invoke. Today those descriptions are verbose, multi-sentence, trigger-stuffed block
   scalars. Enable all eight and the model carries `deliver`'s 19 skills + 32 agents + 11 commands,
   plus `design`, `operate`, `publish`, … **in attention while doing DISCOVER.** The token cost is
   cached and small; the *attention* cost is not. This is the pollution the user feels.
2. **Triggers that cross phase boundaries with no guard.** The descriptions are not just verbose,
   they are over-eager. `roadmapper` reads: *"Trigger this skill whenever the user says … or
   expresses a desire for a project improvement in any form. … Use it proactively — if the user is
   discussing changes to a project in any form, this skill is almost certainly applicable."* That
   tripwire fires during discover/ideate and drags a 1069-line body in at the wrong moment.
   `frontend` ends *"Trigger even if the user doesn't say 'design system'."* `ideate` and
   `market-scan` both say *"Use proactively whenever …"*. A tripwire with no phase guard is a
   tripwire that is always tripped.
3. **No task → skill routing convention.** Nothing in the roadmap grammar tells the agent which
   skills a given item needs. So after a `/clear`, re-warming the right context is guesswork rather
   than something the task *declares*.

The reframe in one line: **the fix is not to load fewer bytes — it is to make the always-on catalog
lean and to make every trigger phase-aware, so a skill outside the active phase stays dormant unless
explicitly summoned.** That is what "tripwire" means here — a *sensitive but specialised* sensor
that fires precisely, not broadly.

---

## 2. Vocabulary

Reusing the settled terms in [`glossary.md`](../../plugins/deliver/knowledge/glossary.md):
**UPPERCASE** = a STATION or PHASE; **lowercase** = an installable artefact (plugin / skill / agent
/ command). The product lifecycle, unchanged:

```
DISCOVER → IDEATE → DELIVER → DESIGN → BUILD ⇄ ASSURE ⇄ SECURE → PUBLISH → OPERATE ↻
```

Three concerns **cross-cut** every phase: usability (`design`), quality (`deliver`), security
(`secure`). This document adds four terms:

- **TRIPWIRE** — a skill's activation contract: a precise trigger line plus a **phase guard**, so it
  self-activates only inside its owning phase (or on an explicit `/command`).
- **FOCUS** — a per-repo declaration of the active phase (`.i2p/focus`), read into context so the
  agent treats out-of-phase surfaces as dormant. Survives `/clear`.
- **phase-gate** — the mechanism (a fail-silent SessionStart injection) that turns the enabled-plugin
  set into a phase-scoped one by broadcasting the active FOCUS.
- **routing-tag** — a controlled-vocabulary line on an EPIC/PLAN that names the phase and the exact
  skills a slice needs, so the task *lights up its own skill tree*.

---

## 3. C1 — phase-scoped trigger discipline (the tripwire core)

Every skill declares the phase it belongs to, and its trigger stays inside that phase.

### 3.1 The `phase` field

Add `phase:` to the skill frontmatter. Where a skill already carries a `metadata:` block (the newer
producer/scanner skills do — see `maintain`, `self-improve`, `market-scan`), `phase` joins it; where
a skill has only `name` + `description` (the leaner deliver-core skills), a minimal `metadata: {
phase: … }` is added. Allowed values are the nine phases plus `cross-cut`:

```yaml
metadata:
  phase: DELIVER        # one of: DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE | cross-cut
```

`cross-cut` marks a skill available in every phase (the `check` / `self-improve` boilerplate every
plugin ships; the `secure` scanners; the `publish` producers; i2p's meta-surface). A `cross-cut`
skill is exempt from the phase guard but **not** from C5's description budget.

### 3.2 The negative-guard clause

Any skill whose description currently says "proactively" / "in any form" / "even if the user doesn't
say" gains an explicit dormancy clause. Template:

> **Guard:** dormant outside `<PHASE>`. Do NOT self-activate during `<other phases>`; fire only on
> `/<command>` or an unambiguous `<PHASE>`-phase request.

### 3.3 Worked example — `roadmapper`

Before (the over-eager original, abridged):

> *Trigger this skill whenever the user says "feature request:", … or expresses a desire for a
> project improvement **in any form**. … Use it **proactively** — if the user is discussing changes
> to a project **in any form**, this skill is almost certainly applicable.*

After:

```yaml
name: roadmapper
description: >
  Manage a project roadmap — capture items, author EARS/PLAN specs, drive test-first delivery.
  Trigger with /roadmapper (or "feature request: …", "add to the roadmap", "what's on the roadmap",
  "pull the next feature"). Guard: dormant outside DELIVER; do NOT self-activate during
  DISCOVER/IDEATE — a raw idea belongs to discover/ideate until it is authorised for build.
metadata:
  phase: DELIVER
```

The lifecycle detail ("captures the idea, writes EARS, generates .feature files, …") moves into the
body, where it already lives, instead of the always-on frontmatter.

---

## 4. C2 — the active phase-gate (FOCUS)

C1 makes each skill well-behaved on its own. C2 lets the *user* declare a focus that the whole
enabled set respects — the direct answer to "I enabled all eight but only need two." You do not
uninstall; you focus.

### 4.1 `.i2p/focus`

A tiny per-repo file (git-ignored, like other `.i2p/` state):

```
phase: DISCOVER
allow: [discover, ideate]     # optional explicit allow-list; default = the phase's owning plugin(s) + cross-cut
note:  building the product brief
```

Absent file = no gate (today's behaviour). This composes with — does not replace —
[`phase-sensor`](../../plugins/deliver/skills/phase-sensor/): phase-sensor *detects* the build phase
from artefacts during DELIVER; FOCUS is a *user-declared* intent that outranks detection when set.

### 4.2 `/i2p:focus`

The front door owns the cross-plugin meta-surface, so the command lives in i2p:

- `/i2p:focus DISCOVER` — write `.i2p/focus`, confirm the active phase.
- `/i2p:focus` — report the current focus.
- `/i2p:focus off` — remove the gate.

### 4.3 The injection

A new fail-silent SessionStart hook in i2p, modelled byte-for-byte on the contract of
[`roadmap-routing.sh`](../../plugins/i2p/hooks/scripts/roadmap-routing.sh) (drains stdin, `set -uo
pipefail`, always `exit 0`, touches nothing in the repo, degrades without `jq`). When `.i2p/focus`
exists it injects one paragraph as `additionalContext`:

> *Active FOCUS: DISCOVER (plugins: discover, ideate; cross-cut always available). Treat skills whose
> `metadata.phase` is not DISCOVER/cross-cut as DORMANT — do not self-activate them; invoke an
> out-of-phase skill only if the user runs its explicit `/command`. To change focus: `/i2p:focus
> <phase>`.*

Cost: one small cached-prefix injection, re-fired on `resume`/`clear`/`compact` exactly as the
existing routing rule is — so it **survives `/clear`**, which is the whole point.

---

## 5. C3 — roadmap-item routing tags

So a task can *light up its own skill tree*. The audit found the natural homes already exist: the
EPIC/PLAN `## Metadata` block (structurally parsed, like the 4-digit `order` columns) and the PLAN
`## Construction process` section (read verbatim by the FLEET engine).

### 5.1 Grammar

One line in `## Metadata`, controlled-vocabulary, parseable by a leading key like every other row:

```markdown
| **Phase** | `BUILD` |
| **Loads** | `deliver:vertical-slice`, `deliver:frontend`, `design:ui-review` |
```

`Loads` names `plugin:skill` artefacts (lowercase, matching the glossary). It is advisory context
routing, not a permission system — it tells a freshly-`/clear`ed agent which skills to warm for this
slice, and nothing more.

### 5.2 Emission & consumption

- **Emit:** `roadmapper` §3 CAPTURE adds the two rows when it authors an EPIC/PLAN, inferring `Loads`
  from the slice's stack and surfaces (a UI slice → `design:*` + `deliver:frontend`; a release slice
  → `secure:scan-all`, `publish:writer`). This is the *"during planning, the agent provides wording
  that lights up the skill tree"* behaviour, made concrete.
- **Consume:** after `/clear`, reading the PLAN's `Phase` + `Loads` is the routing instruction — the
  agent warms exactly those skills and, if `.i2p/focus` is unset, may offer to `/i2p:focus <Phase>`.
- **Golden example:** graft the two rows onto
  [`references/examples/PLAN_0001.md`](../../plugins/deliver/skills/roadmapper/references/examples/PLAN_0001.md)
  so the template ships a worked instance.

---

## 6. C5 — tighten the always-on catalog

A `description:` is the tripwire's *sensor*: it is always in the prefix, so it must be lean. The
rule:

> **Budget ≈ 60 words / 400 chars.** Structure: *one capability sentence* → *`Trigger with /cmd (or
> "phrase", "phrase")`* → *`Guard:` clause (C1)* → *`→ output`*. Everything else — the enumerated
> feature list, the self-improvement note, the "what it produces in detail" prose — moves into the
> body, which loads only on invocation.

Before/after, `frontend` (currently one 90-word run-on with no trigger command and an over-eager
tail):

> **Before:** *"A living, self-improving design system for building information-rich, data-bound web
> apps in vanilla JS. Use this skill whenever the user wants to design, build, critique, or extend a
> data-bound UI — forms, tables, dashboards, pickers, cards, instruments … Trigger even if the user
> doesn't say 'design system' — any data-rich front-end work belongs here."*
>
> **After:** *"Design-system skill for data-bound vanilla-JS UIs (forms, tables, dashboards, INTENT
> markers). Trigger with `/frontend` (or "build this UI", "critique this screen"). Guard: DESIGN /
> BUILD only; dormant during DISCOVER/IDEATE. → components + a11y-checked markup."*

Apply the same compression to `ideate`, `market-scan`, `builder`, and every skill flagged in §7.

---

## 7. Per-plugin rollout (all eight)

Each skill gets a `phase`; the **Guard** column flags the over-eager descriptions that also need a
negative clause + C5 compression. Cross-cut skills need `phase: cross-cut` + C5 only (no guard).

| Plugin | Owning phase | Phase-tag these skills | Guard + rewrite (over-eager today) |
|---|---|---|---|
| **discover** | DISCOVER | `goal-setter`, `market-scan` → DISCOVER | `market-scan` ("proactively whenever … casting about") |
| **ideate** | IDEATE | `ideate`, `name-search` → IDEATE | `ideate` ("Use proactively whenever …") |
| **design** | DESIGN | `mockup`, `ui-review` → DESIGN | — |
| **deliver** | DELIVER/BUILD/ASSURE | `roadmapper`→DELIVER; `builder`,`development-system-core`,`lifecycle-states`,`vertical-slice`,`rust-webapp-rollout`→BUILD; `code-quality`,`pr-review`,`reviewer-gate`→ASSURE; `frontend`→DESIGN; `founder-method`,`scorecard`→DELIVER; `ideate`→IDEATE (fallback); `handoff-protocol`,`phase-sensor`,`prerequisites`,`value-station-handoff`→cross-cut | **`roadmapper`** ("in any form … proactively"), **`frontend`** ("even if the user doesn't say"), `builder` (broad) |
| **secure** | SECURE (cross-cut) | `scan-all`,`scan-dependencies`,`scan-for-pii`,`scan-for-secrets` → SECURE | — (already `/scan-*`-triggered) |
| **operate** | OPERATE | `gemba`,`incident`,`iterate`,`maintain`,`observability`,`operate-gate`,`wiki-publisher` → OPERATE | — |
| **publish** | PUBLISH (cross-cut) | `writer`,`craft-study`,`design-reviewer`,`diagram-studio`,`document-review`,`illustrator`,`model-survey`,`rich-pdf-with-diagrams` → PUBLISH | — |
| **i2p** | cross-cut (front door) | all nine (`check`,`define-welcome`,`flow`,`help`,`lifecycle`,`review`,`self-improve`,`statusline-*`) → cross-cut | — |

Every plugin's `check` + `self-improve` → `cross-cut`. The `phase` values are the single source of
truth the C2 gate reads; keeping them accurate is the covenant that makes the tripwire trustworthy.

---

## 8. Implementation slices (ordered)

Each is a focused branch → PR → `/deliver:pr-review` → direct-merge, per the repo's git workflow —
small batches, one concern each (KAIZEN).

1. **`phase` field + C5 on the two named phases** — add `metadata.phase` and compress descriptions
   for `discover` + `ideate` (the user's working pair). Smallest, proves the frontmatter change.
2. **The phase-gate** — `.i2p/focus` format, the `/i2p:focus` command, and the SessionStart
   injection hook (C2). Independent of the per-plugin tags; delivers the "focus, don't uninstall"
   win immediately.
3. **Roadmap routing-tags** — extend the EPIC/PLAN template + `roadmapper` §3 CAPTURE + the golden
   `PLAN_0001.md` (C3).
4. **Trigger discipline per remaining plugin** — one PR each for `design`, `deliver`, `secure`,
   `operate`, `publish`, `i2p`: apply `phase` + negative guards + C5 per §7. `deliver` is the
   largest and carries the two worst offenders (`roadmapper`, `frontend`).

Ship 1 and 2 first: together they let the user set a FOCUS and feel out-of-phase skills go quiet,
before the long tail of per-plugin rewrites lands.

---

## 9. Appendix — C4 (deferred): split the monoliths

Out of scope for this round, recorded as the recommended follow-on because it aligns with the
marketplace's own doctrine (VALUE_FLOW §8: *"Thin skills, fat references. Each `SKILL.md` is a
router."*). `roadmapper` (1069), `builder` (819), and `reviewer.md` (702) violate it: on trigger
they load everything, not the branch needed. The follow-on splits each into a thin router
(trigger + gate + a *when-to-read* reference table) with sub-topics in `references/` loading
per-branch, enforced by a CI covenant capping `SKILL.md` body size — mirroring the existing KAIZEN
byte-identity checks (CI Checks N/O) in [`scripts/verify-prereqs.sh`](../../scripts/verify-prereqs.sh).
Sequence it after §8 so the routing layer is proven before the structural surgery begins.

---

## 10. The takeaway

The companion doc's rule is *match the door to the document*. This one adds: **match the trigger to
the phase.** Keep the always-on catalog lean (C5), make every tripwire phase-aware (C1), let the
user declare a FOCUS the whole set respects (C2), and let each task light up its own skill tree
(C3). Then enabling all eight plugins costs nothing in attention until a task — or a focus — calls a
phase into the room.

---

**See also:** [`context-building-pipeline.md`](./context-building-pipeline.md) (the doors),
[`glossary.md`](../../plugins/deliver/knowledge/glossary.md) (vocabulary),
[`VALUE_FLOW.md`](../../plugins/deliver/VALUE_FLOW.md) §8 (thin-skills doctrine),
[`roadmap-routing.sh`](../../plugins/i2p/hooks/scripts/roadmap-routing.sh) (the injection precedent),
[`phase-sensor`](../../plugins/deliver/skills/phase-sensor/SKILL.md) (phase detection).
