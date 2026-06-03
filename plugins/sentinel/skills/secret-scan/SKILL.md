---
name: secret-scan
description: >
  Focused detection of committed credentials and secrets — API keys, tokens, private keys,
  database connection strings, and high-entropy strings — across the working tree, git history,
  and build artefacts. Complements pii-audit (which targets PERSONAL data) with a CREDENTIAL
  lens. Trigger with /secret-scan [scope] where scope is: full (working tree + history +
  artefacts), tree (working tree only), history (git history only), or a path. Default: full.
  Shares the SENTINEL finding/report format. Produces findings consumable standalone or by the
  /security-gate consolidator. Self-improving: every missed token family becomes a new pattern;
  every false positive becomes an allowlist entry.
metadata:
  type: scanner
  lens: credentials
  output: findings (markdown) → SECRET-FINDINGS.md or security-gate report
model: claude-haiku-4-5-20251001
---

# SECRET-SCAN

Catch the credential before it ships. Where `pii-audit` asks *"is there a real person's data
here?"*, secret-scan asks *"is there a key, token, or password here?"* — two distinct lenses on
the same repo, deliberately kept separate so neither dilutes the other.

---

## Quick start

```bash
/secret-scan                 # full: working tree + git history + build artefacts
/secret-scan tree            # working tree only (fast, pre-commit)
/secret-scan history         # git history only (deep, pre-open-source)
/secret-scan dist/           # a specific path (e.g. built bundles)
```

---

## What it scans (and why it differs from pii-audit)

| Surface | Why it matters | Note |
|---|---|---|
| **Working tree** | Hardcoded keys in source/config are the most common leak | Excludes `node_modules`, `.venv`, `vendor` |
| **Git history** | A rotated-looking key may still be live; deleted `.env` files persist in history | `git log -p --all` + targeted greps |
| **Build artefacts** (`dist/`, `build/`, source maps) | Bundlers inline `process.env` values; source maps re-expose source | pii-audit skips these by design; secret-scan does NOT |
| **`.env*` files on disk** | Even gitignored, they leak if ever committed or shared | Reported with a "gitignored?" flag |

---

## Detection strategy — two complementary methods

1. **Known-pattern matching** — regex families for well-known token shapes (see
   [`references/SECRET-PATTERNS.md`](references/SECRET-PATTERNS.md)). High precision, low false-positive: a string matching
   `gh[ps]_[A-Za-z0-9]{36}` is almost certainly a GitHub token.
2. **High-entropy heuristic** — flag string literals assigned to suspicious key names
   (`secret`, `token`, `key`, `password`, `passwd`, `auth`, `credential`) whose value has high
   Shannon entropy and length ≥ 20. Catches novel/custom secrets that no regex anticipates.
   Lower precision → always reported at a lower confidence and shown with context for a human.

Both methods defer to the **allowlist** (`references/SECRET-PATTERNS.md §Allowlist` and the
project `.secretignore`) to suppress documented placeholders.

---

## Finding format (shared with SENTINEL)

```markdown
**File:** `/path/to/file:LINE`         (or `commit <hash>:path` for history findings)
**Type:** [api-key | token | private-key | connection-string | password | high-entropy]
**Provider:** [aws | gcp | github | slack | stripe | jwt | generic | …]
**Risk:** [CRITICAL | HIGH | MEDIUM | LOW]
**Confidence:** [pattern-match | entropy-heuristic]
**Match (redacted):** AKIA****************  (show ≤4 leading chars, mask the rest)
**Live?:** [unknown — recommend rotation | likely rotated (old commit)]
```

Risk defaults: a **pattern-match** to a live-provider key = CRITICAL; a connection string with
embedded password = CRITICAL; an entropy-heuristic hit = MEDIUM pending human review.

**Never print a full secret.** Redact to ≤4 leading characters. The point is to locate, not to
re-leak into the report (which is itself committed).

---

## Output

- **Standalone:** write `SECRET-FINDINGS.md` (executive summary table, findings by surface,
  remediation, appendix of files scanned).
- **Via `/security-gate`:** return the findings section for consolidation into `SECURITY-REPORT.md`.

Remediation guidance lives in the pii-audit skill's [`references/REMEDIATION.md`](references/REMEDIATION.md) (rotate → purge
history → move to a secrets manager / env var → add to `.gitignore`); secret-scan reuses it
rather than restating.

---

## The `.secretignore` file

Same syntax as `.gitignore`. Suppresses known false positives (example keys in docs, fixtures
of obviously-fake tokens). Every suppression is disclosed in the report appendix — exclusions
are never silent.

```gitignore
# .secretignore
docs/**/*.example.*          # documentation placeholders
tests/fixtures/fake-keys.json
```

---

## Anti-patterns (never do these)

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Printing the full matched secret in the report | The report is committed → re-leaks the secret | Redact to ≤4 leading chars |
| Skipping `dist/`/source maps | Bundled/inlined secrets are a top leak vector | Always scan artefacts in `full` |
| Reporting only working tree | A purged key lives on in history and may be live | Scan history in `full` |
| Treating entropy hits as confirmed | High false-positive rate | Mark `entropy-heuristic`, MEDIUM, human-review |
| Suppressing with broad `**` allowlist | Hides future real leaks | Narrow `.secretignore` entries only |

---

## Self-improvement covenant

- Every token family that slips through → add a regex to [`references/SECRET-PATTERNS.md`](references/SECRET-PATTERNS.md).
- Every false positive → add a narrow allowlist entry and note the shape.
- Every new provider/key format → document its prefix and length.

This skill compounds: the next scan starts from a stricter baseline than the last.

## References

| Document | Purpose |
|---|---|
| [`references/SECRET-PATTERNS.md`](references/SECRET-PATTERNS.md) | Regex families per provider, entropy thresholds, allowlist |
| [`../pii-audit/references/REMEDIATION.md`](../pii-audit/references/REMEDIATION.md) | How to remediate a leaked secret (rotate, purge, vault) |
