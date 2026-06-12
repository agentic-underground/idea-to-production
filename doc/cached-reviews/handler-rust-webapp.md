# Cached review — FOUNDRY handler-rust-webapp

**Target file:** `plugins/foundry/agents/handler-rust-webapp.md`  
**Unit:** `handler-rust-webapp`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Playwright MCP tool grant likely never matches the plugin-scoped tool names

**Evidence:** Frontmatter line 12: "tools: Read, Write, Edit, Bash, Grep, Glob, mcp__playwright__*" and lines 20-22: "You have the `mcp__playwright__*` tools for live, exploratory browser feedback". FOUNDRY bundles the server in plugins/foundry/.mcp.json under the name "playwright", but plugin-provided MCP servers are exposed with a plugin-namespaced prefix — empirically, foundry's own bundled context7 server surfaces as `mcp__plugin_foundry_context7__*` in a live harness, so the playwright server's tools surface as `mcp__plugin_foundry_playwright__*`. The wildcard `mcp__playwright__*` matches none of them, so the browser-feedback capability the body promises is silently absent from the spawned agent's toolset.

**Recommendation:** Verify the actual tool prefix in the target harness and widen the grant (e.g. `mcp__playwright__*, mcp__plugin_foundry_playwright__*`) or use the harness's documented plugin-MCP naming. This defect is shared by handler-{css,js,react,vanilla-js,playwright} and knowledge/tooling/live-feedback.md (line 16) — fix the convention once, fleet-wide.

### 2. [HIGH] "You inherit the general Rust discipline of handler-rust" is inert — a spawned subagent never sees that file

**Evidence:** Lines 40-42: "You inherit the general Rust discipline of `handler-rust` (core is sacred, typed `thiserror` errors, parse-don't-validate, no panics outside tests, coordinates + `proptest`)". A subagent receives only its own definition as its prompt; no resolvable path to `${CLAUDE_PLUGIN_ROOT}/agents/handler-rust.md` is given, and agent definitions are not transitively composed. Everything in handler-rust beyond the one-line parenthetical — the 100% line+branch coverage floor, the 4-step test-first protocol ("run the test and confirm it FAILS for the right reason"), the Implementation Standards section, the debugger recipes, and the entire Security posture section — never reaches this handler's context.

**Recommendation:** Either inline the load-bearing discipline (coverage floor, implementation standards, security posture) into this file, or replace the inheritance claim with an explicit cold-start instruction: "Before any work, Read `${CLAUDE_PLUGIN_ROOT}/agents/handler-rust.md` and adopt its Prime Directive, Implementation Standards, and Security posture sections as your own."

### 3. [HIGH] No security/hostile-input doctrine for a handler that ships a public, internet-facing API

**Evidence:** The only input-handling instruction is line 74: "Invalid input → `400`, never a panic" — and line 102 even confirms "prod alias is public". handler-rust carries a full "Security posture" section ("Assume inputs are hostile and dependencies are guilty until proven innocent... untrusted input reaching `format!`/paths/process-spawn is a BLOCKER. Recommend `cargo audit` / `cargo deny`"), but per the finding above that section never reaches this agent, and this file carries nothing of its own — no injection posture, no supply-chain audit, no mention that everything compiled into the WASM bundle is publicly readable.

**Recommendation:** Add a Security posture section specific to this stack: hostile query/body parsing through core's parse-don't-validate types; `cargo audit`/`cargo deny` in the GATE; the WASM-is-public rule (no secrets, no privileged logic in `web`); response-header hygiene; and the sentinel security-gate composition when installed.

### 4. [HIGH] KAIZEN covenant instructs the handler to write into installed-plugin files, which are read-only outside the marketplace source repo

**Evidence:** Lines 150-154: "fold any new failure mode into a **guardrail** (symptom → cause → fix) in `references/06-guardrails-and-antipatterns.md`, any version drift into the matrix in `references/00-MANIFEST.md`, and any new template lesson into `references/templates/`". Those paths live under `${CLAUDE_PLUGIN_ROOT}/skills/rust-webapp-rollout/`, i.e. the installed plugin. inspection-core.md's GUARDRAIL states "The installed plugin is normally read-only... never write outside the marketplace source" — yet this handler is granted Write/Edit and is told, in a user project, to mutate plugin assets. handler-rust's covenant uses the safe form ("note any... patterns... Flag for the self-improvement covenant") with no write instruction.

