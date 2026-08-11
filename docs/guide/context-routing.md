# Context routing & the tripwire layer — keeping the doors phase-clean

*A design RFC for the marketplace.* Its companion,
[`context-building-pipeline.md`](./context-building-pipeline.md), explains the **doors** text uses
to reach a Claude Code agent and what each costs; its **sequel**,
[`context-population.md`](./context-population.md), applies the same `metadata.phase` spine to the
*knowledge* layer — keeping the always-on SessionStart door a thin phase pointer (EPIC 0067). This
document covers the *skill catalog*. This document explains the next problem: once
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

- **Skill and agent bodies are lazy.** A `SKILL.md` body (and an agent's body) loads only when it
  is invoked. The three heaviest text bodies — the skills
  [`roadmapper`](../../plugins/deliver/skills/roadmapper/SKILL.md) (1069 lines) and
  [`builder`](../../plugins/deliver/skills/builder/SKILL.md) (819), and the agent
  [`reviewer`](../../plugins/deliver/agents/reviewer.md) (702) — are **not** in context until they
  fire. The fear "big single-skill files are always loaded" is unfounded; see door 4 in the
  companion doc.
- **Truly always-on content is tiny and cached.** After EPIC 0067 (the context-population sequel,
  [`context-population.md`](./context-population.md)) the guaranteed phase-INDEPENDENT per-session
  injection across all eight plugins is just two things: `KAIZEN.md` (~2.4 KB), deduped to a single
  copy by the atomic `mkdir` lock in [`inject-kaizen.sh`](../../plugins/deliver/hooks/inject-kaizen.sh),
  plus i2p's thin phase **pointer** ([`phase-pointer.sh`](../../plugins/i2p/hooks/scripts/phase-pointer.sh),
  ≤60 words). `roadmap-routing.sh` (~1.3 KB) is now **phase-gated** to DELIVER — no longer part of the
  always-on core — and `session-intro` has been absorbed into the pointer. One-time, in the cached
  prefix; prompt caching makes it effectively free.

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

> **What is a gate and what is steering — read this before §3–§4.** Only one lever in this document
> actually *shrinks* the always-on catalog: **C5** (leaner descriptions). C1 and C2 do **not** remove
> anything from the prefix — every `description` the model can see stays visible — so they cannot
> reduce *attention* cost; what they reduce is **mis-activation** (a skill firing in the wrong
> phase). C1 (a guard clause) and C2 (an injected FOCUS) are therefore **best-effort behavioural
> steering**, not deterministic gates: they *lower the probability* of a wrong activation, they do
> not *prevent* it. The only deterministic enforcement Claude Code offers would be a `PreToolUse`
> deny-hook keyed to `metadata.phase` (a real gate); that is noted as a future option in §4.4, not
> claimed here. Read "gate" in this doc as *steering*, and measure it by mis-activation rate, not by
> bytes-in-attention.

---

## 2. Vocabulary

Reusing the settled terms in [`glossary.md`](../../plugins/deliver/knowledge/glossary.md):
**UPPERCASE** = a STATION or PHASE; **lowercase** = an installable artefact (plugin / skill / agent
/ command). The product lifecycle, unchanged:

```
DISCOVER → IDEATE → DELIVER → DESIGN → BUILD ⇄ ASSURE ⇄ SECURE → PUBLISH → OPERATE ↻
```

Three concerns **cross-cut** every phase: usability (`design`), quality (`deliver`), security
(`secure`). This document adds four terms. *(Casing convention, extended: a newly-coined **concept**
that names a marketplace-wide invariant is UPPERCASE like a STATION — `TRIPWIRE`, `FOCUS`; a
concrete **mechanism or artefact** stays lowercase like a skill — `phase-gate`, `routing-tag`.)*

- **TRIPWIRE** — a skill's activation contract: a precise trigger line plus a **phase guard**, so it
  is *biased* to self-activate inside its owning phase and to stay quiet outside it (or fire on an
  explicit `/command`). Best-effort, not enforced (see the gate-vs-steering note in §1).
