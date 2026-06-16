---
id: 64
title: "SENTINEL container & IaC scanning — Dockerfiles, Terraform, k8s"
status: PENDING
priority: MEDIUM
added: 2026-06-16
depends_on: "—"
---

# [64] SENTINEL container & IaC scanning — Dockerfiles, Terraform, k8s

**Brief Description**
Extend the lenses to `Dockerfile`s (root user, pinned base images, secrets in layers) and IaC (`*.tf`, k8s
manifests) for misconfigurations and embedded secrets.

### User Stories
- AS an operator I WANT SENTINEL to scan my Dockerfiles and IaC for misconfigurations and embedded secrets
  SO THAT infra risks are caught by the same gate as code risks.

### EARS Specification
**Ubiquitous**
- The system SHALL scan `Dockerfile`s and IaC sources (`*.tf`, k8s manifests) for misconfigurations and
  embedded secrets as additional security lenses.

**Event-driven**
- WHEN a `Dockerfile` is scanned THE SYSTEM SHALL flag a root user, an unpinned base image, and secrets in
  layers; WHEN IaC is scanned THE SYSTEM SHALL flag misconfigurations and embedded secrets.

**Unwanted behaviour**
- IF a manifest format is unrecognised THEN THE SYSTEM SHALL skip it with a note, never silently report a
  clean pass over unscanned infra.

### Acceptance Criteria
1. Given a Dockerfile running as root with an unpinned base, When scanned, Then both are reported.
2. Given a Terraform file with an embedded secret, When scanned, Then it is flagged.

### Implementation Notes
- Add container + IaC lenses; reuse the secret patterns from secret-scan for embedded-secret detection.
- Fold the lenses into `/security-gate`'s verdict.
- Migrated from `plugins/sentinel/ROADMAP.md` (mid-term) under roadmap item [47].
