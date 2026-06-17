# Secret Patterns — provider regex families, entropy thresholds, allowlist

The detection library for `scan-for-secrets`. Patterns are deliberately tight (high precision) so
pattern-match findings can default to CRITICAL/HIGH with confidence. The entropy heuristic is the
safety net for everything no pattern anticipates.

> **Redaction rule (applies to every match):** show at most the **4 leading characters**, mask
> the remainder. Never write a full secret into a finding — the report is committed.

---

## 1. Provider token families (pattern-match → high confidence)

| Provider | Pattern (POSIX-ish ERE) | Default risk |
|---|---|---|
| AWS Access Key ID | `\b(AKIA\|ASIA)[0-9A-Z]{16}\b` | CRITICAL |
| AWS Secret Access Key | `(?i)aws.{0,20}['"][0-9a-zA-Z/+]{40}['"]` | CRITICAL |
| GitHub token | `\bgh[pousr]_[A-Za-z0-9]{36,}\b` | CRITICAL |
| GitHub fine-grained PAT | `\bgithub_pat_[0-9a-zA-Z_]{82}\b` | CRITICAL |
| Google API key | `\bAIza[0-9A-Za-z\-_]{35}\b` | HIGH |
| GCP service-account key | `"type":\s*"service_account"` + `"private_key"` | CRITICAL |
| Slack token | `\bxox[baprs]-[0-9A-Za-z-]{10,}\b` | HIGH |
| Slack webhook | `https://hooks\.slack\.com/services/T[0-9A-Z]+/B[0-9A-Z]+/[0-9A-Za-z]+` | HIGH |
| Stripe live key | `\b[rsp]k_live_[0-9A-Za-z]{20,}\b` | CRITICAL |
| Twilio | `\bSK[0-9a-fA-F]{32}\b` | HIGH |
| SendGrid | `\bSG\.[0-9A-Za-z_\-]{22}\.[0-9A-Za-z_\-]{43}\b` | HIGH |
| OpenAI / Anthropic-style | `\b(sk\|sk-ant)-[A-Za-z0-9_\-]{20,}\b` | CRITICAL |
| JWT | `\beyJ[A-Za-z0-9_\-]+\.eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\b` | MEDIUM (may be public) |
| Private key block | `-----BEGIN (RSA\|EC\|DSA\|OPENSSH\|PGP)? ?PRIVATE KEY-----` | CRITICAL |
| Generic bearer header | `(?i)authorization:\s*bearer\s+[A-Za-z0-9._\-]{20,}` | HIGH |

---

## 2. Connection strings (pattern-match → CRITICAL when password present)

| Shape | Pattern |
|---|---|
| Postgres/MySQL/Mongo with creds | `(?i)(postgres\|postgresql\|mysql\|mongodb(\+srv)?)://[^:@/\s]+:[^@/\s]+@` |
| Redis with auth | `(?i)redis://[^:@/\s]*:[^@/\s]+@` |
| AMQP with creds | `(?i)amqps?://[^:@/\s]+:[^@/\s]+@` |
| Generic `user:pass@host` URL | `(?i)[a-z][a-z0-9+.\-]*://[^:@/\s]+:[^@/\s]{3,}@[^/\s]+` |

A connection string with an embedded password is always CRITICAL — it bundles host + credential.

---

## 3. Assignment-name heuristic (entropy → MEDIUM, human-review)

Trigger when a string literal is assigned to a key whose name matches:

```
(?i)\b(secret|token|api[_-]?key|access[_-]?key|password|passwd|pwd|auth|credential|client[_-]?secret|private[_-]?key)\b
```

…**and** the value satisfies all of:
- length ≥ 20 characters,
- Shannon entropy ≥ **4.0 bits/char** (base-2 over the value's character distribution),
- not matched by the allowlist (§5) or a placeholder pattern (§4).

Report as `Confidence: entropy-heuristic`, `Risk: MEDIUM`, with surrounding context so a human
decides. Entropy hits are signal, not verdicts.

---

## 4. Placeholder patterns (suppress — these are NOT secrets)

```
(?i)\b(example|placeholder|dummy|sample|changeme|your[_-]?key|xxxx+|<[^>]+>|\.\.\.|redacted|test123|foobar)\b
example\.com   test@test\.com   sk_test_   pk_test_   0{8,}   1234567890
```

A value matching a placeholder pattern is never reported, even if its key name is suspicious.

---

## 5. Allowlist (project-tunable)

Two layers:
1. **This file** — globally-known-safe shapes (the §4 placeholders).
2. **`.secretignore`** at project root — path/pattern suppressions specific to the repo.

Every suppression is recorded in the report appendix ("Suppressed by allowlist / .secretignore"),
so a reader always knows what was *not* reported. Prefer narrow entries (a specific file) over
broad globs.

---

## 6. Self-improvement log

Append here when a new family is learned:

```
### Pattern NNNN — YYYY-MM-DD
**Missed / false-positive:** [what happened]
**New/strengthened rule:** [regex or threshold change]
**Section affected:** [1 providers | 2 conn-strings | 3 entropy | 4 placeholders]
```
