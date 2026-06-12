# Certainty Markers — the articulation protocol

> For the whole conveyor. A marketplace-wide standard for tagging consequential statements so the
> **reasoning travels with the rule.** Distilled from the RUST_WEBAPP_API knowledge package, whose
> first-time-every-time guarantee rests on exactly this discipline.

Most rules fail not because they are wrong but because the next reader cannot see *why* they exist,
so they "improve" them back into the bug they were preventing. A certainty marker fixes this: it
states the certainty level **and** carries the reason, so an implementer never has to *trust* a
rule blind — they can *see* it.

> **IMPORTANT — THE ONLY WAY:** When a marker and your instinct disagree, **the marker wins.** It
> was written *after* the mistake, not before.

---

## The four markers

| Marker | Means | Must carry |
|---|---|---|
| `> **IMPORTANT — THE ONLY WAY:**` | The single sanctioned approach. There is no acceptable alternative; do not deviate. | The approach, stated unambiguously. |
| `> **GUARDRAIL:**` | A rule that prevents a specific, known production failure. Breaking it reintroduces a bug already paid for. | What it protects against (the failure it fences). |
| `> **ANTI-PATTERN (DO NOT):**` | A forbidden or outdated approach. | **Both** the *why* (what it breaks) **and** the *why-not* / what to do instead. |
| `> **WORKED EXAMPLE:**` | The concrete, real reference for an abstract rule. | A specific, true instance (not a hypothetical). |

A bare imperative ("always do X") is weaker than the same rule marked and reasoned. Prefer the
marked form for any statement whose violation has a real cost.

---

## How to use them

1. **Reserve `THE ONLY WAY` for genuine single-path decisions** — places where a second option is a
   defect, not a preference. Overuse dilutes it.
2. **Every `GUARDRAIL` names its failure.** "Keep the empty `[build]` table" is weak; "keep the
   empty `[build]` table — without it `@vercel/rust` 1.3.0 crashes reading `build.target`" is a
   guardrail. The symptom→cause→fix form lives in `guardrails-ledger.md`.
3. **Every `ANTI-PATTERN` carries why **and** why-not.** The reader must leave knowing both what
   breaks and what to do instead.
4. **`WORKED EXAMPLE` must be real.** It is the proof the abstract rule is achievable; a fabricated
   example is worse than none.

> **WORKED EXAMPLE:** The `rust-webapp-rollout` skill tags every consequential line this way —
> `THE ONLY WAY` for the hybrid manifest, a `GUARDRAIL` for the empty `[build]` table, an
> `ANTI-PATTERN` for a separate `api/Cargo.toml`, and a `WORKED EXAMPLE` from the shipped `forge`
> project for each. That tagging is *why* a blind build reaches production first time.

---

## Where markers are expected

- **High-stakes knowledge docs** (the pillars, `testing/test-policy.md`, `architecture/pure-core.md`,
  this `protocols/` set) and **value-handler agents** SHOULD use markers for any rule with a real
  cost of violation.
- **Skills** carrying deploy/build/security discipline (e.g. `rust-webapp-rollout`, `sentinel`'s
  gates) SHOULD use them throughout.
- Ordinary prose, indices, and READMEs need not be marked — markers are for *consequential* rules,
  not decoration.

---

## ♻️ Self-improvement

When a rule is violated despite being written down, the fix is usually not a louder rule but a
*better-articulated* one: upgrade it to the correct marker, add the missing why/why-not, or attach
a worked example. Each pass should make the rule harder to misread than the last. See
`architecture/kaizen-covenant.md`.
