# GitHub Actions Workflow YAML — Research Findings

## Triggers (`on`)

- **Event types**: single (`on: push`) or multiple (`on: [push, fork]`); activity-type filters further narrow (e.g., `pull_request.types: [opened, synchronize]`)
- **Filters**: `branches`, `branches-ignore`, `tags`, `tags-ignore` for ref events; `paths`, `paths-ignore` for push/pull_request
- **Schedule**: POSIX cron syntax for timer-driven runs
- **Reusable workflows**: `workflow_call` enables parameterized invocation; inputs/secrets passed via caller's `with:` and `secrets:` (or `secrets: inherit`)
- **Canonical reference**: https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions

## Jobs & Dependencies

- **`needs` keyword**: establishes sequential job ordering; required job must succeed before dependent job runs
- **Concurrency control**: `concurrency.group` + `cancel-in-progress: true` prevents parallel runs of same workflow; useful for deployment/release gates
- **Matrix builds**: single job definition expands into multiple runs per variable combination; useful for multi-OS/Node/Python testing
  - Combine with reusable workflows for matrix-driven multi-environment deployments
- **Permissions**: define `GITHUB_TOKEN` scope per job (`contents`, `pull-requests`, `deployments`, `packages`, `security-events`, `checks`, `statuses`)

## Caching Strategy

- **Key generation**: use `hashFiles()` to auto-invalidate on lock-file changes: `key: npm-${{ hashFiles('package-lock.json') }}`
- **Restore fallback**: structure keys specific→general for cascading fallback when exact match missing
- **Setup actions**: language-specific actions (`setup-node`, `setup-python`, etc.) auto-create & restore caches; prefer over manual `actions/cache`
- **Cross-OS**: enable `enableCrossOsArchive: true` for Windows runners to reuse Linux/macOS caches (if reproducible)
- **Security**: never cache credentials, tokens, or secrets; repository default is 10 GB with 7-day auto-eviction of unused entries
- **Canonical reference**: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows

## Artifacts & Inter-Job Data

- **Upload**: `actions/upload-artifact` with file/directory patterns; generates SHA256 digest for integrity validation
- **Download**: `actions/download-artifact` by name (or omit for all artifacts); auto-validates digest
- **Retention**: `retention-days` parameter (capped by repo/org/enterprise limits)
- **Sharing**: combine `needs` (job dependency) with artifact download to chain job outputs
- **Use case**: build → upload dist → test job downloads + validates before deployment
- **Canonical reference**: https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts

## Reusable Workflows & Composite Actions

- **Reusable workflows**: `.github/workflows/` files with `workflow_call` trigger; accept `inputs`, `secrets`, expose `outputs`
- **Inputs**: pass via `with:` in caller; reference as `${{ inputs.name }}` in reusable workflow
- **Secrets**: explicit pass (per-secret) or `secrets: inherit` for all repository secrets; only propagate through explicit links
- **Nesting depth**: max 10 levels (1 caller + 9 reusable); no loops allowed
- **Version safety**: pin reusable workflows to commit SHA (not branch/tag) for stability & security
- **Composite actions**: `.github/actions/` with `runs: composite` for reusable action logic; differ from reusable workflows in scope/execution
- **Outputs chaining**: reusable workflow outputs map step → job → workflow; caller accesses via `${{ needs.job-id.outputs.name }}`
- **Canonical reference**: https://docs.github.com/en/actions/using-workflows/reusing-workflows

## Workflow Commands & Step Communication

- **Syntax**: `::command parameter1={data}::{value}` (case-insensitive)
- **Annotations**: `::error::`, `::warning::`, `::notice::` with optional `file`, `line`, `col`, `title` for log highlighting
- **Masking secrets**: `::add-mask::{value}` before logging sensitive data
- **Environment files**: set variables via `echo "VAR=value" >> $GITHUB_ENV`; set outputs via `echo "name=value" >> $GITHUB_OUTPUT`; multiline via heredoc delimiters
- **Log grouping**: `::group::{title}` … `::endgroup::` for collapsible sections
- **Debug**: `::debug::{message}` (requires `ACTIONS_STEP_DEBUG` secret)
- **Canonical reference**: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions

## Common Failure Modes & Validation

- **Secrets leakage**: ensure `add-mask` called before logging user input; cache never stores credentials
- **Job ordering**: forgetting `needs:` causes parallel execution; test with small concurrency groups first
- **Cache eviction**: 7-day inactivity + 10 GB hard limit; monitor via Actions → Cache usage
- **Matrix failures**: one matrix cell failure stops job unless `continue-on-error: true` per step
- **Reusable workflow pin drift**: branch/tag pins allow silent updates; prefer commit SHAs for immutability
- **Artifact download race**: ensure upstream job completes (via `needs`) before download step
- **Multiline output**: forget heredoc delimiters → newlines broken; use `GITHUB_OUTPUT` file with `<<EOF` syntax

## Testing & Validation

- **Local simulation**: GitHub-hosted runners only; use `nektos/act` for local dry-run (syntax validation, job structure)
- **Pre-flight**: run `actions/github-script@v6` with `workflow()` queries to inspect workflow metadata
- **Dry-run mode**: add `if: github.event_name == 'pull_request'` to gate expensive steps during PR testing
- **Step debug**: set `ACTIONS_STEP_DEBUG` secret to `true` to surface `::debug::` annotations
- **Artifact inspection**: download artifact after workflow run to verify content before deployment
- **Concurrency test**: trigger multiple runs of same workflow to confirm `cancel-in-progress` behavior

## Canonical Tooling & Versions

- **Official action versions**: pin to major version (e.g., `actions/upload-artifact@v4`) for stability; check release notes for breaking changes
- **Runner OS selection**: `runs-on: ubuntu-latest` (most common; ~$0.008/min), `windows-latest`, `macos-latest`, or self-hosted
- **Actions ecosystem**: GitHub officially maintains setup actions (`setup-node@v4`, `setup-python@v5`, etc.); prefer over manual installation
- **act (local testing)**: `nektos/act` simulates GitHub runner locally; validates syntax & syntax errors before push
- **Repository variables**: `${{ vars.VAR_NAME }}` for non-secret config (org-level or repo-level); immutable at runtime
