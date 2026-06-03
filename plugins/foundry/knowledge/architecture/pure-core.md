# The Pure Core — the geometry that makes quality physical

> A short, load-bearing articulation distilled from the RUST_WEBAPP_API package. It sharpens what
> Hexagonal (`architecture/hexagonal.md`) and Clean Architecture (`architecture/clean-architecture.md`)
> already teach into the single move that makes tests-as-coordinates (VALUE_FLOW §7) and maximal
> parallelism *physically possible*.

## The move

> **IMPORTANT — THE ONLY WAY:** Extract the **decidable core** — the logic that must be correct —
> into a **pure** module: no I/O, no UI, no platform code, no network, no panics. Everything else
> (DOM, HTTP, render, filesystem) is **thin wiring** that *consumes* the proven core. Dependencies
> flow **one way only**, inward toward the core; a reverse edge is a BLOCKING defect, not a style nit.

```
        pure core   (logic, validation, typed errors, tests — depends on nothing)
         ^      ^
         |      |
     shared-ui   server/glue
        ^   ^         ^
        |   |         |
      web  mobile   api / handler   (thin shells — no decidable logic)
```

## Why it is the quality strategy, not bureaucracy

- **Testability → coordinates.** A coordinate (a precise `input → expected output` test) can only be
  placed in a *pure* space — side effects blur the location. A pure core is the only place every
  requirement can be pinned by a cheap, fast, deterministic unit test.
- **Reuse without drift.** Web, mobile, and the API call the *same* core, so behaviour cannot diverge
  between platforms. The product can never say one thing on the web and another in the API.
- **Reviewability.** The one-way rule is a bright line a reviewer (human or agent) enforces
  mechanically: grep for a forbidden edge, block the change.
- **Security.** Untrusted input is validated in the core (parse-don't-validate) before anything acts
  on it; the shells are thin consumers of already-valid values.
- **Parallelism falls out of the geometry.** Because each coordinate references only its pure module,
  the failing-test set is a maximally parallel work graph: disjoint coordinates against disjoint pure
  modules are solved by independent handlers with no shared mutable context. The only serialization
  points are genuinely shared files.

> **ANTI-PATTERN (DO NOT):** Let the core depend on the UI, a transport-specific serialization
> concern, or anything with I/O. **Why-not:** it instantly makes the core impure, so it can no longer
> be coordinate-d with cheap deterministic tests, and platform-specific bugs leak into the part that
> is supposed to be universally correct. **Instead:** keep the dependency one-way; push the impure
> concern outward into a thin shell validated at the story/system level.

> **WORKED EXAMPLE:** `rust-webapp-rollout`'s crate graph — `core ← ui ← {web, mobile}` and
> `server → core`, with the serverless function a thin shell over `server`. The `core` crate forbids
> `unwrap`/`expect`/`panic!` outside tests; every requirement is a coordinate against it; the shells
> carry no decidable logic. See `skills/rust-webapp-rollout/references/01-architecture-blueprint.md`.

## Relationship to the other lenses
This is the *minimal, universal* statement; the fuller treatments live alongside it:
`architecture/hexagonal.md` (ports & adapters), `architecture/clean-architecture.md` (dependency
rule), `architecture/untestable-patterns.md` (what impurity costs you). When they disagree on
detail, they agree on this: **the decidable core is pure, and the wiring is thin.**
