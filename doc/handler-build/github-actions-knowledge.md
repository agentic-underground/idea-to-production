# GitHub Actions / CI — Knowledge Wall

Raw material for agent-authors building the GitHub Actions value-handler.
Synthesised from three haiku research passes; contradictions resolved inline.

---

## 1. Prime Directives (non-negotiable)

1. **Pin every `uses:` to a full commit SHA.** Tags (`@v4`, `@main`, `@latest`) can be force-pushed by an attacker or by the maintainer after your audit. The only immutable reference is the 40-character SHA. No exceptions, including first-party GitHub actions.
   - Research-01 says "pin to major version" — research-02 overrides this with the correct security posture. Resolved in favour of full SHA.

2. **Default `permissions: read-all`; grant `write-*` per job only.** Never use `write-all`. The blast radius of a compromised action is bounded by the token scope it inherits.
   - April 2025 breaking change: `deployments: write` is now required for deployment reviews on fine-grained PATs — grant it explicitly, do not assume it is included in prior blanket grants.

3. **Never pass secrets to scripts that run untrusted code.** `pull_request_target` runs against the base repo and has access to secrets; if the workflow executes PR-head code it can exfiltrate them. Use `pull_request` for untrusted forks, or gate secret access behind an explicit approval job.

4. **Use OIDC for cloud auth.** Short-lived JWT credentials (15 min) have automatic expiry and no static secret to rotate or leak. Prefer OIDC over long-lived API keys stored in `secrets.*` for AWS, Azure, and GCP.

5. **All `run:` steps must be idempotent.** GitHub's "Re-run failed jobs" feature re-executes from the failure point. A step that pushes a git tag or creates a database table will fail on re-run unless written defensively (`git diff --quiet`, `CREATE TABLE IF NOT EXISTS`, `--force-recreate`).

---

## 2. Canonical Tooling & Pinned Versions

| Tool | Purpose | Version / Install |
|---|---|---|
| **actionlint** | Static analysis for workflow YAML | v1.7.12 (2026-03); `brew install actionlint` or `go install github.com/rhysd/actionlint@latest` |
| **rhysd/actionlint-action** | CI integration for actionlint | Use in a dedicated linting workflow; gate merge on it passing |
| **nektos/act** | Local dry-run in Docker | v0.2.62+ required for `workflow_dispatch` input support; `brew install act` |
| **actions/checkout** | Repo clone | Pin to full SHA; keep aligned with runner OS |
| **actions/upload-artifact** | Artifact upload | `@v4` (by SHA) — generates SHA256 digest automatically |
| **actions/download-artifact** | Artifact download | `@v4` (by SHA) — auto-validates digest on download |
| **actions/cache** | Dependency caching | `@v4` (by SHA); prefer language setup actions that wrap it |
| **actions/setup-node** | Node.js | `@v4` (by SHA) |
| **actions/setup-python** | Python | `@v5` (by SHA) |

**Runner OS pricing & selection:**
- `ubuntu-latest` — most common, ~$0.008/min; maps to ubuntu-24.04 as of 2025
- `windows-latest` / `macos-latest` — available but more expensive
- `ubuntu-20.04` has been sunset; actionlint v1.7.12 catches stale runner labels

---

## 3. Idioms

### Trigger patterns
```yaml
on:
  push:
    branches: [main]
    paths-ignore: ['**.md']
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_call:           # makes this a reusable workflow
    inputs:
      environment:
        required: true
        type: string
    secrets:
      deploy_key:
        required: true
```

### Concurrency guard (prevents parallel deploys)
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### Least-privilege template
```yaml
permissions:
  contents: read           # workflow-level default
jobs:
  release:
    permissions:
      contents: write      # job-level override only where needed
      deployments: write   # required since April 2025 breaking change
```

### Cache key with fallback
```yaml
- uses: actions/cache@<full-sha>
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

### Safe secret handling in shell
```yaml
- name: Deploy
  env:
    API_KEY: ${{ secrets.API_KEY }}   # env var, not CLI arg
  run: |
    set +x                            # suppress xtrace before sensitive ops
    deploy --key "$API_KEY"
