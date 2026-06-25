# 02 — Stations: The Carriage of Value from IDEA to PRODUCTION

> **Purpose:** The process model. How a solution is carried, station by station, from a raw
> IDEA to a verified PRODUCTION deployment — and why tests are the coordinates that locate
> the work.
>
> **TL;DR:** Value moves down a fixed line of stations. Each station transforms and
> **certifies** the freight before it advances. Coordinates (failing tests) are placed at
> the SPEC station and turned green at the IMPLEMENT station. Nothing reaches PRODUCTION
> that skipped a station.

---

## 1. The line

```
IDEA ─▶ BRIEF ─▶ SPEC (EARS) ─▶ COORDINATES ─▶ IMPLEMENT ─▶ STORY ─▶ GATE ─▶ BUILD ─▶ DEPLOY ─▶ VERIFY
                                (failing tests)  (green)              (CI)   (prebuilt)         (prod)
```

Each station has an **entry condition**, a **transformation**, and an **exit certificate**.
Freight may not advance without its exit certificate. The handler's job is to carry one
**vertical slice** (`00 §2.5`) along this whole line, not to do one station for the whole
product and then the next.

---

## 2. The stations

| Station | Entry | Transformation | Exit certificate |
|---|---|---|---|
| **IDEA** | a raw intent | name the user-visible outcome of one thin slice | a one-sentence slice statement |
| **BRIEF** | slice statement | identify which crate owns the new logic; name the pure module(s) | a target crate + module name |
| **SPEC (EARS)** | target module | write the requirements as `input → expected output` pairs, including edge cases (empty, max, unicode, whitespace) | an enumerated requirement list |
| **COORDINATES** | requirement list | write the **failing tests** that pin each requirement against a pure function | tests exist and **fail for the right reason** |
| **IMPLEMENT** | failing coordinates | write the minimum code to turn every coordinate green; no speculative abstraction | all coordinates green locally |
| **STORY** | green core | wire the thin shells (UI component, function handler) that consume the proven core | the slice works end-to-end by hand |
| **GATE** | wired slice | run the full quality gate | `cargo xtask ci` green (`07`) |
| **BUILD** | gated slice | `vercel build` locally (WASM site + cross-compiled function) | `.vercel/output` produced (`05`) |
| **DEPLOY** | local build | `vercel deploy --prebuilt` (preview, then prod) | a live URL |
| **VERIFY** | live URL | run the verification matrix against the deployment | every row passes (`05 §verification`) |

> **GUARDRAIL:** A station's exit certificate is mandatory. Do not "build" before the gate
> is green; do not "deploy" before the build succeeds; do not call a slice done before
> VERIFY passes against the *deployed* artefact (not just localhost). Skipping a station is
> how silent breakage reaches production.

---

## 3. Tests as coordinates — the heart of the line

The COORDINATES and IMPLEMENT stations are where the quality-first creed becomes mechanical.

A failing unit test is a **coordinate in multidimensional logical space**: an
`input → expected output` assertion against a *pure* function that pins one point (or a
tightly-constrained region) in the space of all possible implementations. You navigate from
SPEC to PRODUCT by **turning each coordinate green**.

> **IMPORTANT — THE ONLY WAY:** Place the coordinate *before* the implementation, and run
> it to confirm it **fails for the right reason** before you make it pass. A test written
> after the code is a description; a test written before is a location. Only the location
> tells you where the solution must go.

How to place good coordinates:
1. **Extract the pure core first.** If the logic is tangled with DOM/IO/network, pull the
   decidable part into a pure function in `core`. A coordinate can only be placed in a pure
   space — side effects blur the location.
2. **One axis per edge case.** Empty input, maximum length, unicode, whitespace, the
   boundary value exactly at the limit — each is a new axis that narrows the region until
   exactly one implementation satisfies all coordinates.
3. **Bug fixes get a negation coordinate.** A fix's test is an input that must *not* yield
   the corrupt output. The coordinate *is* the bug's negation.
4. **Invariants get a `proptest`.** When a property must hold for *all* inputs ("never
   panics", "valid input always round-trips"), pin it with a property test, not a handful
   of examples.

> **WORKED EXAMPLE:** `forge-core`'s `Greeting` is pinned by coordinates that say:
> `""` and `"   "` → `EmptyName`; 65 chars → `TooLong { max: 64, got: 65 }`; exactly 64
> chars → `Ok`; `"  Ada  "` → trims to `"Ada"`; plus two `proptest` invariants —
> *every non-blank ≤64-char name appears in its rendered message*, and *construction never
> panics for any string whatsoever*. Together these coordinates leave exactly one correct
> `Greeting::new`. See [`templates/crate-core-lib.rs.tmpl`](templates/crate-core-lib.rs.tmpl).

---

## 4. The vertical slice — why thin, why end-to-end

> **IMPORTANT — THE ONLY WAY:** Carry one **thin** slice along the *entire* line before
> starting the next. The first slice through a new project is the "hello world" slice whose
> only job is to prove the shape: one domain type, one typed error, real validation,
> exhaustive coordinates, one shared component, the WASM shell, and one function — deployed
> and verified.

**Why thin:** a slice you can review in one sitting is a slice whose coordinates you can
actually enumerate. A fat slice hides un-pinned behaviour.

**Why end-to-end:** the value of the architecture is *reuse without drift*. You only prove
that by carrying a single behaviour from `core` all the way to a verified `/api` response
and a rendered WASM page. A slice that stops at "the core compiles" has not been carried;
it is freight abandoned between stations.

> **ANTI-PATTERN (DO NOT):** Build the whole core, then the whole UI, then the whole API,
> then try to deploy. **Why-not:** you discover the deploy-station problems (`04`, `05`,
> `06`) only at the very end, with a large diff, when they are most expensive to diagnose.
> The first slice must reach VERIFY *fast* so the line itself is proven before volume flows
> through it.

---

## 5. Parallelism falls out of the geometry

Because each coordinate is self-contained and references only its pure module, the failing-
test set is a **maximally parallel work graph**. Independent agents solve disjoint
coordinates without coordination. The senior move when planning a larger build:

1. **Name the pure modules** (the new `core` types/functions).
2. **Write the failing coordinates** that pin each function.
3. **Tier the work:** all new pure modules + their coordinates run concurrently (PRIMARY);
   dependent selectors/glue next (SECONDARY); shared-file merges (the core lib everyone
   extends, the render orchestrator everyone wires) last, in disjoint regions (TERTIARY).
4. **Hand each tier's disjoint units to parallel workers.** The build becomes "make the
   coordinates green," and persistent parallelism is a property of the geometry, not an
   act of coordination.

---

Continue to [`03-toolchain-and-environment.md`](03-toolchain-and-environment.md).
