# Ecosystems — manifests, lockfiles, advisory tooling

The lookup table `scan-dependencies` reads to know *how* to audit each ecosystem it detects. Run
the native advisory tool when present; otherwise fall back to static checks and say so.

---

## Detection & tooling matrix

### npm / pnpm / yarn (JavaScript/TypeScript)
- **Manifest:** `package.json` (`dependencies`, `devDependencies`, `optionalDependencies`)
- **Lockfile:** `package-lock.json` (npm) · `pnpm-lock.yaml` (pnpm) · `yarn.lock` (yarn)
- **Vuln tool:** `npm audit --json` (also `pnpm audit --json`, `yarn npm audit --json`)
- **Parse:** `.vulnerabilities` → per-package `{severity, via, range, fixAvailable}`. Map
  `critical/high/moderate/low` → CRITICAL/HIGH/MEDIUM/LOW.
- **Static checks:** floating ranges (`^`, `~`, `*`, `latest`), missing lockfile,
  `scripts.postinstall` in deps, typosquat names.

### Python — pip
- **Manifest:** `requirements.txt`, `requirements-*.txt`, `constraints.txt`
- **Lockfile:** pinned `==` with `--hash`, or `requirements.lock`
- **Vuln tool:** `pip-audit -f json`
- **Static checks:** unpinned (`>=`, `*`, no specifier), no hashes.

### Python — Poetry / uv / PDM
- **Manifest:** `pyproject.toml` (`[tool.poetry.dependencies]` / `[project] dependencies`)
- **Lockfile:** `poetry.lock` · `uv.lock` · `pdm.lock`
- **Vuln tool:** `pip-audit` (against the resolved env) or `uv pip audit`
- **Static checks:** caret/star ranges, lockfile present & in sync.

### Go
- **Manifest:** `go.mod` · **Lockfile:** `go.sum`
- **Vuln tool:** `govulncheck -json ./...` (reachability-aware — lower false positives)
- **Static checks:** `replace` directives to local/forked paths, very old module versions.

### Rust
- **Manifest:** `Cargo.toml` · **Lockfile:** `Cargo.lock`
- **Vuln tool:** `cargo audit --json` (RustSec advisory DB)
- **Static checks:** wildcard versions, yanked crates.

### Ruby
- **Manifest:** `Gemfile` · **Lockfile:** `Gemfile.lock`
- **Vuln tool:** `bundle audit --format json` (ruby-advisory-db)
- **Static checks:** no version constraint, `:git`/`:path` sources.

### Java / Kotlin
- **Manifest:** `pom.xml` (Maven) · `build.gradle[.kts]` (Gradle)
- **Lockfile:** Gradle lockfiles (optional); Maven none by default
- **Vuln tool:** OWASP `dependency-check` (if available)
- **Static checks:** version ranges, `LATEST`/`RELEASE` placeholders, dynamic versions.

---

## Running advisory tools safely

- Prefer **read-only / report** invocations; never trigger a fresh network install as a side
  effect of an audit (that itself is supply-chain exposure).
- If a tool is absent from the environment, **do not install it silently** — report
  "advisory tool unavailable; static checks only" and recommend the user run it in CI.
- Cache nothing sensitive; the audit reads manifests/lockfiles already in the repo.

---

## Severity mapping (native → SECURITY)

| Native severity | SECURITY risk |
|---|---|
| critical | CRITICAL |
| high | HIGH |
| moderate / medium | MEDIUM |
| low / info | LOW |

For static-only findings: no-lockfile = HIGH; floating range = MEDIUM; abandoned = LOW–MEDIUM
(scale by age + archived flag); typosquat = HIGH (attack signal).

---

## Typosquat heuristic

Flag a dependency whose name is **edit-distance 1** from a top-popularity package in the same
ecosystem (e.g. `reqeusts` vs `requests`, `loadsh` vs `lodash`, `colour`/`crossenv` lookalikes),
*unless* it is itself a well-known package. Report as HIGH with the suspected target name —
typosquats are deliberate, not accidental.

---

## Self-improvement log

```
### Ecosystem update NNNN — YYYY-MM-DD
**Added / changed:** [ecosystem, tool, or parse note]
**Reason:** [new ecosystem encountered | tool output format changed | better tool found]
```
