---
name: dependency-audit
description: >
  Supply-chain audit of a project's third-party dependencies. Parses package manifests and
  lockfiles across ecosystems (npm/pnpm/yarn, pip/Poetry/uv, Go modules, Cargo, RubyGems,
  Maven/Gradle), then flags: known-vulnerable versions (via the ecosystem's native advisory
  tooling), unpinned/floating ranges, abandoned or unmaintained packages, and typosquat-shaped
  names. Trigger with /dependency-audit [path]. Produces findings consumable standalone or by
  /security-gate. Self-improving: every new ecosystem or advisory source is folded into the
  reference.
metadata:
  type: scanner
  lens: supply-chain
  output: findings (markdown) → DEPENDENCY-FINDINGS.md or security-gate report
model: claude-haiku-4-5
---

# DEPENDENCY-AUDIT

The third dimension of a pre-release security pass. `pii-audit` checks *your data*, `secret-scan`
checks *your credentials*, `dependency-audit` checks *the code you didn't write but ship anyway* —
both whether it is **safe to run** (vulnerabilities) and whether you are **allowed to ship it**
(licence compatibility).

---

## Quick start

```bash
/dependency-audit            # audit the current repo's dependencies
/dependency-audit ./service  # audit a specific subproject
```

---

## What it checks

| Check | Question | Default risk |
|---|---|---|
| **Known vulnerabilities** | Does any installed version have a published advisory? | CRITICAL/HIGH per advisory severity |
| **Floating/unpinned versions** | Are versions ranges (`^`, `~`, `*`, `latest`) instead of pinned + locked? | MEDIUM — reproducibility & supply-chain risk |
| **Lockfile present & consistent** | Is there a lockfile, and does it match the manifest? | HIGH if absent (non-reproducible builds) |
| **Abandoned / unmaintained** | Last release age, archived flag, deprecation notice | LOW–MEDIUM |
| **Typosquat shape** | Name is an edit-distance-1 lookalike of a popular package | HIGH (deliberate-attack signal) |
| **Install scripts** | Does a dep run postinstall/build scripts (npm)? | MEDIUM — review surface |
| **Licence compatibility** | Is each dep's licence compatible with how this project is distributed? | CRITICAL strong-copyleft conflict · HIGH unknown/missing licence · MEDIUM unmet attribution |

---

## Ecosystem detection

Detect by manifest/lockfile presence (see [`references/ECOSYSTEMS.md`](references/ECOSYSTEMS.md) for the full table):

| Ecosystem | Manifest | Lockfile | Native advisory tool |
|---|---|---|---|
| npm/pnpm/yarn | `package.json` | `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` | `npm audit --json` |
| Python (pip) | `requirements*.txt` | `requirements.lock` / hashes | `pip-audit` |
| Python (Poetry/uv) | `pyproject.toml` | `poetry.lock` / `uv.lock` | `pip-audit` / `uv pip audit` |
| Go | `go.mod` | `go.sum` | `govulncheck` |
| Rust | `Cargo.toml` | `Cargo.lock` | `cargo audit` |
| Ruby | `Gemfile` | `Gemfile.lock` | `bundle audit` |
| Java | `pom.xml` / `build.gradle` | — | OWASP dependency-check |

**Approach:** prefer the ecosystem's *native* advisory tool when it is available in the
environment (it has the freshest data and exact resolution). Run it, parse its JSON, and map its
severities into the SENTINEL risk scale. When the native tool is **not** available, fall back to
static manifest analysis (pinning, lockfile, age, typosquat) and clearly mark vulnerability
coverage as **"advisory tool unavailable — static checks only"** (no-silent-caps: never imply
full vuln coverage when only static checks ran).

---

## Licence compatibility (the second lens)

The vuln audit asks *"is this dependency safe to run?"*; this lens asks *"are we allowed to **ship** it
the way we distribute?"* — a separate failure mode that bites at release or open-source time, not at
runtime. It **complements** the vulnerability audit and never duplicates it: a dependency can be vuln-free
and still licence-incompatible.

**Detect each dependency's licence** (the SPDX identifier) from the most authoritative source available:
the lockfile/manifest licence field, the installed package's `LICENSE`/`COPYING` file, or the registry
metadata (`npm view <pkg> license`, `pip show`, `cargo metadata`, `go-licenses`). Cover **transitive**
deps, not just direct ones — most copyleft surprises arrive transitively. Then assess against the
project's **intended distribution** (proprietary/closed binary, permissively-licensed open source,
SaaS/network service, or internal-only — read `LICENSE`/`.sentinel` policy if present, else state the
assumption):

| Licence class | Examples | Flag when distributed as | Default risk |
|---|---|---|---|
| **Strong copyleft** | GPL-2.0/3.0, AGPL-3.0, SSPL | proprietary or permissive OSS (AGPL/SSPL also bite a SaaS) | CRITICAL — reciprocal source-disclosure obligation |
| **Weak copyleft** | LGPL, MPL-2.0, EPL | proprietary, only if linkage doesn't honour the terms | HIGH/MEDIUM by linkage |
| **Permissive (attribution)** | MIT, BSD, Apache-2.0, ISC | any — but attribution/NOTICE must ship | MEDIUM if attribution unmet |
| **Unknown / missing** | no SPDX id, no LICENSE file, "UNLICENSED" | any | HIGH — default is all-rights-reserved, not "free" |

