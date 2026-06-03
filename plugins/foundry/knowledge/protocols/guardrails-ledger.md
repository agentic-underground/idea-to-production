# The Guardrails Ledger — turning trial-and-error into first-time-every-time

> For the whole conveyor. The pattern for capturing every known failure mode so it is never
> rediscovered. Distilled from the RUST_WEBAPP_API package, whose `06-guardrails-and-antipatterns.md`
> turned a multi-hour debugging saga into a copy-paste-safe build.

A **guardrail** fences a specific, known failure. A **ledger** is the consolidated, no-ambiguity
record of them. Together they are how a project stops paying for the same mistake twice: the cost of
a bug is paid *once*, here, and every future build inherits the fix.

> **IMPORTANT — THE ONLY WAY:** Every guardrail carries its own reasoning, so an implementer never
> has to *trust* the rule — they can *see* why it exists. A rule without its reason gets "improved"
> back into the bug it prevented. Use the certainty markers (`protocols/certainty-markers.md`).

---

## The ledger entry shape

Every entry is **symptom → cause → fix**, in that order, so a reader who hits the *symptom* finds
the *cause* and the already-known *fix* without re-diagnosing:

```
### <ID> — <one-line title>
- **Symptom:** what you observe (the error text, the broken behaviour).
- **Cause:** the underlying reason (the mechanism, not the guess).
- **Fix → <MARKER>:** the resolution, tagged GUARDRAIL / THE ONLY WAY / ANTI-PATTERN.
```

Group entries by area (build/toolchain, runtime, deploy/platform, …) and give each a stable ID so
other docs and code comments can cite it (`see ledger B3`).

> **WORKED EXAMPLE:** `rust-webapp-rollout/references/06-guardrails-and-antipatterns.md` entry **B3**:
> *Symptom* — every function invocation 500s with `Missing AWS_LAMBDA_FUNCTION_NAME`; *Cause* —
> `vercel_runtime` 1.x pulls `lambda_runtime`, which eagerly `expect()`s AWS env vars Vercel never
> sets; *Fix → THE ONLY WAY* — use `vercel_runtime = "2"` (hyper-based). A reader who sees that 500
> never re-walks the multi-hour diagnosis.

---

## The FORBIDDEN list

A ledger should end with a consolidated **FORBIDDEN list**: a table of `Forbidden | Why forbidden |
Do this instead`. It is the fast index — a reviewer (human or agent) scans it before approving, and
each row points back to the ledger entry that earned it. *(Foundry's `reviewer` and the `sentinel`
plugin's gates both consult the relevant FORBIDDEN list.)*

> **GUARDRAIL:** A FORBIDDEN list with no reasons is a wish list. Every row names the failure it
> prevents and the sanctioned alternative — otherwise the rule erodes the first time it is
> inconvenient.

---

## Where ledgers live

- **Domain/stack ledgers** live with the skill that owns the domain (e.g. the Rust rollout ledger
  in `skills/rust-webapp-rollout/references/`). They are stack-specific and detailed.
- **This doc** is the *pattern* every ledger follows — define once, obey everywhere.
- A guardrail discovered mid-build that is genuinely cross-cutting (not stack-specific) is promoted
  into the relevant pillar or protocol doc, not buried in a single skill.

---

## ♻️ Self-improvement (the ledger is the memory)

> **IMPORTANT — THE ONLY WAY:** Every new failure mode discovered in real work becomes a new ledger
> entry **before** the slice that hit it is closed. The ledger is the project's memory; unmaintained,
> the same bug returns. With it, the build compounds toward first-time-every-time — each entry at
> least halves the chance that class of failure ever recurs. See `architecture/solid-covenant.md`.
