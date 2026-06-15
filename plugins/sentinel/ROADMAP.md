# SENTINEL — Roadmap

> **Consolidating.** The marketplace roadmap now lives as a file-per-item tree at
> [`.i2p/roadmap/`](../../.i2p/roadmap/) (status = folder). The expansion items below are **pending
> migration** into `.i2p/roadmap/backlog/` (roadmap item [47]); kept here meanwhile so nothing is lost.

The shipped v1 covers the three core lenses (PII, secrets, supply-chain) and the consolidated
gate. This roadmap captures the deliberate expansion path — each item deepens SENTINEL's reach as
a complete pre-release security station. Items are independently shippable.

## Near-term

- **`license-audit` skill** — scan dependency licenses for compatibility and copyleft conflicts
  (e.g. GPL in a permissively-licensed product). Map each dependency's SPDX license against a
  configurable policy; flag conflicts and unknown/missing licenses. Pairs naturally with
  `dependency-audit` (same manifests, different question).
- **`sbom` skill** — generate a Software Bill of Materials (CycloneDX and SPDX formats) from the
  resolved dependency graph. Increasingly a procurement/compliance requirement; reuses the
  ecosystem detection from `dependency-audit`.
- **Unified `.securityignore`** — one exclusion file consumed by all lenses (superseding the
  per-skill `.piiignore` / `.secretignore`), with per-lens sections. Keeps exclusions in one
  auditable place.

## Mid-term

- **Severity-policy config** — a `sentinel.config.json` letting a project tune the verdict rule
  (e.g. treat HIGH as BLOCK for regulated products; downgrade a specific advisory with a
  documented justification + expiry).
- **CI integration recipes** — drop-in GitHub Actions / GitLab CI snippets that run
  `/security-gate` and fail the build on BLOCK, post the report as a PR comment, and upload the
  SBOM as an artefact.
- **Container & IaC scanning** — extend the lenses to `Dockerfile`s (root user, pinned base
  images, secrets in layers) and IaC (`*.tf`, k8s manifests) for misconfigurations and embedded
  secrets.

## Longer-term

- **Diff-scoped mode** — scan only what changed since a ref (`/security-gate --since main`) for
  fast, incremental gating on every PR.
- **Live-credential verification** (opt-in, sandboxed) — confirm whether a detected key is still
  active before classifying BLOCK, reducing rotation churn on already-dead secrets.
- **Findings ledger** — a machine-readable `SECURITY-LEDGER.jsonl` accumulating verdicts over
  time, so trends (regressions, recurring false positives) are visible and feed self-improvement.

## Principles guiding expansion

Every new lens (a) asks a *distinct* security question, (b) shares the SENTINEL finding/report
format and the no-silent-pass rule, (c) plugs into `/security-gate`'s parallel fan-out and
verdict computation, and (d) carries the self-improvement covenant.
