# Protocol — Resilient external-API calls

> Load when code or automation calls a **third-party HTTP API** (GitHub, package
> registries, cloud control planes) — in app code, CI, or provisioning. The rule:
> **never depend on an anonymous/unauthenticated quota, and never let one slow/again
> response wedge the run.**

This protocol pairs with [12-Factor Config](../architecture/twelve-factor.md) (the token
is config from the environment, never hard-coded) and the SECURITY reviewer role.

---

## The principle

Automation that calls a third-party API must be **authenticated, degradable, and
bounded**:

1. **Authenticate** — send a token from the environment / secret store. Anonymous quotas
   are tiny, shared *per source IP*, and non-deterministic under load.
2. **Degrade gracefully** — if no token is present, fall back (anonymous, cached, or
   skip) rather than crashing the run.
3. **Bound the failure** — retries with backoff; honour `Retry-After` /
   rate-limit-reset; treat `403`/`429` as transient-or-quota, not fatal.
4. **Don't burn quota you don't need** — prefer conditional requests; cache stable data.

---

## GitHub REST API — the concrete numbers

- **Unauthenticated: 60 requests/hour, per source IP.** A shared egress IP (CI, a NAT
  gateway, a fleet's outbound) exhausts this almost immediately, then returns `403
  rate limit exceeded`. **Authenticated PAT: 5,000/hour** (GitHub App installs higher;
  Actions' built-in `GITHUB_TOKEN` ~1,000/repo/hour). ([rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api))
- **Read the headers:** `x-ratelimit-remaining`, `x-ratelimit-reset` (epoch),
  `x-ratelimit-used`, `x-ratelimit-resource`. Back off on these, don't guess. ([rate limits](https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api))
- **`Authorization: Bearer <token>`** and `Authorization: token <token>` both work for
  PATs; JWTs (GitHub Apps) require `Bearer`. ([authenticating](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api))
- **Conditional requests are free.** Send `If-None-Match: <etag>`; a `304 Not Modified`
  **does not count against the primary rate limit** — ideal for polling stable resources.
  ([best practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api))
- **CI:** use the runner's built-in `GITHUB_TOKEN`; pause ≥1s between mutating calls to
  respect secondary limits. ([best practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api))

> **ANTI-PATTERN (DO NOT):** call `api.github.com` unauthenticated from CI or provisioning
> on a shared egress IP. **Why-not:** the 60/hr budget is drained by everything else on
> that IP, so your call `403`s intermittently — a flaky failure that looks like *your* bug.

> **GUARDRAIL:** data you fetch "to be current" that is actually published + stable (e.g.
> GitHub's SSH host keys via `/meta`) still needs the authenticated call — GitHub says the
> documented fingerprints are examples and you must query the API for authoritative values
> ([SSH key fingerprints](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)).
> So authenticate + cache (ETag); don't try to hard-code your way around the API.

---

## WORKED EXAMPLE — Ansible `ssh_known_hosts` (provisioning)

A provisioning role fetched GitHub's SSH host keys from `api.github.com/meta` on every run,
**unauthenticated**. On a fleet behind one egress IP the 60/hr budget was exhausted → `403`
→ the whole apply aborted at task ~15 on every host. The fix carried all four principles:

- **Authenticate:** send `Authorization: Bearer <vault GH_TOKEN>` (5,000/hr).
- **Degrade:** header computed as `{}` when no token → falls back to anonymous.
- **Bound:** `until: result is success` + bounded `retries`/`delay`.
- The keys were already fingerprint-pinned for verification, so auth changed the trust
  posture not at all — it only lifted the quota.

---

## Checklist

- [ ] Token sourced from env/secret store (never committed) — see [12-Factor Config](../architecture/twelve-factor.md).
- [ ] Graceful no-token fallback.
- [ ] Retries with backoff; `403`/`429` + reset/`Retry-After` honoured.
- [ ] Conditional requests (ETag) for repeatable/polled reads.
- [ ] No secret in logs.

## Related

- [12-factor.md](../architecture/twelve-factor.md) (Factor III Config · Factor IV Backing services)
- [degraded-capabilities.md](./degraded-capabilities.md) · [guardrails-ledger.md](./guardrails-ledger.md)