Surface each conflict as a **finding** in the shared format below (`Type: licence`), with the SPDX id and
the obligation it imposes as the `Detail`. This is the dependency-side analogue of FOUNDRY's
LICENSING-REVIEWER — when that reviewer runs on a diff it defers to these findings; standalone, this lens
is the whole-tree sweep.

---

## Finding format (shared with SENTINEL)

```markdown
**Package:** name@version  (ecosystem)
**Manifest:** `/path/to/manifest:LINE`
**Type:** [vuln | unpinned | no-lockfile | abandoned | typosquat | install-script | licence]
**Risk:** [CRITICAL | HIGH | MEDIUM | LOW]
**Detail:** [advisory ID + summary | "floating range ^1.2" | "last release 2019, archived" | "edit-distance-1 of <popular>" | "GPL-3.0 — reciprocal source disclosure, incompatible with proprietary distribution" | "no SPDX id / no LICENSE — defaults to all-rights-reserved"]
**Fix:** [bump to X.Y.Z | pin + lock | replace with <maintained alt> | remove | replace with permissively-licensed alt | obtain licence clarification | satisfy attribution/NOTICE]
**Source:** [npm-audit | pip-audit | govulncheck | static-analysis | licence-metadata]
```

---

## Output

- **Standalone:** `DEPENDENCY-FINDINGS.md` — summary table (counts by severity), findings by
  ecosystem, a prioritised remediation list (vulns first, then licence conflicts, then pinning/
  lockfile hygiene), appendix of manifests parsed and which tools ran.
- **Via `/security-gate`:** return the findings section for consolidation.

---

## Propose the pin — never auto-pin (human-gated)

Unpinned and abandoned deps that are only **re-warned every run but never fixed** are waste:
the same finding is rediscovered and re-litigated indefinitely. Close the loop by turning the
warning into a **concrete, reviewable proposal** — not by editing the manifest in place.

- **Detect:** a `Type: unpinned` finding (floating `^`/`~`/`*`/`latest`) or a `Type: abandoned`
  finding the operator has not yet acted on.
- **Propose (the safe action):** prepare the exact pinned-version change — resolve the floating
  range against the lockfile to the concrete installed version (`name@X.Y.Z`), and stage it as a
  **branch + PR a human merges** (e.g. `package.json` `^1.2.0` → `1.2.4`, lockfile already pins it;
  or for an abandoned package, propose the maintained alternative named in the finding's `Fix:`).
  Express it as the finding's `Fix:` made actionable, with the diff scoped to one concern.
- **Never auto-pin / never auto-merge.** Pinning changes the build's resolved graph — a judgment
  call (it can pin *past* a security patch, or freeze a transitively-needed range). This stays
  **propose-only / human-gated** (the maturity model marks this class "no" — never safe-auto): the
  proposal is opened, the human decides.

This follows the marketplace's **merge-governance** — every change reaches `main` through an
adversarial-reviewed PR a human merges (FOUNDRY's `pr-approval` default; run `/foundry:pr-review`
on the branch when foundry is installed), never a self-merge. It is the same human-gated stance
SENTINEL's own `self-improve` skill takes, and it honours quality-first
([`../../knowledge/covenant.md`](../../knowledge/covenant.md)): the floor is raised by a reviewed
proposal, not by a silent in-place edit.

---

## Anti-patterns (never do these)

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Claiming "no vulnerabilities" when the advisory tool didn't run | False assurance | State "static checks only; vuln scan unavailable" |
| `npm install` / network installs during an audit | Side effects, supply-chain exposure during a security check | Parse manifests/lockfiles; run advisory tools in offline/report mode where possible |
| Ignoring transitive deps | Most vulns are transitive | Read the lockfile, not just the manifest |
| Treating every floating range as CRITICAL | Noise drowns real vulns | Floating = MEDIUM hygiene; vuln = CRITICAL/HIGH |

---

## Self-improvement covenant

- Every new ecosystem → add it to [`references/ECOSYSTEMS.md`](references/ECOSYSTEMS.md), including how
  to read its licence metadata (the `Native advisory tool` row's licence-detection equivalent).
- Every new advisory source or better native tool → record the command and JSON shape.
- Every new licence class or distribution-model nuance (e.g. a copyleft variant, a SaaS-triggering clause)
  → record the rule so the licence lens stays current as the vuln lens does.
- Every false positive (e.g. an intentionally-pinned old package, a dual-licensed dep allowed under its
  permissive option) → note the allowlist pattern.

## References

| Document | Purpose |
|---|---|
| [`references/ECOSYSTEMS.md`](references/ECOSYSTEMS.md) | Per-ecosystem manifests, lockfiles, advisory commands, JSON parsing notes |
