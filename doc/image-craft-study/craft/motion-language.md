# Motion language — named elements · element-specific verbs · fit-the-environment

> The element-level motion layer: how an *animated diagram* earns the word **alive** rather than merely
> *moving*. The motion sibling of [`art-direction-DRAFT.md`](art-direction-DRAFT.md) (which judges the
> still frame) and the next development of the
> [Motion canon](../../../plugins/pressroom/knowledge/raster-toolchain.md#motion-canon--the-house-motion-policy-the-linger-directive)
> (which paces the *whole frame* in time). Most "the animation is busy / arbitrary / says nothing"
> reactions are a named violation here — a thing moving in a way that does **not** fit what it is.
>
> **How to wield it:** before a generator emits a single `<svg>`, it **names its elements** (from the
> registry below), **picks each element's verb**, and emits each through
> [`diagram-primitives.sh`](../toolchain/src/diagram-primitives.sh) (the shared crafted-SVG library — the
> single home for the line-art craft). The motion verbs are *element-specific*: a token **rides**, a gate
> **latches**, a sweep **rotates-and-surfaces**. It would be wrong to make a gate ride or a token latch —
> the motion must *fit the element* and *fit the diagram's whole visual environment*.

## 1. Premise — from frame-linger to element-motion

The [Motion canon](../../../plugins/pressroom/knowledge/raster-toolchain.md#motion-canon--the-house-motion-policy-the-linger-directive)
answered one question: **"how long does this FRAME hold?"** — the dwell, the breathe, the poster linger,
the ≥24-hold "Ah-HA!" floor. That is *frame-level* policy, and it is the bedrock this doc stands on. But it
is mute on a second, equally load-bearing question:

> **"What KIND of thing is this — and how does a thing of THIS kind move?"**

Today the answer is implicit. Every flagship generator already encodes an element archetype with its own
motion — the foundry conveyor's token *rides* the rail while gates *latch* teal and the TESTS gate *flips*
red→green; the market-scanner's beam *rotates-and-surfaces*; the masthead's nodes *cross-dissolve* — but
that vocabulary lives only in shell variable names and code comments. It is nowhere codified, so every
generator **re-derives** it from scratch, and the line-art stays flat single-stroke primitives because the
*elements* never received the shared, crafted vocabulary the *timing* already has.

This doc codifies that vocabulary as a **language**, so a value-handler builds an animated diagram with deep
knowledge of its choices: named elements, each with an element-specific animation that fits the element and
the diagram's visual environment. The rule that governs every choice:

> **Animation must FIT the element.** A token *rides* (it is a thing that travels). A gate *latches* and
> *flips* (it is a thing that changes state in place). A sweep *rotates* (it is a thing that scans). A node
> *breathes* (it is a thing that is present). Motion borrowed from the wrong archetype reads as noise — the
> #1 tell of a generated-not-authored animation. This is the element-level companion to art-direction's
> "no focal point" tell: there, the eye wanders in space; here, the eye wanders in *time*.

## 2. The named-element registry

The eight primary elements (plus two minor), each binding **what it IS** (its crafted SVG form, the home of
the line-art uplift — implemented as a `prim_*` in
[`diagram-primitives.sh`](../toolchain/src/diagram-primitives.sh)) to **what it MEANS** in a diagram. The
registry NAMES are the primitive names; the library is the implementation.

| Element | What it IS (crafted form → primitive) | What it MEANS |
|---|---|---|
| **NODE** | a shaded disc with a soft drop-shadow + optional check-glyph → `prim_node` | a stage / station / phase — a *place* value occupies |
| **ARC** | a dashed cubic Bézier with an arrowhead, on its own depth plane → `prim_arc` | a relationship that *returns* — a feedback or loop-closing edge |
| **TOKEN** | a small bright ringed marker that sits *on* the rail → `prim_token` | the unit of value in transit — the IDEA travelling the line |
| **GATE** | a node specialised to carry a verdict (latched-teal ✓ / failing-red / pending-dim) → `prim_gate` | a checkpoint value must *clear* — a test, a quality/security gate |
| **RAIL** | a base stroke + a teal "lit" overlay up to the token → `prim_rail` | the fixed path value travels — the conveyor, the lifecycle spine |
| **SWEEP / BEAM** | a translucent wedge + a bright leading edge from a hub → `prim_sweep` | an active scan crossing a field — discovery passing over candidates |
| **STAMP** | a label that settles into a verdict word (KEEP / SHIP / PASS) → `prim_stamp` | the moment of judgement — the decision the sequence was building to |
| **HALO** | a soft concentric ring around an element → `prim_halo` | attention — "look *here*, this is the current element" |
| *BLIP* (minor) | a small echoed dot on a dial/field → reuses `prim_node` small | a candidate registered on the scan but not yet judged |
| *WEDGE* (minor) | the SWEEP's translucent trailing sector alone → part of `prim_sweep` | the *covered* arc — how much of the field has been scanned |

> **One element, one crafted home.** Because each element is a single `prim_*`, the line-art investment
> (shading, layered planes, in-vector depth) lands **once** and every generator that sources the library
> inherits it. This is the structural reason the registry exists: it is not a glossary, it is the set of
> sockets the craft plugs into.

## 3. The motion verbs

Each element moves with its own verb(s). For every verb: **(a)** what the motion *communicates*, **(b)**
which [TIMING](../../../plugins/pressroom/knowledge/raster-toolchain.md#motion-canon--the-house-motion-policy-the-linger-directive)
role/holds it wants, and **(c)** the `reslow.sh` / `magick -morph` treatment that realises it.

### NODE — arrive · breathe · dissolve

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **arrive** | a stage *enters* — fade/scale-in as the eye is led to it | `label` ≈7 (a marker appears) or `caption` ≈14 if it carries a one-line beat | a keyframe at low opacity/small `r` cross-dissolving (`-morph`) into the settled node |
| **breathe** | this node is *current and alive* — the gentle PULSE while it holds | inherits its frame's dwell; the breathe is *within* the hold | `reslow.sh` PULSE-modulate within the hold window (`100 102 104 102`), **never** a per-frame flicker |
| **dissolve** | this state *gives way* to the next — a cross-fade, not a jump | the `transition` between two states (≈2–3) | `magick -morph M` tween frames between consecutive keyframes (the masthead does exactly this) |

### TOKEN — ride

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **ride** | value *advances* gate-to-gate along the rail | the step *between* stops is a `transition` (≈3, flick by); a **beat at each stop** takes that stop's own role (often `dense` ≈28 when the stop teaches) | the inter-stop frames are emitted once each and held briefly; the rail's lit overlay (`prim_rail`) extends to the new token x with each ride |

> The token never lingers *mid-rail* — the motivated motion is "depart, travel quickly, settle on the next
> meaningful stop." The teaching happens **at** the gate, not in the gap.

### GATE — latch · flip

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **latch** | this checkpoint is *cleared* — it dims-to-done, teal with a ✓ | a `transition`/`label` as the token passes (the clearing is quick; the *meaning* was taught at the flip) | the gate's fill swaps dim→teal and the check-glyph appears, cross-dissolved in |
| **flip** | the **state change** — e.g. a failing test red→green; the proof-before-code spine | a **`dense` ≥24-hold "Ah-HA!" beat** — the mandatory floor; the eye must travel, read the caption, and *connect* | a held keyframe at the new colour with a soft glow ring; the spine caption settles at full opacity (per "SETTLE the key label") before advancing |

> A flip is the single densest beat a diagram has: it is where the sequence's *meaning* lands. It always
> takes the ≥24 floor. A latch is its quiet echo — the same gate, now merely *done*.

### SWEEP / BEAM — rotate-surface

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **rotate-surface** | an active scan *crosses the field*, brightening each element as the leading edge reaches it | each distinct beam angle is a `transition` (≈3) — pure motion, caption unchanged | one keyframe per angle; a candidate flips dim→amber the moment `sweep_angle ≥ its_angle`; the translucent WEDGE trails behind to show coverage |

> The rotation itself teaches nothing new per frame, so it stays *quick* (the market-scanner sweeps eleven
> angles at `transition` pace). The teaching arrives **after** the sweep, in the STAMP that resolves the
> verdict.

### ARC — glow-on

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **glow-on** | a feedback/return relationship *activates* on its **own** beat — the loop lights up so it does not crowd the spine | a `long` ≈21 or `dense` ≈28 beat (it teaches a relationship); each loop gets a *separate* beat | the arc swaps dim→saturated with its label faded in; the masthead gives the quality arc and the return loop one beat **each** so neither competes |

> An arc must light on **its own beat** — two loops glowing at once is the element-level version of
> art-direction's "no focal point." Give each return-edge its own held moment.

### STAMP — resolve

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **resolve** | a label *settles into a verdict* — the judgement the whole sequence was building toward | a **`dense` ≥24-hold "Ah-HA!" beat**; then the verdict rests at full opacity into the `poster` | the verdict word cross-dissolves in and **holds legibly** (never read mid-dissolve); the kept candidate is ringed, the verdict caption stated once and held |

### HALO — attention-pulse

| Verb | (a) Communicates | (b) Role · holds | (c) Treatment |
|---|---|---|---|
| **attention-pulse** | "look *here*" — a ring draws the eye to the **current** element | rides the current node's dwell; the pulse is *within* the hold | a translucent ring whose radius breathes with the node (the masthead's `halo` peak is exactly this — a slow rise, paired with the node's breathe) |

> HALO is a *modifier*, not a stage of its own: it attaches to whichever element is current and breathes
> with it. It never pulses on a settled/done element — that would mislead the eye.

## 4. Fit-the-environment rules

A verb that fits its element can still be *wrong* for the figure. The motion must suit the diagram's whole
visual environment:

1. **Pace matches density.** A dense figure (many nodes, a long rail) wants *slower* rides and longer
   breathes so the eye is not whipped; a sparse figure can move briskly. Read the figure's element count
   before you set holds.
2. **No element fights its neighbour.** Two things must not demand the eye in the same beat. Give each
   ARC its own `glow-on` beat; never `flip` two gates simultaneously; a HALO marks **one** current
   element. Concurrency in time is the temporal twin of compositional clutter.
3. **The "Ah-HA!" beats get the ≥24 floor.** The meaning-bearing verbs — **gate:flip** and
   **stamp:resolve** (and a relationship-teaching **arc:glow-on**) — always take ≥24 holds (the `dense`
   tier clears it). This is inherited verbatim from the Motion canon's mandatory floor; it is not optional.
4. **Pure transitions stay quick.** The verbs that teach nothing new per frame — **token:ride** steps,
   **sweep:rotate-surface** angles, **node:dissolve** tweens — stay at `transition` pace (≈2–3). Slowness
   spent on a transition is slowness stolen from a beat that needed it.
5. **Always end on a settled poster.** Per the Motion canon, every figure ships a reduced-motion poster
   frame and dwells on it (`poster` ≈44–52) before the loop restarts — both feedback arcs calm, the verdict
   resolved, no competing labels. The settled poster is what lets a loop read as *done*, not as churn.

## 5. How a generator USES this

The build path, end to end — the bridge from a frame-level `TIMING.tsv` to element-level animation:

1. **Name its elements.** Decide, up front, which registry elements the figure is made of — e.g. the
   foundry conveyor is `RAIL + GATE×6 + TOKEN + STAMP`; the market-scanner is
   `SWEEP + BLIP-field + STAMP + HALO`.
2. **Pick each element's verb.** A GATE gets `latch` for routine clears and `flip` for its one spine
   state-change; the TOKEN gets `ride`; the SWEEP gets `rotate-surface`; the STAMP gets `resolve`. Choose
   the verb that *fits* — never borrow another element's motion.
3. **Emit via `diagram-primitives.sh`.** Source the library and call `prim_rail`, `prim_gate`,
   `prim_token`, `prim_sweep`, `prim_stamp`, `prim_halo`, `prim_node`, `prim_arc` instead of re-hand-rolling
   `<svg>` and copying the `<defs>`. The crafted form (and any future line-art uplift) comes for free.
4. **Tag the frames per the Motion canon's TIMING roles.** Emit each *distinct* visual state exactly once
   and write its `frame ⇥ role ⇥ holds` row to `TIMING.tsv`, choosing the role from each verb's column in
   §3 — `flip`/`resolve` rows take `dense` (≥24), `ride`/`rotate-surface` rows take `transition`, the final
   settled state takes `poster`. `reslow.sh` consumes the holds and applies the breathe-within-hold; the
   `-morph` cross-dissolves handle the `dissolve`/`arrive` tweens.
5. **Ship the poster.** Copy the settled keyframe as the reduced-motion poster and a frame-strip proof, per
   the Motion canon.

> **Forward note.** This codifies the language and its exemplar elements **now**. The *bulk* line-art uplift
> across all generators is **feedback-driven**: each maintainer finding and each expensive vision-review
> finding becomes a one-sentence reusable rule folded — via the self-improvement loop
> ([`rich-pdf-with-diagrams/references/self-improvement.md`](../../../plugins/pressroom/skills/rich-pdf-with-diagrams/references/self-improvement.md))
> — into the right home: a *frame-timing* lesson into the
> [Motion canon](../../../plugins/pressroom/knowledge/raster-toolchain.md#motion-canon--the-house-motion-policy-the-linger-directive),
> an *element-motion* lesson **here**, a *crafted-form* lesson into the primitive it names. The bar rises
> once; every future build inherits it.

---

> **Sources (the canon to cite):** the frame-level
> [Motion canon](../../../plugins/pressroom/knowledge/raster-toolchain.md#motion-canon--the-house-motion-policy-the-linger-directive)
> this layer sits above; the crafted-primitive library
> [`diagram-primitives.sh`](../toolchain/src/diagram-primitives.sh) that implements every element; the
> still-frame sibling [`art-direction-DRAFT.md`](art-direction-DRAFT.md); and the flagship generators that
> ground the verbs in working code —
> [`build-foundry-conveyor-frames.sh`](../toolchain/src/build-foundry-conveyor-frames.sh) (token *rides*,
> gates *latch*, the red→green *flip*),
> [`build-market-scanner-radar-frames.sh`](../toolchain/src/build-market-scanner-radar-frames.sh) (sweep
> *rotate-surface*, stamp *resolve*), and
> [`build-masthead-cycle-frames.sh`](../toolchain/src/build-masthead-cycle-frames.sh) (nodes *dissolve* via
> `-morph`, arcs *glow-on*, the halo *attention-pulse*). When you cite, name the element **and** its verb —
> *"a gate that rides — wrong; a gate latches (cf. foundry-conveyor)"* — so the finding is teachable and the
> generator↔reviewer loop can verify the fix.
