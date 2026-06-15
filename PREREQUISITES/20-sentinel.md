# 20 — SENTINEL prerequisites

SENTINEL's three core lenses (PII, secrets, dependencies) work on **pattern-matching + the
ecosystem's native advisory tooling**. It degrades gracefully: a missing scanner narrows a lens to
"partial coverage" and is reported — never a silent PASS. Installing the scanners below upgrades
coverage from heuristic to authoritative, and adds a **SAST** lens via the standalone `semgrep` CLI.

## Dependency / supply-chain (SCA) — per ecosystem

| Tool | Tier | Probe | Ecosystem | Install |
|---|---|---|---|---|
| `npm audit` | recommended | `npm --version` | npm/pnpm/yarn | ships with npm |
| `pip-audit` | recommended | `pip-audit --version` | Python | `uv tool install pip-audit` |
| `govulncheck` | optional | `govulncheck -version` | Go | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| `cargo-audit` | recommended | `cargo audit --version` | Rust (RustSec) | `cargo install cargo-audit` |
| `bundler-audit` | optional | `bundle audit version` | Ruby | `gem install bundler-audit` |
| OWASP `dependency-check` | optional | `dependency-check --version` | Java/Maven/Gradle | release tarball |

## Cross-ecosystem scanners (recommended additions)

| Tool | Tier | Probe | Lens | Install |
|---|---|---|---|---|
| `osv-scanner` | recommended | `osv-scanner --version` | SCA across all lockfiles (Google OSV DB) | release binary / `go install github.com/google/osv-scanner/cmd/osv-scanner@latest` |
| `trivy` | optional | `trivy --version` | SCA + IaC + container/image | install script / apt repo |
| `grype` + `syft` | optional | `grype version` | SBOM + vuln scan | install script |

## Secrets

| Tool | Tier | Probe | Why | Install |
|---|---|---|---|---|
| `gitleaks` | recommended | `gitleaks version` | committed-credential scan (tree + history) | release binary |
| `trufflehog` | optional | `trufflehog --version` | verified-secret detection with entropy | release binary |

> SENTINEL's secret-scan also works with **zero external tools** (regex families + entropy). The
> scanners above raise confidence and add history/verification depth.

## SAST (static application security testing)

| Tool | Tier | Probe | Install |
|---|---|---|---|
| `semgrep` (standalone CLI) | optional | `semgrep --version` | `uv tool install semgrep` |

Code-level vuln patterns (injection, taint, weak crypto) are an optional lens run via the standalone
`semgrep` CLI; SENTINEL ships no SAST MCP server.

Ansible: [`ansible/binaries.yml`](ansible/binaries.yml) (osv-scanner/trivy/grype/gitleaks/trufflehog),
[`ansible/cargo.yml`](ansible/cargo.yml) (cargo-audit), [`ansible/uv.yml`](ansible/uv.yml) (pip-audit/semgrep),
[`ansible/go.yml`](ansible/go.yml) (govulncheck).

> **No MCP needed.** SENTINEL is built entirely on local CLI scanners — the broader gaps (SBOM, IaC,
> container scanning) are served by the optional **CLI** scanners listed above (`syft`/`grype`,
> `trivy`); local binaries, not MCP servers, are the right model for a security gate.