**Recommendation:** Rephrase: capture new guardrails/version-drift/template lessons in the PROJECT (e.g. a `GUARDRAIL_PROPOSALS.md` or the handoff report) and flag them for /foundry:self-improve, which applies them to the marketplace source on a branch under pr-approval governance. Only edit references/ directly when running inside the marketplace source repository.

### 5. [MEDIUM] Description omits the TEST-phase spawner that the body's own model-policy table names

**Evidence:** Description lines 6-7: "Spawned by IMPLEMENT-AGENT and STORY-AGENT when the stack manifest is a Rust web app + Vercel function" — but the Spawning Model Policy table (line 131) has the row "`ds-step-3-tests` | TEST (Phase 3) | `claude-haiku-4-5` (test code)", and the Test-First Mandate (lines 141-144) assigns this handler coordinate-writing work. handler-rust's description correctly names "TEST-AGENT, IMPLEMENT-AGENT, and STORY-AGENT". Since the description is what drives delegation, the TEST phase agent may never route RUST_WEBAPP_API test work to this specialist.

**Recommendation:** Amend the description to "Spawned by TEST-AGENT, IMPLEMENT-AGENT, and STORY-AGENT...", matching the body table and handler-rust's pattern.

### 6. [MEDIUM] Hardcoded model IDs contradict the model-selection policy's no-hardcode rule, and the refusal instruction is unverifiable

**Evidence:** Lines 131-133 pin concrete IDs (`claude-haiku-4-5`, `claude-sonnet-4-6`, `claude-opus-4-8`) and lines 134-135 add "If you were spawned on the wrong model for your phase, refuse and surface the mismatch". model-selection.md says "Resolve at spawn time, do not hardcode" and "Agents that legitimately must pin a model state the *tier* here and let this doc carry the ID." The IDs agree with the policy table today, but when the fleet re-tiers (one edit to model-selection.md, by design) this table goes stale and the refusal clause makes the handler reject correctly-spawned work. Also, a subagent cannot reliably introspect its own model ID, so the refusal instruction is largely unactionable.

**Recommendation:** Replace the concrete IDs with tiers (haiku/sonnet/opus) plus a pointer: "resolve via `${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md`". Re-scope the refusal clause to what is checkable: refuse only when the spawning prompt itself declares a phase/tier mismatch.

### 7. [MEDIUM] SUBJECT_MATTER_UNDERSTANDING is claimed in the description but no mechanism exists in the body

**Evidence:** Description lines 10-11: "Carries the KAIZEN covenant and the project's SUBJECT_MATTER_UNDERSTANDING." The body never mentions SMU — no instruction to load `doc/SUBJECT_MATTER_UNDERSTANDING.md`, no `SMU::LOADED` sentinel per knowledge/orchestration/subject-matter-understanding.md and knowledge/protocols/context-sentinel.md (which define the load-and-attest protocol). The claim is unbacked: a cold-start instance has no idea the contract exists.

**Recommendation:** Add a one-paragraph SMU clause: "Before implementing, Read `doc/SUBJECT_MATTER_UNDERSTANDING.md` in the project (protocol: `${CLAUDE_PLUGIN_ROOT}/knowledge/orchestration/subject-matter-understanding.md`) and emit the SMU::LOADED sentinel; if absent, surface the gap to the phase agent instead of guessing domain intent."

### 8. [MEDIUM] Bare `references/...` paths are unanchored and do not resolve from the agent's own location