- **FOCUS** — a per-repo declaration of the active phase (`.i2p/focus`), read into context so the
  agent is *steered* to treat out-of-phase surfaces as dormant. Survives `/clear`.
- **phase-gate** — the mechanism (a fail-silent SessionStart injection) that broadcasts the active
  FOCUS so the enabled-plugin set is *treated* as phase-scoped. Advisory steering, not a hard gate.
- **routing-tag** — a controlled-vocabulary line on an EPIC/PLAN that names the phase and the exact
  skills a slice needs, so the task *lights up its own skill tree*.

---

## 3. C1 — phase-scoped trigger discipline (the tripwire core)

Every skill declares the phase it belongs to, and its trigger stays inside that phase.

### 3.1 The `phase` field

Add `phase:` to the skill frontmatter. It is a **list**, not a scalar — several skills are validly
active in more than one phase (`frontend` in DESIGN *and* BUILD), so a single value would misclassify
them. Where a skill already carries a `metadata:` block (the newer producer/scanner skills do — see
`maintain`, `self-improve`, `market-scan`), `phase` joins it; where a skill has only `name` +
`description` (the leaner deliver-core skills), a minimal `metadata: { phase: [ … ] }` is added.
Allowed members are the nine phases plus `cross-cut`:

```yaml
metadata:
  phase: [DESIGN, BUILD]   # members: DISCOVER IDEATE DELIVER DESIGN BUILD ASSURE SECURE PUBLISH OPERATE | cross-cut
```

The gate rule is: a skill is dormant under `FOCUS=X` **iff** `X ∉ phase ∪ {cross-cut}`.

