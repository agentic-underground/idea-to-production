# Cached review — FOUNDRY handler-ansible

**Target file:** `plugins/foundry/agents/handler-ansible.md`  
**Unit:** `handler-ansible`  
**Findings:** 9 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [CRITICAL] Load-bearing knowledge corpora referenced without any resolvable path — and they live OUTSIDE the plugin (self-containment violation)

**Evidence:** Lines 148-151: "consult the provisioning guardrails ledger and the VM-debugging field knowledge — the dead ends (UEFI-only cloud images, `generate_mirrorlists: false`, HTTP-cache HTTPS-rewrite, a placeholder apt-proxy that makes a fresh VM undiscoverable, `domifaddr --source agent` for bridged guests) are already mapped; don't re-pay for them." No `${CLAUDE_PLUGIN_ROOT}` (or any) path is given. The only files containing this material are `/home/user/Code/idea-to-production/PREREQUISITES/60-provisioning-guardrails.md` and `/home/user/Code/idea-to-production/incoming-knowledge/knowledge-vm-debugging/` — both at the MARKETPLACE root, not inside `plugins/foundry/`. A repo-wide grep for `domifaddr|UEFI|generate_mirrorlists|apt-proxy` matches only `agents/handler-ansible.md` itself within any plugin.

**Recommendation:** Either ship the provisioning ledger + VM-debugging field knowledge into `plugins/foundry/knowledge/` (e.g. `knowledge/provisioning/guardrails-ledger.md`, `knowledge/provisioning/vm-debugging/`) and reference them via `${CLAUDE_PLUGIN_ROOT}/knowledge/provisioning/...`, or delete the consult instruction and inline the load-bearing guardrails. A standalone foundry install cannot resolve this instruction at all today — the handler's distinguishing domain knowledge is unreachable.

### 2. [HIGH] Handler is dangling — no spawning surface, roster, model policy, or glossary knows it exists

**Evidence:** Line 8-10 (frontmatter): "Spawned by TEST-AGENT, IMPLEMENT-AGENT, and STORY-AGENT during FOUNDRY pipeline phases when the project stack includes Ansible". But `grep -rn handler-ansible` across `plugins/foundry/{agents,skills,knowledge,commands,.claude-plugin}` (excluding the file itself) returns ZERO hits. The canonical VALUE_HANDLER_POOL in `knowledge/orchestration/agent-roster.md` (~lines 308-310) lists `handler-architect, handler-python, handler-fastapi, handler-js, handler-vanilla-js, handler-react, handler-css, handler-playwright, handler-rust, handler-rust-webapp` — no ansible. `knowledge/policy/model-selection.md` (~line 17) enumerates the `model: inherit` handlers as `handler-{python,js,react,fastapi,css,playwright,vanilla-js,rust,rust-webapp}` — no ansible. The glossary and `skills/builder/SKILL.md` also never mention it.

**Recommendation:** Register the handler everywhere the pool is canonical: add `handler-ansible` to the VALUE_HANDLER_POOL in `agents/builder-lead.md`/`skills/builder/SKILL.md` and `knowledge/orchestration/agent-roster.md`, to the inherit-handler list in `knowledge/policy/model-selection.md`, and to the glossary (via the separate cross-plugin process). Until then, the description's spawning claim is false — the phase agents will never staff Ansible work with this handler.

### 3. [HIGH] Hardcoded concrete model IDs with no reference to the canonical model-selection policy

**Evidence:** Lines 100-102 (Spawning Model Policy table): "`claude-haiku-4-5` (Molecule scenarios / assertions)" / "`claude-sonnet-4-6` (default)" / "`claude-opus-4-8` (end-to-end converge on a real target)". `knowledge/policy/model-selection.md` states (~line 28): "Tiers map to the latest model in each family. Resolve at spawn time, do not hardcode" and "agents reference this table instead of pinning model IDs". The sibling `handler-python.md` (~lines 82-83) at least prefixes its table with "the spawning phase agent chooses the model per the model-selection policy ([link])"; handler-ansible omits that link entirely, so when the canonical table re-tiers, these three IDs silently age out.

**Recommendation:** Replace the concrete IDs with tiers (haiku / sonnet / opus) and add the sibling handlers' lead-in sentence citing `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md` as the resolver — matching the policy's own rule that only the policy table carries IDs.

### 4. [HIGH] The gate mandates 'a real apply' with zero blast-radius containment

**Evidence:** Lines 72-74: "The gate is `ansible-lint` (zero violations) + `ansible-playbook --syntax-check` + a real apply that converges, then a SECOND apply proving `changed=0`." Nothing constrains WHAT the apply targets. The Environment Assumptions block (line 131) even has the handler discover `inventory*` files — so an agent following the gate verbatim will run `ansible-playbook` against the project's actual inventory (live hosts over SSH), twice, with no `--limit`, no requirement to use Molecule's ephemeral instance or localhost, and no instruction to run `--check --diff` first on anything real. Line 102 makes it worse: STORY phase is explicitly "end-to-end converge on a real target".

