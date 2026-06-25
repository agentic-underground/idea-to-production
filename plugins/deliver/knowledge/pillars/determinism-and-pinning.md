# Determinism & Pinning — "latest is a future incident"

> A facet of **waste elimination** (`pillars/waste-elimination.md`) and **quality-first**
> (`pillars/quality-first.md`). Distilled from the RUST_WEBAPP_API package: the discipline that lets
> a build reach production **first time, every time** instead of rediscovering a solved problem.

A non-deterministic build is waste waiting to happen. Every "it worked yesterday" is rework: time
spent re-diagnosing a difference the build was supposed to hold constant. The cure is to **pin what
must be constant** and to **scaffold from a single zero-drift source** so two builds of the same
thing are the same thing.

---

## 1. Pin everything that affects the output

> **IMPORTANT — THE ONLY WAY:** "Latest" is not a version; it is a future incident. Pin the
> toolchain, the framework, the runtime, the build tools, and the language edition to a **proven
> version matrix** — a set of versions known to work *together*.

- A version matrix is canonical: one table, every component, the role each plays. Templates and
  manifests are written against it.
- Lockfiles are committed. A floating range (`^`, `~`, `*`, `latest`) in a manifest is a
  reproducibility hole — flag it (this is also a `secure` scan-dependencies finding).

> **GUARDRAIL:** A version bump is its **own vertical slice** with its own full GATE + (where
> relevant) DEPLOY + VERIFY pass. Changing a pinned version silently, inside an unrelated change, is
> how a green PR ships a latent incident. If you change a matrix entry, you are off the proven path
> until the slice re-certifies it.

---

## 2. Scaffold from a zero-drift source

> **IMPORTANT — THE ONLY WAY:** Canonical files are **copied from templates**, not hand-authored
> from memory. The template is the exact shipped file, parameterized, with every guardrail already
> applied. Hand-authoring reintroduces drift and re-opens closed guardrail entries.

- A template carries a **placeholder legend** and a **file→destination map**; substitution is a
  single consistent pass. Inconsistent substitution (the crate name here, the `--package` flag
  there) is itself a classic build break — substitute *all* placeholders, once.
- The template set is the memory of "what good looks like." Improving the template improves every
  future build; fixing a bug only in a generated copy leaves the template (and the next build) wrong.

> **WORKED EXAMPLE:** `rust-webapp-rollout/references/templates/` is the source of zero drift for
> the Rust/WASM/Vercel stack — the hybrid `Cargo.toml`, the `vercel.json`, the `.cargo/config.toml`
> with its mandatory empty `[build]` table. A new build copies them and substitutes four
> placeholders; it never re-derives them, so it never re-hits the saga in the guardrail ledger.

---

## 3. Why this is waste elimination

- **Rediscovery is the most expensive waste** — a problem solved once and then re-encountered costs
  the original diagnosis *again*, usually later, with a bigger diff, when it is hardest to find.
  Pinning + templates convert that recurring cost into a one-time cost.
- **Determinism makes the gate meaningful.** A gate can only certify freight if the same input
  produces the same output. Non-determinism turns a green gate into a coin flip.
- **Determinism makes coordinates valid.** A test is a coordinate (`testing/test-policy.md`) only if
  the space it pins is stable; a drifting toolchain moves the target under the test.

---

## ♻️ Self-improvement (halve the distance to perfection)

Every version drift discovered becomes a matrix update; every hand-authoring mistake becomes a new
or improved template; every inconsistent-substitution break becomes a tightened placeholder legend.
Each pass leaves the next build more deterministic than the last — at least halving the remaining
chance of an "it worked yesterday." See `architecture/kaizen-covenant.md`.
