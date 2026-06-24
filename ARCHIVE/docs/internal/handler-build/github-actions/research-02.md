# GitHub Actions Security Hygiene — Research Axis 2

## Action Pinning & Immutability

- **Full commit SHA only**: Use full-length commit SHA values (e.g., `uses: owner/repo@abc123...`) — only immutable method that prevents backdoor injection via tag/branch override
- **Never use**: `@latest`, `@main`, `@v1`, or floating tags/refs; tag updates can be force-pushed by attacker
- **Enforcement**: Org/repo policies can mandate commit SHA pinning in workflows; CODEOWNERS review recommended for `.github/workflows/*.yml`
- **Test**: `git log --oneline` to fetch SHA, update workflow to full SHA, verify action digest in `run` output
- **Source**: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions

## Least-Privilege Permissions

- **Default-read pattern**: Set `permissions: read-all` at workflow level, then grant only needed `write-*` per job
  - Common: `contents: write` for release, `pull-requests: write` for PR comments, `issues: write` for issue updates
  - Avoid: `write-all` unless audited; limits blast radius if action compromised
- **GITHUB_TOKEN scope**: Inherited from org default; explicitly override in workflow to tighten
- **Test**: Run workflow without elevated perms; add incrementally only if task fails with "insufficient permissions" error
- **Source**: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions

## OIDC for Cloud Auth (vs. Long-Lived Secrets)

- **OIDC flow**: GitHub generates short-lived (15 min) JWT for each job; cloud provider (AWS/Azure/GCP) exchanges token for temporary credentials
- **Setup per cloud**:
  - AWS: Add OIDC provider in IAM, create role with `github.com:repo:owner/repo:*` condition
  - Azure: Create federated credential in App Registration with GitHub issuer URL
  - GCP: Create Workload Identity Pool federation with GitHub provider
- **Advantages**: No rotatable secrets in repository, automatic expiry, audit trail in cloud logs, no risk of `secrets.context` leakage
- **Test**: Verify cloud provider receives valid OIDC token in workflow logs (audit trail), confirm temporary creds issued, test job without long-lived API keys
- **Source**: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect

## Secret Handling & Masking

- **Never echo secrets**: Use `core::setSecret()` in JS actions or `::add-mask::` in shell to mark sensitive non-secret values as masked
- **Environment variable pattern**: Store secrets as `env:` vars, not command-line args (processes visible to other runners)
- **Untrusted input in PR**: `pull_request_target` grants read access to base repo secrets but workflow runs against PR head — risk: malicious PR code could echo secrets to logs
  - Mitigation: Never pass `secrets.*` to untrusted script in `pull_request_target`; use `pull_request` event instead if safe, or gate secret access to explicit approval job
- **Quoting**: Wrap secrets in quotes when passed to shell; different per shell (Bash vs. PowerShell)
- **Test**: Review workflow run logs for secret redaction; ensure no `***` values appear unmasked; test fork PR scenario to confirm secrets not leaked
- **Source**: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions

## Supply-Chain Attack Vectors

- **Third-party action risks**: Compromised action repo, typo-squat variants, abandoned action with unfixed vuln, subtle malicious payload
- **Mitigations**:
  1. **Audit source code** — Review action.yml `runs:` entry, check shell scripts for exfil (sending output to attacker host)
  2. **Dependabot alerts** — Enable `GITHUB_TOKEN` scope for `pull-requests: write`, use Dependabot to auto-update actions in pinned SHAs
  3. **Code scanning** — Run `github/super-linter` or `semgrep` on `.github/workflows/` to catch injection patterns
  4. **Namespace precision** — Use full `owner/repo@sha` not shorthand; typos less likely in long form
  5. **Approve in PR** — Don't auto-merge workflow changes; human review of new actions
- **Common failure mode**: Action updates to fixed SHA but maintainer pushes force-push; SHA still valid but points to new code — use action release tags + commit SHA cross-check
- **Test**: `git show <sha>:action.yml` to inspect action version at pinned SHA; grep for common exfil patterns (curl, wget, `> /dev/tcp`); run workflow in dry-run mode with `--dry-run` flag if tool supports
- **Source**: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions

## Validation Checklist

- [ ] All `uses:` statements in `.github/workflows/` pin to full commit SHA (no `@v*`, `@main`)
- [ ] `permissions:` set to `read-all` by default, `write-*` only on jobs that need it
- [ ] Cloud auth uses OIDC JWT exchange, no long-lived API keys in secrets
- [ ] Secrets never echoed in logs; `::add-mask::` applied to sensitive non-secret values
- [ ] `pull_request_target` workflows do not pass `secrets.*` to untrusted scripts
- [ ] Workflow logs reviewed post-run for unredacted secrets (search for literal key names)
- [ ] Dependencies scanned with Dependabot; code scanning enabled on `.github/workflows/`
