# The missing-handler gate — pause, decide, defer, resume

> The one-copy home for **what FOUNDRY does when a required VALUE_HANDLER is absent**. It is the governing
> protocol for the `builder-lead.md` Phase 4.5 roster cross-check and `builder/SKILL.md` §8: a missing
> handler **PAUSES** the plan (it does *not* silently route the item to the nearest handler), surfaces a
> **3-way decision gate**, and — on the BOTH/DEFER path — wires the **awaiting-handler ↔ DEFERRED
> handler-creation** pairing through the roadmapper DEFER/RESTORE/RESUME idioms. Referenced, never
> restated.

## Why pause, not degrade

The old behaviour was *detect-and-degrade*: a missing handler was silently routed to the nearest
registered one. That ships a DEGRADED build the human never chose. A stack with no handler is a
**decision point**, not a routing detail — building handler-less risks the wrong tool quietly carrying a
class of work it does not understand. So detection now **PAUSES** and asks. The human (or `founder`)
chooses; the conveyor acts on the choice. (This is the upgrade from card #23.)

> **Detection is a HALT, not a WARN.** When a Phase-4 decomposition names a `VALUE_HANDLERS required` that
> is not registered in [`agent-roster.md`](agent-roster.md) **and** has no agent file under
> `${CLAUDE_PLUGIN_ROOT}/agents/`, builder-lead **stops** before emitting the plan and presents the gate
> below. It does **not** route the item to the nearest handler on its own authority.

## The 3-way decision gate (card #24)

On the pause, surface exactly three options — the roadmapper GO / DISCUSS / DEFER-idiom mapped onto the
handler gap. Present them, then act on the chosen path:

### Option 1 — BUILD HANDLER FIRST
Author `handler-<stack>` via the four-wave research → synthesis → build → review pipeline, **governed by
the handler-authoring discipline** ([`handler-authoring-discipline.md`](handler-authoring-discipline.md) —
pinned version matrix + FORBIDDEN list + KAIZEN covenant). Register it in the roster and the
VALUE_HANDLER_POOL. **Then RESUME** the paused original build with the real handler. No DEGRADED_CAPABILITIES
— the item is built right, just later.

### Option 2 — MVP WITH EXISTING
Route the item to the **nearest registered handler** *as a deliberate, disclosed choice* — and record
**`DEGRADED_CAPABILITIES`**: which capabilities the nearest handler cannot deliver for this stack, and the
risk. **This disclosure SHALL be written into `docs/internal/FOUNDRY_PLAN.md`** under a
`## DEGRADED_CAPABILITIES` heading (item id · missing handler · substitute handler · what is degraded).
A degrade is only safe when it is *visible*; an undisclosed degrade is the failure this gate exists to
prevent.

### Option 3 — BOTH (MVP now + handler later)
Do the MVP (Option 2, with its `DEGRADED_CAPABILITIES` disclosure) **and** schedule the real handler:
1. Raise the new-handler feedback via **`/operate:gemba`** (capture → route → raise) so the gap
   becomes a tracked, de-duplicated issue instead of evaporating.
2. File a **DEFERRED "Create handler-<stack>"** roadmap item (the handler-creation work, to be built under
   the authoring discipline).
3. Mark the **original** build item **awaiting-handler**, paired with that DEFERRED item (card #26).

> **EARS (cards #23/#24).**
> - WHEN a required value-handler is absent THE SYSTEM SHALL pause (not silently degrade).
> - WHEN the missing-handler pause fires THE SYSTEM SHALL present the 3-way gate and act on the choice.
> - IF option MVP is chosen THEN the system SHALL emit `DEGRADED_CAPABILITIES` and disclose it in
>   `FOUNDRY_PLAN.md`.

## Deferral + resumption — awaiting-handler ↔ DEFERRED handler item (card #26)

The BOTH path creates a **pair** that the roadmapper DEFER/RESTORE/RESUME idioms
([`../../skills/roadmapper/SKILL.md`](../../skills/roadmapper/SKILL.md) §11.6 RESUME, §11.7 DEFER/RESTORE)
manage. The two items are explicitly linked so neither is lost:

| Item | Status | Pairing note |
|---|---|---|
| The original build item | **awaiting-handler** (paused; kept out of the active build order) | `> AWAITING-HANDLER: paired with #<H> "Create handler-<stack>"` |
| The handler-creation item `#<H>` | **DEFERRED** (per roadmapper §11.7 DEFER) | `> DEFERRED: <date> — creates handler-<stack> for #<orig>` |

**WHILE awaiting-handler** (state-driven): the original SHALL stay paused and **visibly paired** with its
DEFERRED handler item — it never silently re-enters the build order, and its pairing note names the
handler item it waits on.

**WHEN the handler-creation item completes** (event-driven): the system SHALL surface the paired
awaiting-handler item for **RESTORE** (roadmapper §11.7: status awaiting-handler → PENDING) **+ re-plan**
with the now-real handler (re-run Phase 4 decomposition for that item; the roster cross-check now finds
the handler, so the plan emits with no degrade). Optionally arm this transition as a durable follow-up via
the `tf` registry / `.i2p/scheduled-jobs.json` so the RESTORE prompt fires when the handler lands.

> **EARS (card #26).**
> - WHILE a build is awaiting-handler THE SYSTEM SHALL keep it paused and visibly paired with its DEFERRED
>   handler item.
> - WHEN a handler-creation item completes THE SYSTEM SHALL surface the paired awaiting-handler item for
>   RESTORE + re-plan with the real handler.

## Ideation catches it earlier — stack-fit (card #23)

The cheapest place to catch a handler gap is *ideation*, before any build cost. The IDEATOR **Stack-fit**
challenge axis ([`../../../ideator/knowledge/ideation/challenge-protocol.md`](../../../ideator/knowledge/ideation/challenge-protocol.md))
flags an IDEA brief whose `LANGUAGE/STACK` field names a stack with no FOUNDRY value-handler — so the gap
surfaces as a conversation, not a paused build. A gap *accepted* at ideation becomes the same 3-way gate
when the item reaches FOUNDRY; a gap *missed* at ideation is the rework this axis exists to prevent.