**Evidence:** Lines 67 ("Canonical matrix: `references/00-MANIFEST.md`"), 88-89 ("`references/04-vercel-rust-runtime.md`"), 105, 114, and 151-153 cite `references/...` with no anchor. From the agent file's directory, `agents/references/` does not exist; the real location is `${CLAUDE_PLUGIN_ROOT}/skills/rust-webapp-rollout/references/`, stated only once at lines 35-37. A cold-start agent resolving paths against its runtime cwd (a user project) will dangle on every later citation; the file also mixes three styles (full ${CLAUDE_PLUGIN_ROOT} paths, relative `../knowledge/...` links, and bare `references/`).

**Recommendation:** Anchor once and define a shorthand explicitly ("`references/` below means `${CLAUDE_PLUGIN_ROOT}/skills/rust-webapp-rollout/references/`"), or expand each citation to the full ${CLAUDE_PLUGIN_ROOT} path, per the self-containment convention the rest of the file already uses.

### 9. [MEDIUM] Inline serverless snippet hand-duplicates the canonical template the file itself forbids hand-authoring — and has already drifted

**Evidence:** Lines 36-38 command: "Do **not** hand-author the canonical files from memory — that reintroduces drift", yet lines 76-87 embed a variant of `references/templates/api-function.rs.tmpl`: the snippet calls `{{crate_prefix}}_server::handle(/* parsed query */)` where the template calls `handle_greet(&name)`, drops the template's percent-decoding and its explanatory comments, and retains `{{crate_prefix}}` placeholders an agent could copy verbatim. (The API itself is current — verified against vercel_runtime 2.2.0 on docs.rs: `run`, `service_fn`, `ResponseBody` are all real exports — so this is a duplication/drift defect, not staleness.)

**Recommendation:** Replace the inline code block with the shape rules only ("hyper-based, no lambda_runtime; handler is HTTP plumbing; invalid input → 400") plus the existing pointer to the template — the template stays the single source of zero drift. If a snippet must stay, label it NON-CANONICAL ILLUSTRATION and state that scaffolding always comes from the template.

### 10. [MEDIUM] No completion/handoff contract — the handler never says what it returns to the phase agent

**Evidence:** The file ends at the KAIZEN Covenant (line 154) with no output protocol. inspection-core.md's agent criteria require "output/completion protocol precise", and the marketplace ships a dedicated handoff-protocol skill ("package artifacts, risks, review status, and next instructions in a strict schema"). For a handler whose done-condition is "the matrix passes against production" (line 106-107), nothing tells it to hand back the production URL, deployment ID, verification-matrix results, or gate evidence — the phase agent must re-derive proof.

**Recommendation:** Add a Completion Protocol section: report the prod alias URL + deployment ID, the verification-matrix table with per-row PASS/FAIL, the GATE command output summary, files created/modified, and any proposed guardrails — formatted per `${CLAUDE_PLUGIN_ROOT}/skills/handoff-protocol/SKILL.md`.

## Capability-uplift proposals

### 1. Preflight toolchain and auth verification before any slice work

**Proposal:** Add section "## Preflight — prove the line can run before loading it": Before GATE, run `rustc --version`, `dx --version`, `cargo zigbuild --version`, `zig version`, `vercel --version`, and `vercel whoami`, and diff each against the proven matrix. Any mismatch or missing tool: STOP and surface a precise report to the phase agent (tool, expected version, found, install hint — `/foundry:check` carries the manifest) instead of failing mid-deploy. An unauthenticated Vercel CLI (no `vercel whoami` identity, no `VERCEL_TOKEN` in CI) is a BLOCKING precondition failure, not something to work around.

**Rationale:** The handler assumes a fully provisioned, authenticated machine (lines 98-102 jump straight to `cargo xtask ci` → `vercel deploy`). A missing zig or expired Vercel token today fails deep inside the BUILD/DEPLOY steps with a confusing error, burning tokens; the marketplace already has /foundry:check but the handler never points at it.

### 2. Failed-deploy and rollback doctrine — VERIFY can fail against production and the handler has no move

**Proposal:** Add to the Build, deploy, verify section: "If any verification-matrix row fails against production, the slice is NOT done and production is presumed broken: immediately repoint the alias to the last verified deployment (`vercel rollback` / `vercel alias set <prev-deployment> <prod-alias>`), record the failing row + response body verbatim, and return NEEDS_REVISION to the phase agent. Never iterate fixes against live production; reproduce on a preview deployment (`vercel deploy --prebuilt` without `--prod`, tested via `vercel curl`) until the matrix is green there, then re-promote."

