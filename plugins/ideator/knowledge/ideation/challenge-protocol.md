# The challenge protocol — pressure-test the emergent IDEA

> The one-copy home for **how IDEATOR adversarially challenges an idea** as it refines it. Referenced by
> the `ideate` skill, never restated. Refinement is not transcription — it is *interrogation*. The job is
> to reach **knowledge-parity** by rigorously, pragmatically challenging the emergent IDEA until it is
> unambiguous, or to surface that it is not yet ready.

> **Stance.** Default-then-ask, but *adversarial about the substance*: present a strong recommended
> answer, then **try to break the idea** on each axis before accepting it. A weak idea caught here costs
> a conversation; caught in PRODUCTION it costs a build. (The covenant:
> [`../covenant.md`](../covenant.md).)

## The challenge axes — disambiguate every shallow area

Walk these as the dialogue earns each branch (infer-first; one focused question at a time, **each with a
recommended answer + multiple-choice**). For each, name the **hidden assumption** and pressure-test it:

| Axis | The challenge (what to break) |
|---|---|
| **Problem** | Is this a real, specific, observable pain — or a vague aspiration? *"What does the actor do today when it bites, and what does that cost?"* Kill "improve UX". |
| **Actor** | Who **specifically** — a named role, not "users"? Whose problem is it *most*? If you can't name one actor, the idea is unfocused. |
| **Scope** | What is the **smallest v1** that delivers the core value? Aggressively push OUT-OF-SCOPE. A scope that "does everything" ships nothing. |
| **Success** | How will we *test* that it works? Convert "better/faster" into an observable, measurable threshold. An untestable success is a hidden ambiguity. |
| **Value & price** | Does the value (quantified) exceed the price-band? Who signs the cheque? If the economics don't close, the idea doesn't. |
| **The wedge** | Why *this*, why *now*, why *you*? What makes an actor switch and stay? "Same but new" is not a wedge. |
| **The slice** | What is the thin, end-to-end **first slice** that proves the core in days? If you can't name it, scope is still fuzzy. |
| **Stack-fit** | Does the brief's `LANGUAGE/STACK` map to a **registered** FOUNDRY value-handler? A buildable idea is one the conveyor can carry. **If the named stack has no handler, FLAG the gap here** (see *Stack-fit flag* below) — don't paper over it; an unhandled stack caught at ideation is a conversation, caught at BUILD it is a paused conveyor and a handler to author. |
| **The risks** | What are the top 2–3 ways this fails? Each unresolved risk is either *answered* or *explicitly accepted* — never silently ignored. |

## Stack-fit flag — an unsupported stack is surfaced at ideation, not at BUILD

> **WHEN an IDEA brief names a `LANGUAGE/STACK` with no FOUNDRY value-handler, the system SHALL flag the
> gap at ideation** — the cheapest place to catch it. Cross-check the brief's stack against the registered
> handlers (FOUNDRY's VALUE_HANDLER_POOL — Python · JS/TS · React · CSS · Rust · Rust-webapp · Rust-Tauri
> · FastAPI · vanilla-JS · GitHub-Actions · …). On a miss, do **not** silently accept the brief:
>
> 1. **Name the gap** plainly: "Stack `<X>` has no FOUNDRY value-handler — the conveyor can't yet carry it
>    natively."
> 2. **Offer the fork** (the same decision FOUNDRY's missing-handler gate will otherwise force later):
>    pivot to a **supported stack**, **author a new `handler-<X>`** first (governed by FOUNDRY's
>    handler-authoring discipline), or **accept it as an explicit risk** the user signs off on (the BUILD
>    will pause and decide).
> 3. **Record the resolution** into the package (the chosen stack, or the accepted-risk note) so the gap
>    is never silently rediscovered downstream.
>
> This is the ideation-side half of FOUNDRY's missing-handler pause-and-decide gate: the same gap, caught
> a station earlier and far cheaper.

## The disambiguation rule

> **THE ONLY WAY — bring your own understanding to parity, out loud.** Wherever *your* grasp of the IDEA
> is shallow, say so and resolve it — do not paper over it with a confident-sounding brief. An ambiguity
> you smooth over now becomes a question a downstream agent must stop and ask (or, worse, guesses at).
> Each resolved ambiguity is **written into the package so it is never asked again** (knowledge-parity
> compounding).

## When the idea is not ready

If a challenge axis cannot be resolved (no real problem, no namable actor, no closing economics, no
wedge), **say so plainly** and either: return to discovery (hand back to `/market-scan` for a better
opportunity), or record the gap as an explicit risk the user *chooses* to accept. Do not manufacture a
crisp brief over a soft idea — that is the most expensive kind of clarity.

## Feeding the loop

When a downstream builder later hits an ambiguity the package *should* have resolved, that
**ideation-feedback** flows back (see the `self-improve` skill): the corresponding challenge axis or the
package contract gets sharpened via a PR, so future ideations ask the missing question by default. The
spark gets sharper over time.
