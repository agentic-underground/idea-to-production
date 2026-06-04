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
checks *your credentials*, `dependency-audit` checks *the code you didn't write but ship anyway*.

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

## Finding format (shared with SENTINEL)

```markdown
**Package:** name@version  (ecosystem)
**Manifest:** `/path/to/manifest:LINE`
**Type:** [vuln | unpinned | no-lockfile | abandoned | typosquat | install-script]
**Risk:** [CRITICAL | HIGH | MEDIUM | LOW]
**Detail:** [advisory ID + summary | "floating range ^1.2" | "last release 2019, archived" | "edit-distance-1 of <popular>"]
**Fix:** [bump to X.Y.Z | pin + lock | replace with <maintained alt> | remove]
**Source:** [npm-audit | pip-audit | govulncheck | static-analysis]
```

---

## Output

- **Standalone:** `DEPENDENCY-FINDINGS.md` — summary table (counts by severity), findings by
  ecosystem, a prioritised remediation list (vulns first, then pinning/lockfile hygiene),
  appendix of manifests parsed and which tools ran.
- **Via `/security-gate`:** return the findings section for consolidation.

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

- Every new ecosystem → add it to [`references/ECOSYSTEMS.md`](references/ECOSYSTEMS.md).
- Every new advisory source or better native tool → record the command and JSON shape.
- Every false positive (e.g. an intentionally-pinned old package) → note the allowlist pattern.

## References

| Document | Purpose |
|---|---|
| [`references/ECOSYSTEMS.md`](references/ECOSYSTEMS.md) | Per-ecosystem manifests, lockfiles, advisory commands, JSON parsing notes |