**Recommendation:** Add a blast-radius GUARDRAIL to the gate: converge only against ephemeral targets (Molecule instance, container, localhost) or an inventory/host explicitly designated by the phase agent's instruction; require `--limit <designated>` on any apply to a real inventory; run `--check --diff` before the first real apply; never apply to an inventory containing non-loopback hosts the instruction did not name.

### 5. [MEDIUM] Internal contradiction: 'never modify test code' vs the Test-First Mandate that orders the handler to write test code

**Evidence:** Line 33: "think before coding, ask if unclear, never widen scope unnecessarily, never modify test code." Yet lines 86-87 mandate: "Write the verification first — a Molecule `verify.yml` assertion ... that FAILS against the unbuilt state", and line 100 says the TEST-phase spawn exists precisely to author "Molecule scenarios / assertions". 'Never modify test code' is an IMPLEMENT-phase rule stated unconditionally for a handler that serves TEST, IMPLEMENT, and STORY phases.

**Recommendation:** Phase-scope the constraint: "When spawned for IMPLEMENT, never modify the verification/Molecule code that gates you — fix the tasks. When spawned for TEST or STORY, authoring verification IS your work." (Note: sibling handler-python.md carries no such unconditional clause — this file added the contradiction.)

### 6. [MEDIUM] No degraded-capabilities handling for absent tooling, despite a gate that hard-requires the tools

**Evidence:** Lines 127-132 probe the environment (`ansible --version && ansible-lint --version`, molecule presence) but give no instruction for the failure branch — and lines 72-74 make `ansible-lint` zero-violations a hard gate. Foundry ships `knowledge/protocols/degraded-capabilities.md` for exactly this; the handler never cites it. An agent with no ansible-lint on PATH must either stall or silently skip the gate.

**Recommendation:** Add after the Environment Assumptions block: "If `ansible` or `ansible-lint` is absent, STOP and surface the missing prerequisite to the phase agent per `${CLAUDE_PLUGIN_ROOT}/knowledge/protocols/degraded-capabilities.md` — never substitute a weaker gate silently. If Molecule is absent, fall back to the scripted second-apply gate and say so in the handoff."

### 7. [MEDIUM] Mixed path-resolution scheme: two load-bearing knowledge refs are runtime-unresolvable relative links

**Evidence:** Lines 111-112 cite canon as "[`../knowledge/first-principles.md`](../knowledge/first-principles.md) §2" and line 170 cites "[`kaizen-covenant.md`](../knowledge/architecture/kaizen-covenant.md)", while lines 31, 36, 57, 63, 135 correctly use `${CLAUDE_PLUGIN_ROOT}/knowledge/...`. At runtime the agent's cwd is the project, not `plugins/foundry/agents/`, so a `Read("../knowledge/first-principles.md")` dangles. (Siblings share the flaw; that makes it fleet drift, not an excuse.)

**Recommendation:** Normalise every knowledge reference in this file to `${CLAUDE_PLUGIN_ROOT}/knowledge/...` per the self-containment law, keeping markdown-link form only as a secondary affordance.

### 8. [LOW] Description claims SUBJECT_MATTER_UNDERSTANDING but the body never operationalizes it

**Evidence:** Line 10: "Carries the KAIZEN self-improvement covenant and the project's SUBJECT_MATTER_UNDERSTANDING." The body contains a KAIZEN Covenant section (lines 164-170) but no instruction to read, acquire, or maintain SUBJECT_MATTER_UNDERSTANDING — the claim is unbacked in this file.

**Recommendation:** Either add one line in the body telling the handler where the project's SUBJECT_MATTER_UNDERSTANDING lives and when to read it, or drop the claim from the description.

### 9. [SUGGESTION] Wrong-model refusal instruction is unverifiable by the agent

**Evidence:** Lines 104-105: "If you were spawned on the wrong model for your phase, refuse and surface the mismatch to the orchestrator before doing any work." A spawned subagent has no reliable introspection of its own model ID, so the instruction cannot be executed as written (fleet-wide pattern shared with siblings).

**Recommendation:** Make the check enforceable on the spawning side: require the phase agent to state the model tier in the spawn prompt, and have the handler verify the STATED tier against the policy table (a checkable string) rather than its own runtime model.

## Capability-uplift proposals

### 1. No blast-radius doctrine for applies against real infrastructure

**Proposal:** Add a section "## Blast-radius containment — THE ONLY WAY" after the gate: "Converge only against (a) a Molecule ephemeral instance, (b) localhost/a container, or (c) a host the phase agent's instruction NAMES explicitly. Any apply to a named real host: run `ansible-playbook --check --diff --limit <host>` first and read the diff; the real apply always carries the same `--limit`. ANTI-PATTERN: `ansible-playbook site.yml` against a discovered inventory — an unscoped apply to hosts nobody designated is an incident, not a test. Record every real-host apply (target, playbook, recap line) in the handoff."