```

### Masking a computed value
```bash
echo "::add-mask::$COMPUTED_TOKEN"
```

### Environment files (not deprecated `::set-output::`)
```bash
echo "VERSION=1.2.3" >> "$GITHUB_ENV"       # set for subsequent steps
echo "sha=$GIT_SHA"  >> "$GITHUB_OUTPUT"    # expose as job output
# multiline:
{
  echo "BODY<<EOF"
  cat release-notes.md
  echo "EOF"
} >> "$GITHUB_ENV"
```

### Log grouping
```bash
echo "::group::Lint output"
npm run lint
echo "::endgroup::"
```

### Artifact chain (build → test → deploy)
```yaml
jobs:
  build:
    steps:
      - uses: actions/upload-artifact@<sha>
        with:
          name: dist
          path: dist/
          retention-days: 7
  test:
    needs: build
    steps:
      - uses: actions/download-artifact@<sha>
        with:
          name: dist
```

### Reusable workflow invocation
```yaml
jobs:
  deploy:
    uses: ./.github/workflows/deploy.yml   # LOCAL caller: no ref — resolves to the current commit
    with:
      environment: production
    secrets: inherit          # or list explicitly
```
- Max nesting depth: 10 levels (1 caller + 9 reusable). No cycles.
- Pin REMOTE reusable workflows (`owner/repo/.github/workflows/x.yml@<sha>`) to a SHA, not a branch.
  LOCAL callers (`./.github/workflows/x.yml`) take no ref — `@<sha>` there is invalid YAML.

### OIDC cloud auth (AWS example)
```yaml
permissions:
  id-token: write
  contents: read
steps:
  - uses: aws-actions/configure-aws-credentials@<sha>
    with:
      role-to-assume: arn:aws:iam::123456789:role/GitHubActions
      aws-region: us-east-1
```

---

## 4. Anti-Patterns & Failure Modes

| Anti-pattern | Consequence | Fix |
|---|---|---|
| `uses: actions/foo@v4` or `@main` | Tag can be force-pushed; silent supply-chain injection | Pin to full 40-char commit SHA |
| `permissions: write-all` | Any compromised step owns the repo | Default `read-all`; grant per job |
| Secrets as CLI args (`--key $SECRET`) | Visible in process list to other runners | Pass via `env:` block |
| `pull_request_target` + untrusted script with secrets | Secret exfiltration from fork PRs | Never pass `secrets.*` to PR-head code; use `pull_request` event |
| Cache key without `runner.os` | Cross-OS cache collisions; stale artifacts restored | Always include `${{ runner.os }}` prefix |
| Missing `needs:` between producer and consumer jobs | Artifact download race; parallel jobs may see stale state | Add explicit `needs:` dependency |
| Non-idempotent push/create steps | Re-run fails loudly or silently corrupts state | Guard with `git diff --quiet`, `IF NOT EXISTS`, etc. |
| Multiline output with bare `echo` | Newlines broken; downstream steps get empty or truncated values | Use `GITHUB_OUTPUT` with heredoc delimiter |
| `ubuntu-20.04` runner label | Job queues indefinitely after GitHub sunset | Update to `ubuntu-24.04`; keep actionlint current |
| `${{ env.FOO }}` with unset var | Empty string silently; script proceeds with blank value | Explicit default `${{ env.FOO \|\| 'fallback' }}` or guard in shell |
| `continue-on-error: true` on matrix without purpose | Failures silently swallowed; broken matrix cells ship | Use it deliberately; add a summary step that aggregates failures |
| Floating reusable workflow ref | Caller picks up breaking changes without notice | Pin caller's `uses:` to SHA |
| Force-pushed SHA (maintainer rebases) | Pinned SHA now points to new code | Cross-check action release tag + commit SHA; use Dependabot for alerts |

---

## 5. Environment-Detection Snippet

Use this in a composite action or reusable workflow to adapt behaviour per runner OS and detect CI context:

```bash
#!/usr/bin/env bash
# Detect runner OS
case "$RUNNER_OS" in
  Linux)   PKG_MGR="apt-get" ;;
  macOS)   PKG_MGR="brew" ;;
  Windows) PKG_MGR="choco" ;;
  *)       echo "::warning::Unknown RUNNER_OS=${RUNNER_OS}"; PKG_MGR="unknown" ;;
esac

