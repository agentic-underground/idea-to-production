# The routing test suite — how the context-fulfilment router is proven, and how to grow it

*Maintainer-facing.* This documents the test system that proves the marketplace's routing holds:
**(a) context stays lean** — a task loads only what it needs — and **(b) every path is reachable** —
no skill/command/agent is unroutable and no route is dead. It is the *starter* for a comprehensive
routing-test system; §5 is how you extend it. It is the empirical backbone under the design RFC
[`context-routing.md`](./context-routing.md) and the user-facing [`lexicon.md`](./lexicon.md).

## 1. What is tested, and where it lives

| File | Role |
|---|---|
| [`scripts/verify-routing.sh`](../../scripts/verify-routing.sh) | **Layer 1** — the deterministic, token-free **pre-push gate** (checks R1–R8). |
| [`scripts/routing/collisions.tsv`](../../scripts/routing/collisions.tsv) | The **one central ledger** — collisions, orphans-by-design, and known defects. |
| per-skill **frontmatter** | The rest of the source of truth (each skill's own triggers + `metadata.phase`). Hybrid model: frontmatter owns per-skill facts, the ledger owns only cross-skill facts. |
| [`docs/guide/lexicon.md`](./lexicon.md) | The human **STANDARD LEXICON**, kept in sync with the ledger by check R8. |
| `scripts/routing/eval-fixtures.tsv` + `route-eval.sh` | **Layer 2** — the opt-in behavioural eval (§4). |

## 2. These are PRE-PUSH gates, not CI

The mental model is: **run it before you `git push`.**

```bash
bash scripts/verify-routing.sh            # ✓/✗/⚠ table; exit 0 iff no hard FAIL
bash scripts/verify-routing.sh --strict   # also fail on WARN (flips the warn-then-flip checks)
```

It is wired into the repo's pre-push gate ([`.pipeline/verify`](../../.pipeline/verify)) and mirrored
as a backstop job in [`.github/workflows/verify.yml`](../../.github/workflows/verify.yml) — but the
gate is the local pre-push run, not the cloud job. It follows the house style of
[`verify-prereqs.sh`](../../scripts/verify-prereqs.sh) exactly: a `section/pass/fail/warn` harness, a
`fails` counter, and `exit 0|1`.

## 3. The checks (R1–R8)

**Hard gates (green today, block a push on regression):**

- **R1 · Reachability** — every skill & command is routable (a `/command`, a quoted trigger phrase),
  and every agent is spawned-by-design (a spawn/VALUE_HANDLER marker), user-triggerable, or declared
  `orphan` in the ledger. An unroutable, undeclared section FAILs. *(Requirement b.)*
- **R2 · Ledger integrity** — every `collision` member and `orphan` key names a section that exists on
  disk; every collision has a non-empty disambiguation signal.
- **R3 · Dead slash routes** — every `/plugin:cmd` named in a description resolves. A slash that names
  **nothing** (no command, skill, or agent) FAILs unless it is a ledgered `defect`; a slash that names
  a skill with no command file WARNs (inert but not fatal).
- **R4 · Declared collisions** — an identical quoted trigger phrase claimed by **more than one**
  section must be covered by a declared collision family. An *undeclared* collision FAILs — this is
  the deterministic form of "only the required context loads". *(Requirement a.)*

**Warn-then-flip (depend on unlanded [`context-routing.md`](./context-routing.md) slices — WARN now,
flip to hard-FAIL as each slice lands, or run `--strict`):**

- **R5 · Phase tag** — every skill carries a `metadata.phase` list (RFC C1). Untagged skills *fail
  open* (treated available), so the gate is safe while tags roll out.
- **R6 · Description budget** — every `description` ≤ 60 words / 400 chars (RFC C5) — the always-on
  catalog leanness sensor.
- **R7 · Roadmap seed-wording** — every EPIC/PLAN carries `Phase` + `Loads` routing-tags whose `Loads`
  name real skills (RFC C3).
- **R8 · Lexicon ↔ ledger sync** — every collision family and defect in the ledger is documented in
  [`lexicon.md`](./lexicon.md), mirroring the KAIZEN byte-identity covenant.

### The ledger format

`collisions.tsv` is TAB-separated, `#`-commented, with three record kinds keyed by the first column:

```
collision   C4-review-critique   deliver:pr-review,design:ui-review,…   the ARTEFACT under review   note
orphan      deliver:flaky-test-fixer   spawned-only   TEST/STORY stations   automation agent, no user trigger
defect      publish:design-review      /publish:design-review   DEAD-ROUTE   command file missing (O1)
```

## 4. Layer 2 — the behavioural eval (opt-in, token-costly)

Layer 1 proves the *wiring* is sound. It cannot prove that **natural wording actually routes** to the
intended section and leaves others dormant — that is a model behaviour, so it needs a model in the
loop. That is `scripts/routing/eval-fixtures.tsv` (`phrase ⇥ expected section(s) ⇥ must-NOT-load`) run
by `scripts/routing/route-eval.sh` through a judge subagent. It is **never** in the pre-push gate (it
costs tokens and is non-deterministic); run it on demand or under `/loop`, and log results like
`scorecard`. Seed fixtures target the highest-risk collision zones (C0 idea-intake, C4 review, C5
chart) — the phrasings most likely to mis-route.

## 5. How to extend it (this is a *starter*)

- **A new skill/command/agent** → give it a clear trigger in its frontmatter, or a `/command`, or (if
  spawned-only) add an `orphan` row. R1 tells you if it's unroutable.
- **A new intended overlap** (two sections that *should* share an intent) → add a `collision` row with
  the disambiguating axis, and a row in [`lexicon.md`](./lexicon.md) §4 (R8 enforces both).
- **You fixed a defect** (added the missing command) → delete its `defect` row; R3 will confirm.
- **Flip a warn-then-flip check** once its RFC slice lands → remove the check from the WARN set in
  `verify-routing.sh` (or gate CI with `--strict`).
- **A new behavioural fixture** → append a `phrase ⇥ expected ⇥ must-not-load` row to
  `eval-fixtures.tsv`.

### Prove the gate itself works (regression test of the test)

```bash
# an untracked dead route → R3 RED
#   (temporarily add `Trigger with /deliver:bogus` to any SKILL.md description, run, then revert)
# an undeclared shared phrase → R4 RED
#   (add the same quoted phrase to two skills, run, then revert)
```

Both were verified to turn the gate RED (and reverting returns it GREEN) when this suite landed.

---

**See also:** [`lexicon.md`](./lexicon.md) (the jargon this proves),
[`context-routing.md`](./context-routing.md) (the design the warn-then-flip checks enforce),
[`verify-prereqs.sh`](../../scripts/verify-prereqs.sh) (the house-style harness this mirrors).