**Rationale:** The current gate (lines 72-74) demands a real apply twice with no target constraint while the environment probe surfaces live inventories — the single most dangerous omission in an IaC handler.

### 2. Vault discipline covers authoring but not operating — no CI/agent-context vault mechanics

**Proposal:** Extend Directive 3 with: "Vault in automation — THE ONLY WAY: the password comes from `--vault-password-file` or `ANSIBLE_VAULT_PASSWORD_FILE`; `--ask-vault-pass` is forbidden in any non-interactive run. Never decrypt a vault file to disk or stdout — use `ansible-vault view` for inspection; edits go through `ansible-vault edit`. The vault password file itself is gitignored and never logged. Re-key (`ansible-vault rekey`) when a secret is rotated. GUARDRAIL: before any commit, grep staged files for plaintext tokens/IPs that should be vaulted (pairs with sentinel's /secret-scan when installed)."

**Rationale:** The handler says secrets live in vault (lines 56-59) but gives the agent no executable procedure for using vault headlessly — the exact context a spawned handler runs in — leaving it to improvise prompts or decrypt-to-stdout.

### 3. No concrete Molecule-absent fallback gate, and no recipe to bootstrap Molecule

**Proposal:** Add "## The scripted gate when Molecule is absent": "Run `ansible-playbook --syntax-check`, then the first apply, then the second apply capturing the recap: `ansible-playbook play.yml | tee /tmp/apply2.log; grep -E 'changed=[1-9]' /tmp/apply2.log && echo IDEMPOTENCE-FAIL`. A non-zero `changed=` on apply #2, or any `failed=`, fails the gate. If the project has roles but no `molecule/`, scaffold the minimal scenario (`molecule init scenario -r <role> --driver-name default` with a delegated/podman platform) before writing verifications, and note the new scenario in the handoff."

**Rationale:** Lines 73-74 say "where Molecule exists" but the no-Molecule branch has no mechanics — 'a scripted second apply asserting changed=0' (line 114) names the idea without the command, recap-parsing, or pass/fail criterion an agent needs.

### 4. No variable-precedence / inventory-hygiene doctrine — the classic Ansible defect class is unaddressed

**Proposal:** Add to Implementation Standards: "Variable placement — role tunables in `defaults/main.yml` (lowest precedence, overridable); environment facts in `group_vars/<group>.yml`; host singletons in `host_vars/`; never duplicate a var at two precedence levels (the 22-level precedence chain makes the shadow silent). `vars:` blocks in plays and `set_fact` for static config are ANTI-PATTERNS — they out-rank inventory and make environments undivergeable. Verify resolution with `ansible-inventory --host <h> --yaml` and `ansible -m debug -a var=<name>` before relying on a value; a var that resolves differently than its file suggests is a defect to fix at the source level, not patch with `-e`."

**Rationale:** Idempotence and FQCN are covered, but the most common real-world Ansible failure — a value silently shadowed across the precedence chain — has no guardrail anywhere in the file.

### 5. No partial-failure / fleet-rollout safety (unreachable hosts, mid-play failure, rolling updates)

**Proposal:** Add "## Partial failure is a state too": "A play that dies mid-fleet leaves drifted hosts — design for it: `serial:` for rolling changes to multi-host groups; `any_errors_fatal: true` where a half-applied change is worse than none; `max_fail_percentage` for tolerant fleets; `block/rescue/always` so cleanup runs on failure paths. Every `rescue` gets its own coordinate — a Molecule/assert scenario that forces the failure and proves the rescue converges. An unreachable host in the recap is a gate FAIL, not a skip: report `unreachable=` count alongside `changed=`."

**Rationale:** The coordinate axes (lines 117-122) cover fresh/converged/drifted hosts but the handler is mute on the failure DURING converge — the case where IaC does real damage — and on testing error paths at all.

### 6. No ansible-core version-skew awareness despite honouring pins

**Proposal:** Extend Environment Assumptions: "Version skew is a defect source: read `ansible --version` (ansible-core X.Y) and each role's `meta/runtime.yml` `requires_ansible` before authoring; module arguments and deprecations differ across core 2.15→2.18 (e.g. removed `include`, jinja2 native-types defaults, `ansible.builtin.apt` cache semantics). When unsure of a module's current arg set for the PINNED core/collection version, resolve the docs for THAT version (context7 MCP or `ansible-doc <fqcn>` locally) — never write args from memory. A lint rule firing only on newer ansible-lint is fixed forward, not silenced."

**Rationale:** Line 134-136 rightly says honour pins, but gives the handler no procedure for writing code that is correct FOR the pinned version — `ansible-doc`/context7 are available and unused, so the handler will author from stale memory against old cores.