`cross-cut` marks a skill available in **every** phase and so exempt from the phase guard — the
`check` / `self-improve` boilerplate every plugin ships, and i2p's meta-surface. **Note the deliberate
distinction:** a companion whose *concern* cross-cuts (design, secure, publish) is not therefore
`cross-cut`-*tagged* — its skills carry their owning phase (`secure:scan-all → [SECURE]`) and are
reached across phases by **explicit `/command` or C3 routing-tag**, not by sitting always-active. Only
truly phase-agnostic boilerplate is tagged `cross-cut`. (§7 is the authoritative per-skill assignment;
§2's "concerns cross-cut" describes the *workflow*, not the tag.) `cross-cut` skills are still bound by
C5's description budget.

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
  → EPIC/PLAN specs on the roadmap.
metadata:
  phase: [DELIVER]
```

The lifecycle detail ("captures the idea, writes EARS, generates .feature files, …") moves into the
body, where it already lives, instead of the always-on frontmatter.

---

## 4. C2 — the active phase-gate (FOCUS)

C1 makes each skill well-behaved on its own. C2 lets the *user* declare a focus that the whole
enabled set respects — the direct answer to "I enabled all eight but only need two." You do not
uninstall; you focus.

### 4.1 `.i2p/focus`

A tiny per-repo file (git-ignored — so a FOCUS is **per-clone, per-machine**, not a committed
team-wide setting; right for a solo-builder repo):

```
phase: DISCOVER
allow: [discover, ideate]     # optional; entries may be a plugin (expands to only its in-phase skills) or a plugin:skill
note:  building the product brief
```

The dormancy rule is evaluated **per skill** against its `metadata.phase` (§3.1), so an `allow:`
plugin entry expands to *only that plugin's in-phase-or-cross-cut skills* — it does not re-admit a
plugin's out-of-phase skills. Absent file = no gate (today's behaviour).

> **Implementation status (slice 3 landed).** The C2 slice reads `phase:` and an optional `note:`;
> the `allow:` refinement above is **deferred to a later slice** — a hand-written `allow:` is currently
> ignored (not an error). The gate rule is fully delivered by per-skill `metadata.phase` matching;
> `allow:` is only a within-phase narrowing. The reader (`focus-routing.sh`) re-validates `phase:`
> against the nine-phase allowlist before injecting, so a hand-edited/cloned-repo `.i2p/focus` cannot
> inject arbitrary text into a session's context.

This composes with — does not replace —
[`phase-sensor`](../../plugins/deliver/skills/phase-sensor/): phase-sensor detects the *within-BUILD
sub-phase* (EARS / FEATURE / TEST / IMPLEMENT …) from artefacts during DELIVER, whereas FOCUS declares
a *lifecycle* phase (DISCOVER … OPERATE). They are deliberately **different levels**; the gate reads
only the lifecycle level, and FOCUS is a user-declared intent that outranks detection when set.

### 4.2 `/i2p:focus`

The front door owns the cross-plugin meta-surface, so the command lives in i2p:

- `/i2p:focus DISCOVER` — write `.i2p/focus`, confirm the active phase.
- `/i2p:focus` — report the current focus.
- `/i2p:focus off` — remove the gate.

### 4.3 The injection

A new fail-silent SessionStart hook in i2p, reusing the **same contract** as
[`roadmap-routing.sh`](../../plugins/i2p/hooks/scripts/roadmap-routing.sh) (drains stdin, `set -uo
pipefail`, always `exit 0`, touches nothing in the repo, degrades without `jq`) — the same shape, not
identical bytes. When `.i2p/focus` exists it injects one paragraph as `additionalContext`:

> *Active FOCUS: DISCOVER (plugins: discover, ideate; cross-cut always available). Apply the gate
> rule: a skill is DORMANT iff `DISCOVER ∉ (its `metadata.phase` ∪ {cross-cut})` — do not
> self-activate a dormant skill; invoke it only if the user runs its explicit `/command`. A skill
> with **no** `metadata.phase` yet is AVAILABLE (fail open). To change focus: `/i2p:focus <phase>`.*

**Untagged skills fail open** — until every skill carries `metadata.phase` (§8), an untagged skill is
treated as available, never silently dormant. This keeps the gate inert-but-safe while the tags roll
out, consistent with "absent focus file = no gate."

Cost: one small cached-prefix injection, re-fired on `resume`/`clear`/`compact` exactly as the
existing routing rule is — so it **survives `/clear`**, which is the whole point.

### 4.4 The deterministic option, considered

The injection above is *steering* (§1): the model still sees every description and can still
mis-fire. Claude Code does offer one genuinely deterministic door — a **`PreToolUse` deny-hook** on
the Skill tool that reads the invoked skill's `metadata.phase` and the active `.i2p/focus`, and
**denies** an out-of-phase invocation outright. That would make "gate" literal. It is deliberately
**out of scope here** (it changes tool-permission behaviour globally and needs its own design +
tests), but it is the upgrade path if steering proves too soft in practice — recorded so the choice
is explicit, not overlooked.

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

> **Consumer-safety (verify before shipping C3).** The `## Metadata` block is machine-read on the
> merge-gating path — by `scripts/verify-prereqs.sh` (the EPIC `**Branch**` / `## Plans` floor) and
> by the FLEET engine. Both parse it by **bolded key** (`grep '| **Key** |'`), which ignores
> unrecognised rows, so two additive rows are safe — but the C3 slice must **confirm** this against
> the then-current parsers rather than assume it, and add a check that each `Loads` value is a real
> installed `plugin:skill` (a typo'd tag warms nothing silently). Both are checks the routing test
> suite enforces (R2 no-dead-routes, R7 seed-wording).

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

Before/after, `frontend` (currently a 118-word run-on whose only triggers are dash pseudo-commands
`-help`/`-design`/`-critique` — no slash command — with an over-eager tail):

> **Before:** *"A living, self-improving design system for building information-rich, data-bound web
> apps in vanilla JS. Use this skill whenever the user wants to design, build, critique, or extend a
> data-bound UI — forms, tables, dashboards, pickers, cards, instruments … Trigger even if the user
> doesn't say 'design system' — any data-rich front-end work belongs here."*
>
> **After:** *"Design-system skill for data-bound vanilla-JS UIs (forms, tables, dashboards, INTENT
> markers). Trigger with `/frontend` (or "build this UI", "critique this screen"). Guard: DESIGN /
> BUILD only; dormant during DISCOVER/IDEATE. → components + a11y-checked markup."*
>
> *(The "After" trigger `/frontend` did **not** exist when this RFC was written — `frontend` shipped no
> command file, so copying the example as-is would have shipped a dead trigger, exactly the class of dead
> route the R3 check catches. Slice 5 (the deliver C5 slice) **created** `plugins/deliver/commands/frontend.md`
> alongside this description, so `/frontend` now resolves.)*

Apply the same compression to `ideate`, `market-scan`, `builder`, and every skill flagged in §7.
*(C4 — splitting the monolith bodies these lean descriptions front — is deferred; see §9.)*

---

## 7. Per-plugin rollout (all eight)

Each skill gets a `phase`; the **Guard** column flags the over-eager descriptions that also need a
negative clause + C5 compression. Cross-cut skills need `phase: cross-cut` + C5 only (no guard).

| Plugin | Owning phase | Phase-tag these skills | Guard + rewrite (over-eager today) |
|---|---|---|---|
| **discover** | DISCOVER | `goal-setter`, `market-scan` → `[DISCOVER]` | `market-scan` ("proactively whenever … casting about") |
| **ideate** | IDEATE | `ideate`, `name-search` → `[IDEATE]` | `ideate` ("Use proactively whenever …") |
| **design** | DESIGN | `mockup`, `ui-review` → `[DESIGN]` | — |
| **deliver** | DELIVER/BUILD/ASSURE | `roadmapper`→`[DELIVER]`; `builder`,`development-system-core`,`lifecycle-states`,`vertical-slice`,`rust-webapp-rollout`→`[BUILD]`; `code-quality`,`pr-review`,`reviewer-gate`→`[ASSURE]`; `frontend`→`[DESIGN, BUILD]`; `founder-method`,`scorecard`→`[DELIVER]`; `ideate`→`[IDEATE]` (fallback); `handoff-protocol`,`phase-sensor`,`prerequisites`,`value-station-handoff`→`[cross-cut]` | **`roadmapper`** ("in any form … proactively"), **`frontend`** ("even if the user doesn't say"), `builder` (broad) |
| **secure** | SECURE (concern cross-cuts) | `scan-all`,`scan-dependencies`,`scan-for-pii`,`scan-for-secrets` → `[SECURE]` | — (already `/scan-*`-triggered) |
| **operate** | OPERATE | `gemba`,`incident`,`iterate`,`maintain`,`observability`,`operate-gate`,`wiki-publisher` → `[OPERATE]` | — |
| **publish** | PUBLISH (concern cross-cuts) | `writer`,`craft-study`,`design-reviewer`,`diagram-studio`,`document-review`,`illustrator`,`model-survey`,`rich-pdf-with-diagrams` → `[PUBLISH]` | — |
| **i2p** | front door (agnostic) | all nine (`check`,`define-welcome`,`flow`,`help`,`lifecycle`,`review`,`self-improve`,`statusline-install`,`statusline-widgets`) → `[cross-cut]` | — |

Note the "concern cross-cuts" rows (`secure`, `publish`): the *concern* is available in every phase,
but its skills carry their **owning** phase (not `cross-cut`) and are reached across phases by explicit
`/command` or a C3 `Loads:` tag — they are not always-active. Only `i2p`'s meta-surface and every
plugin's `check` + `self-improve` boilerplate are tagged `[cross-cut]`. These `phase` values are what
the C2 steering reads; keeping them accurate is the covenant that makes the tripwire trustworthy.

---

## 8. Implementation slices (ordered)

Each is a focused branch → PR → `/deliver:pr-review` → direct-merge, per the repo's git workflow —
small batches, one concern each (KAIZEN).

1. **`metadata.phase` on ALL skills (tags only)** — one small PR that adds the `phase` list to every
   skill across all eight plugins per §7. Pure frontmatter, no description rewrites. This lands the
   data the gate reads **before** the gate ships, avoiding a consumer-before-producer inversion
   (until then the gate fails open per §4.3, so ordering is safe either way — but tagging first makes
   the gate meaningful on arrival).
2. **`phase` + C5 + guard clause on the two named phases** — compress descriptions and add the §3.2
   **negative-guard clause** (not just the phase tag) for `discover` + `ideate` (the user's working
   pair, incl. `ideate`'s over-eager rewrite). Proves the full C1+C5 change on a small surface.
3. **The phase-gate** — `.i2p/focus` format, the `/i2p:focus` command, and the SessionStart injection
   hook (C2). Now reads real tags from slice 1; delivers the "focus, don't uninstall" win.
4. **Roadmap routing-tags** — extend the EPIC/PLAN template + `roadmapper` §3 CAPTURE + the golden
   `PLAN_0001.md` (C3), incl. the consumer-safety confirmation from §5.1.
5. **Trigger discipline + C5 per remaining plugin** — one PR each for `design`, `deliver`, `secure`,
   `operate`, `publish`, `i2p`: guard clauses + description compression per §7. `deliver` is the
   largest and carries the two worst offenders (`roadmapper`, `frontend`, the latter creating the
   `/frontend` command per §6).

Ship 1–3 first: tags everywhere, the full C1+C5 pattern proven on discover/ideate, then the gate that
reads them — so the user can set a FOCUS and feel out-of-phase skills go quiet before the long tail of
per-plugin rewrites lands.

---

## 9. Appendix — C4 (deferred): split the monoliths

Out of scope for this round, recorded as the recommended follow-on because it aligns with the
marketplace's own doctrine (VALUE_FLOW §8: *"Thin skills, fat references. Each `SKILL.md` is a
router."*). The two heaviest **skills** — `roadmapper` (1069) and `builder` (819) — violate it: on
trigger they load everything, not the branch needed. The heaviest **agent**, `reviewer.md` (702), has
the same shape but is an agent, not a `SKILL.md`. The follow-on splits each into a thin router
(trigger + gate + a *when-to-read* reference table) with sub-topics in `references/` loading
per-branch, enforced by a CI covenant capping body size — **two caps, one for `SKILL.md` and one for
`agents/*.md`**, since a SKILL.md-scoped cap alone would not cover `reviewer.md`. Model both on the
existing KAIZEN byte-identity checks (CI Checks N/O) in
[`scripts/verify-prereqs.sh`](../../scripts/verify-prereqs.sh). Sequence it after §8 so the routing
layer is proven before the structural surgery begins.

---

## 10. The takeaway

The companion doc's rule is *match the door to the document*. This one adds: **match the trigger to
the phase.** Two distinct wins, kept honest about which lever delivers which: **C5** actually shrinks
the always-on catalog (fewer bytes in attention — the only lever that does); **C1 + C2** steer the
model away from firing an out-of-phase skill (lower mis-activation — best-effort, not a hard gate,
§4.4); and **C3** lets each task light up its own skill tree. Together they mean enabling all eight
plugins keeps the *lean* descriptions in view but the *wrong* skills quiet — until a task, or a FOCUS,
calls a phase into the room. Not "zero attention"; **right attention.**

---

**See also:** [`context-building-pipeline.md`](./context-building-pipeline.md) (the doors),
[`lexicon.md`](./lexicon.md) (the standard lexicon this design routes),
[`routing-tests.md`](./routing-tests.md) (the pre-push gate that PROVES this design — the R2/R3/R7
checks referenced above),
[`glossary.md`](../../plugins/deliver/knowledge/glossary.md) (vocabulary),
[`VALUE_FLOW.md`](../../plugins/deliver/VALUE_FLOW.md) §8 (thin-skills doctrine),
[`roadmap-routing.sh`](../../plugins/i2p/hooks/scripts/roadmap-routing.sh) (the injection precedent),
[`phase-sensor`](../../plugins/deliver/skills/phase-sensor/SKILL.md) (phase detection).