# Detect CI vs local (act sets ACT=true)
if [[ "${CI:-}" == "true" ]]; then
  echo "Running in CI (RUNNER_NAME=${RUNNER_NAME:-unknown})"
  if [[ "${ACT:-}" == "true" ]]; then
    echo "::notice::Running under act (local dry-run) — some behaviours differ"
  fi
fi

# Safe secret guard: abort if expected env var is blank
: "${DEPLOY_KEY:?DEPLOY_KEY must be set}"
```

Key env vars always available in GitHub Actions:
- `GITHUB_ACTIONS=true` — set by GitHub; absent in local shells
- `GITHUB_REF`, `GITHUB_SHA`, `GITHUB_RUN_ID`, `GITHUB_RUN_ATTEMPT`
- `RUNNER_OS`, `RUNNER_ARCH`, `RUNNER_NAME`
- `ACT=true` — set by nektos/act; use to gate behaviours that don't work locally

---

## 6. Test & Validation Strategy

### Layer 1 — pre-commit (local, no network)
1. `actionlint -color .github/workflows/*.yml` — syntax, type-checking, injection detection, runner label validation, shellcheck integration
2. `act -n -j <job>` — dry-run; validates step ordering and env expansion without executing

### Layer 2 — local with secrets (Docker required)
3. `act -j <job> -s GITHUB_TOKEN=$(gh auth token)` — full local execution; store secrets in `.actrc`, never on CLI
4. Inspect act output for unmasked secrets (search logs for `***` absence where expected)

### Layer 3 — CI required status checks
5. Dedicated workflow running `rhysd/actionlint-action@v1` — gate PR merge on pass
6. Gate on: actionlint ✓, test suite ✓, security scans ✓, coverage thresholds ✓
7. Branch protection: require checks to pass, dismiss stale reviews, require branches up to date

### Layer 4 — post-merge / on-merge validation
8. Re-run failed jobs from GitHub UI to confirm idempotency
9. Check cache hit rate in Actions > Caching tab
10. Grep workflow logs for literal secret names (confirm masking worked)
11. Enable `ACTIONS_STEP_DEBUG=true` secret for verbose debug output when diagnosing silent failures

### Audit checklist (run before any workflow ships)
- [ ] Every `uses:` pinned to full 40-char SHA
- [ ] `permissions: read-all` at workflow level; `write-*` only on jobs that require it
- [ ] `deployments: write` explicitly granted to any job that creates a deployment (April 2025)
- [ ] Cloud auth via OIDC — no long-lived API keys in `secrets.*`
- [ ] No secrets echoed in run steps; `::add-mask::` applied to any computed sensitive values
- [ ] `pull_request_target` workflows do not pass `secrets.*` to PR-head scripts
- [ ] Cache keys include `${{ runner.os }}` and `hashFiles(lock-file)`
- [ ] All `run:` steps are idempotent
- [ ] actionlint passes locally and in CI
- [ ] act dry-run passes
- [ ] Third-party actions audited: `git show <sha>:action.yml`; grepped for exfil patterns
- [ ] Required status checks enforced on default branch

---

## 7. Thin Spots (gaps the research left under-specified)

- **Self-hosted runners** — security model, network isolation, and label resolution were not covered. Composite actions and reusable workflows behave identically, but runner hygiene (ephemeral vs persistent, image hardening) needs a dedicated research pass.
- **Dependabot for action SHA updates** — mentioned in research-02 as a mitigation but no concrete `dependabot.yml` snippet was provided. Agent-author should add a `package-ecosystem: github-actions` stanza.
- **Matrix failure aggregation** — `continue-on-error` at the matrix level, and using a summary step or `actions/github-script` to surface all failures in the PR, was not detailed. Current guidance only covers per-step `continue-on-error`.
- **Composite action vs reusable workflow trade-offs** — research-01 names both but does not give a decision rule. Composite actions run in the caller's job context (same runner, share env); reusable workflows run as separate jobs (isolated, can have their own `permissions`). This distinction matters for security design.
- **act limitations depth** — research-03 lists gotchas but does not cover act's service containers or `act`'s handling of `GITHUB_OUTPUT` vs the old `set-output` command. These behave differently from real runners on older act versions.
- **Caching across PRs vs branches** — the 10 GB / 7-day eviction policy is noted but scope isolation (caches are branch-scoped by default; PRs can read base branch cache but not vice versa) was not stated.
