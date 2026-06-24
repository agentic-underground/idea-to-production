# Research 03: Validating Workflows (actionlint, act, status checks, failure modes)

## Static Analysis: actionlint

**Current tool:** [actionlint](https://github.com/rhysd/actionlint) — v1.7.12 (2026-03), maintained by @rhysd  
**Install:** `brew install actionlint` or `go install github.com/rhysd/actionlint@latest` or download binary  
**CI integration:** GitHub Marketplace action `rhysd/actionlint-action@v1` or run standalone  

**Validates:**
- YAML syntax, key duplication, required fields  
- Type checking in `${{ }}` expressions (contexts, functions, argument counts)  
- Runner labels (macos-26-large, windows-2025-vs2026, etc., updated regularly)  
- Action metadata & inputs (required, deprecated, mismatches)  
- Job dependencies (cyclic detection, undefined refs)  
- Permissions scope names & access levels  
- Webhook events, workflow_dispatch inputs, cron syntax, IANA timezones  
- Glob patterns (branch/tag/path filters)  
- Shell availability per OS (bash on windows-2025, pwsh, etc.)  
- Script injection risks (untrusted inputs in run: scripts)  
- Hardcoded credentials in container/service configs  
- Deprecated commands, constant if: conditions, YAML anchors  
- Shellcheck & pyflakes integration for `run:` scripts  
- Reusable workflow syntax & caller/callee validation  

**Canonical reference:** [`docs/checks.md`](https://github.com/rhysd/actionlint/blob/main/docs/checks.md)

---

## Local Dry-Run: act

**Current tool:** [act](https://github.com/nektos/act) — runs workflows in Docker locally  
**Install:** `brew install act` or download binary  
**Key flags:**  
- `-n, --dry-run` — parse & plan without executing  
- `-j <job>` — run single job  
- `--matrix key:value` — run one matrix combo  
- `-s GITHUB_TOKEN=<token>` — inject secrets for auth testing  
- `-W <path>` — specify workflows dir  

**Limitations & gotchas:**
- Requires Docker running locally; can't replicate exact GitHub runner environments  
- Third-party action pulls default image may not match exact GH runner state  
- Secrets passed on cmdline are visible in process list (use `.actrc` file instead)  
- Self-hosted runner labels won't resolve correctly  
- act v0.2.62+ supports event triggers & workflow_dispatch inputs  

**Testing pattern:** `act -n` for validation, then `act -j <job> -s GITHUB_TOKEN=...` for end-to-end  

---

## Required Status Checks & PR Protection

**Setup:** Settings → Branches → Branch protection rules → Require status checks to pass  
**Best practice:**  
- Gate on actionlint passing (via CI step or Marketplace action)  
- Gate on test suite, security scans, coverage thresholds  
- Require PRs from trusted contexts (no `pull_request_target` unless secrets are scoped)  
- Dismiss stale reviews after new commits  
- Require branches to be up to date before merge  
- Require code reviews from code owners  

**Enforcement:** GitHub enforces checks before merge; failed checks block until fixed  

---

## Common Failure Modes & Validation

### Permissions

**Failure:** Workflow tries `git push` or artifact upload without `contents: write`, `packages: write`, or `deployments: write`  
**April 2025 breaking change:** `deployments: write` required for deployment reviews (fine-grained PAT users hit this)  
**Detection:** actionlint validates `permissions:` section; act doesn't enforce at dry-run  
**Fix:** Explicit `permissions: { contents: write, deployments: write }` in workflow  

### Cache Key Collisions

**Failure:** `actions/cache@v4` with identical key across branches; restore step succeeds but uses stale cache  
**Detection:** Manual code review; act can run locally to see cache miss rate  
**Fix:** Include `${{ runner.os }}-${{ hashFiles(...) }}` in cache key; use `restore-keys` fallback  
**Validation:** `act -s GITHUB_TOKEN=<token> -j <cache-test-job>` to watch cache hits/misses  

### Secrets in Logs

**Failure:** Secrets printed to stdout/stderr; GitHub masks them but they appear in workflow logs if script redirects  
**Detection:** Grep logs for `***` (GitHub's masking indicator); manual audit of run: scripts  
**Fix:** Use environment variables, never `echo $SECRET`; use `set +x` before sensitive ops  
**actionlint check:** Detects hardcoded credentials in container/service configs; doesn't catch `run:` script leaks  
**Validation:** `act -s SECRET=<value> -j <job>` and inspect logs for masking  

### Non-Idempotent Steps

**Failure:** Steps fail on re-run (e.g., git push on already-pushed tag, database setup without --idempotent)  
**Detection:** Re-run failed job from GitHub UI; act can't replay exact failure  
**Fix:** Use `git diff --quiet` before push, `CREATE TABLE IF NOT EXISTS`, `--force-recreate` flags  
**Validation:** Manually re-run workflows in GitHub; document re-run behavior  

### Missing Actions Inputs / Typos

**Failure:** Action silently ignores unknown input keys; workflows behave unexpectedly  
**Detection:** actionlint checks popular actions (setup-node, checkout, etc.) against known inputs  
**Fix:** Consult action's `action.yml`; actionlint will warn on mismatches  

### Implicit Defaults in Contexts

**Failure:** `${{ env.SECRET }}` returns empty string if not set (no error); script proceeds with blank values  
**Detection:** Type checking in actionlint `${{ }}` expressions; act can reveal at runtime  
**Fix:** Use `${{ env.SECRET || 'default' }}` or explicitly check in scripts  

### Runner Label Drift

**Failure:** Workflow specifies `ubuntu-20.04` but GitHub sunset it; job queues indefinitely then fails  
**Detection:** actionlint checks against current runner labels (v1.7.12 includes 2025-era labels)  
**Fix:** Update to `ubuntu-24.04` or latest LTS; keep actionlint updated  

---

## Testing & Validation Strategy

### Pre-commit / Local Dev
1. `actionlint -color <workflow.yml>` — catch syntax, type, and injection issues  
2. `act -n -j <job>` — dry-run to see step order, env expansion  
3. `act -j <job> -s GITHUB_TOKEN=<pat>` — test with secrets (runs fully, watch logs)  

### CI Gate (Required Status Check)
1. Add `rhysd/actionlint-action@v1` to a dedicated linting workflow  
2. Gate merge on ✓ actionlint, ✓ test suite, ✓ security scans  
3. Enforce code review + branch protection  

### On-Merge Validation
1. Test workflow runs; re-run failed jobs from GitHub UI to check idempotency  
2. Monitor for secrets leaks in logs (GitHub masks, but grep for `***`)  
3. Check cache hit rate (GitHub Actions > Caching)  

### Audit Checklist
- [ ] `permissions:` explicitly set (not relying on defaults)  
- [ ] No hardcoded secrets in action inputs or inline scripts  
- [ ] Cache keys include `runner.os` and content hash  
- [ ] All `run:` scripts idempotent (safe to re-run)  
- [ ] actionlint passes locally & in CI  
- [ ] act dry-run succeeds (no Docker/auth required for basic syntax)  
- [ ] Third-party actions pinned to commit hash (e.g., `actions/setup-node@abc123`)  
- [ ] Required status checks enabled on main branch  

---

## Source URLs

- [actionlint repo & docs](https://github.com/rhysd/actionlint)
- [actionlint checks reference](https://github.com/rhysd/actionlint/blob/main/docs/checks.md)
- [actionlint playground](https://rhysd.github.io/actionlint/)
- [act repo](https://github.com/nektos/act)
- [GitHub Actions security guide — Wiz](https://www.wiz.io/blog/github-actions-security-guide)
- [GitHub Actions common failure modes](https://github.com/orgs/community/discussions/118365)
- [GitHub Changelog — April 2025 deployments permission change](https://github.blog/changelog/2025-03-20-notification-of-upcoming-breaking-changes-in-github-actions/)