**Rationale:** Lines 93-107 define a one-way pipeline ending at production verification with no instruction for the failure branch — the single most expensive failure mode this handler owns. The deploy playbook covers mechanics but the agent's own doctrine never tells it that a red matrix means roll back first.

### 3. WASM-is-public secrets doctrine — everything in the Dioxus bundle ships to every browser

**Proposal:** Add a GUARDRAIL: "The WASM bundle is a public artifact. Any value compiled into the `web` crate — `env!()`/`option_env!()` expansions, string literals, embedded keys, privileged URLs — is readable by every visitor. Secrets live only in Vercel environment variables read at runtime by the serverless function (`std::env::var` parsed into a typed config struct in `server`, never in `core` which stays I/O-free). Before DEPLOY, grep the built `*.wasm`/JS output for known secret patterns and any project env-var names; a hit is a BLOCKING defect. The sentinel plugin's /secret-scan composes here when installed."

**Rationale:** The handler builds a browser-delivered binary plus a serverless function and says nothing about secret placement — the classic frontend leak. The FORBIDDEN list covers build mechanics but not this, and the core-purity rule alone doesn't prevent a key landing in the `web` crate.

### 4. Adversarial verification matrix — production VERIFY is a single happy-path curl

**Proposal:** Extend the verify doctrine: "The matrix must include hostile rows, each asserting status AND body shape: missing parameter (expect documented default or 400, never 500), over-long value (10KB query — expect 400), percent-encoding edge cases (`%00`, `%2F`, mixed UTF-8), wrong method (POST to a GET function — expect 405/400), and malformed query separators. Assert `Content-Type: application/json` on every row and that no response ever leaks a panic backtrace or internal path. Each row that exposes a defect becomes a new unit coordinate in `server` before the fix."

**Rationale:** Line 102's VERIFY is `curl .../api/<fn>?name=Claude` — one happy path. The body's own claim "Invalid input → 400, never a panic" (line 74) is asserted nowhere against the deployed artifact, where the runtime layer (not core) handles raw HTTP.

### 5. Dioxus/WASM frontend quality discipline — bundle budget and browser-side test coverage

**Proposal:** Add section "## Frontend discipline (web crate)": (1) Record the released `.wasm` size per slice; an unexplained growth >20% is a finding to surface — investigate with `twiggy top` and prefer `wasm-opt -Oz` in the bundle step. (2) Install a panic hook (`console_error_panic_hook`) in debug builds only, so browser-side panics are diagnosable during MCP exploration but cost nothing in release. (3) Components stay logic-free: any conditional rendering decision is a pure `core`/`ui` function with its own coordinate; what remains in `web` is markup, provable via the story-level matrix and `wasm-bindgen-test` smoke tests where a behaviour can't be hoisted.

**Rationale:** The handler treats `web` as a thin shell proven only at story level (lines 142-144) but gives zero WASM-specific craft: no size budget (a first-class production concern for WASM payloads), no panic observability in the browser, no rule for where rendering logic must be hoisted to stay testable.

### 6. Production observability hooks — the function deploys blind

**Proposal:** Add: "Every serverless function emits one structured JSON log line per request (status, latency_ms, route, error kind — never request payloads or PII) via `eprintln!`/`println!` so Vercel's log drain captures it. After VERIFY, run `vercel logs <prod-alias> --json` and confirm the verification requests appear with expected statuses — this proves the observability channel itself, not just the response. Cold-start latency for the first VERIFY request is recorded in the completion report; >2s is a finding to surface (binary size, allocator, or dependency bloat)."

**Rationale:** The handler's done-condition is a verified production deployment, but nothing instruments it: when the function later fails for a real user, mission-control has nothing to read. One log line and one `vercel logs` assertion close the loop between FOUNDRY's deploy and the OPERATE phase at near-zero cost.
