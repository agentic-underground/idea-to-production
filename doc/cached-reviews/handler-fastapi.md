# Cached review — FOUNDRY handler-fastapi

**Target file:** `plugins/foundry/agents/handler-fastapi.md`  
**Unit:** `handler-fastapi`  
**Findings:** 10 · **Capability-uplift proposals:** 6

> Cached output from the adversarial Review stage — raw reviewer findings BEFORE the refute/verify pass and BEFORE any edits were applied. Severity: CRITICAL / HIGH / MEDIUM / LOW / SUGGESTION.

## Findings

### 1. [HIGH] Canonical async test fixture is broken under the strict-mode pytest-asyncio the file itself assumes

**Evidence:** Lines 101-105: "@pytest.fixture\nasync def client():\n    async with AsyncClient(transport=ASGITransport(app=app), base_url=\"http://test\") as c:\n        yield c" — while every test uses the strict-mode marker, line 112: "@pytest.mark.asyncio". Under pytest-asyncio strict mode (the default since 0.21, and the mode the explicit @pytest.mark.asyncio markers imply), a plain @pytest.fixture on an async generator is not awaited — tests receive an async_generator object, not an AsyncClient, and every doctrine test in this file fails at collection-use time.

**Recommendation:** Change the fixture decorator to @pytest_asyncio.fixture (import pytest_asyncio), OR add explicit doctrine that the handler must set asyncio_mode = "auto" in pyproject.toml [tool.pytest.ini_options] and then drop the redundant @pytest.mark.asyncio markers. State which mode is THE ONLY WAY for FOUNDRY projects so generated test suites are internally consistent.

### 2. [HIGH] Description claims SQLAlchemy 2.0 and Alembic expertise; the body carries zero SQLAlchemy 2.0 or Alembic doctrine

**Evidence:** Lines 4-5 (frontmatter): "Expert in FastAPI, Pydantic v2, SQLAlchemy 2.0, Alembic, httpx, pytest-asyncio". The body's only SQLAlchemy code is legacy 1.x-style sync usage inside the BAD example — line 143: "async def create_order(body: CreateOrderRequest, db: Session = Depends(get_db)):" (a sync Session injected into an async route). There is no AsyncSession, no async_sessionmaker, no Mapped[]/mapped_column 2.0 declarative style, no select() statement style, and Alembic appears only as a directory probe — line 87: "ls alembic.ini migrations/ 2>/dev/null".

**Recommendation:** Either narrow the description to what the body teaches, or (better) add the missing doctrine: an "SQLAlchemy 2.0 async standards" section (AsyncSession via async_sessionmaker, Mapped[]/mapped_column models, select() not query(), transactional test fixture) and an "Alembic discipline" section (review every autogenerate diff, upgrade/downgrade roundtrip test, alembic check). A cold-started handler currently cannot deliver the capability its own manifest advertises.

### 3. [MEDIUM] Performance doctrine contradicts itself: a single-sample assertion is presented as proof of a p95 threshold

**Evidence:** Lines 204-212 mandate a one-shot measurement ("start = time.perf_counter() ... assert elapsed_ms < 200") while the threshold table at lines 217-219 states "p95 < 200 ms" / "p95 < 5000 ms", and line 221 makes the assertion "a blocking defect" if missing. One sample cannot assert a 95th percentile, and the first request through an ASGI test client includes app startup/lifespan cost — so the mandated blocking test is both statistically wrong and CI-flaky.

**Recommendation:** Specify the sampling protocol in the handler: warm-up request(s) excluded, N≥20 timed samples, assert sorted(samples)[int(0.95*N)] under threshold (or assert the median with a documented margin and rename the claim). Mirrors test-policy.md §Performance tests, so flag the upstream doc for the same fix per the covenant — but the handler must not ship a flaky blocking gate meanwhile.

### 4. [MEDIUM] Model-pin policy drift: hardcoded model IDs with no reference to the canonical model-selection policy

**Evidence:** Lines 64-66 hardcode "claude-haiku-4-5", "claude-sonnet-4-6", "claude-opus-4-8" in the Spawning Model Policy table. plugins/foundry/knowledge/policy/model-selection.md says "agents reference this table instead of pinning model IDs in their own frontmatter, so the whole fleet can be re-tiered in one edit (and pinned IDs cannot silently age out)" and "Resolve at spawn time, do not hardcode". handler-python.md (line 83) at least cites the policy doc before its table; handler-fastapi cites nothing — when the policy table re-tiers, this file's IDs silently age.

**Recommendation:** Replace the hardcoded IDs with tiers and add the citation handler-python carries: "the spawning phase agent chooses the model per the model-selection policy (`${CLAUDE_PLUGIN_ROOT}/knowledge/policy/model-selection.md`): TEST → haiku tier, IMPLEMENT → sonnet tier, STORY → opus tier — resolve the concrete ID from that table at spawn time."

### 5. [MEDIUM] Internal contradiction: 'never modify test code' vs being spawned by TEST-AGENT to author test code

**Evidence:** Line 26: "think before coding, ask if unclear, never widen scope unnecessarily, never modify test code." — yet lines 6-7 (description) say "Spawned by TEST-AGENT, IMPLEMENT-AGENT, and STORY-AGENT" and the spawning table (line 64) staffs this handler in the TEST phase via ds-step-3-tests, where its entire job is writing test code. The unconditional prohibition is unexecutable in two of the handler's three phases.

**Recommendation:** Scope the rule by phase: "During IMPLEMENT (Phase 4) you never modify test code — tests are the coordinates you satisfy. During TEST and STORY phases you author test code; you still never weaken or delete an existing passing coordinate." (Same defect exists fleet-wide in the other handlers — flag upstream per the covenant.)

### 6. [MEDIUM] Dependency-override doctrine leaks global state across tests

**Evidence:** Line 131: "app.dependency_overrides[get_db] = lambda: FakeDB()" — shown as standalone doctrine with no scoping or cleanup. Mutating the module-level app's dependency_overrides without app.dependency_overrides.clear() pollutes every subsequent test in the session, the classic FastAPI test-isolation failure.

**Recommendation:** Make the canonical form a fixture: override inside a fixture, yield, then app.dependency_overrides.clear() in teardown (or use an app-factory pattern so each test gets a fresh app). State explicitly that bare module-level overrides are a defect the reviewer should catch.

### 7. [MEDIUM] Tests depend on an undefined db_session fixture; no test-database strategy exists

**Evidence:** Lines 113 and 119 pass db_session into the canonical route tests ("async def test_create_user_returns_201(client, db_session):") but the fixture is never defined anywhere in the file, and the file carries no doctrine for the test DB (in-memory SQLite vs transactional-rollback Postgres vs testcontainers). A cold-started handler cannot reproduce its own doctrine examples.

**Recommendation:** Define the canonical db_session fixture in the Testing Standards section: async engine on a per-test database (state the chosen strategy — e.g. transaction-per-test with rollback on an async engine), wired through dependency_overrides so client and db_session share the session. State when SQLite-in-memory is acceptable and when it is not (dialect-specific SQL, JSONB, constraints).

### 8. [LOW] No failure-mode handling for the environment probe; uv-only assumption with no fallback

**Evidence:** Lines 76-88 probe only `uv` and `pyproject.toml` ("which uv && uv --version", "cat pyproject.toml | grep ..."); line 193 hardcodes "uv run pytest". Nothing says what to do when uv is absent, the project uses poetry/pip/requirements.txt, pyproject.toml is missing, or the grep finds no pytest-asyncio (a sync-only FastAPI app).

**Recommendation:** Add a short "When the probe fails" ladder: pyproject absent → ask the phase agent before scaffolding; uv absent → fall back to `python -m pytest` and report the toolchain gap; pytest-asyncio absent → add it (pinned) before writing async tests, or fall back to sync TestClient doctrine for a sync app.

### 9. [LOW] Unverifiable self-check: handler told to refuse when spawned on the wrong model

**Evidence:** Lines 68-69: "If you were spawned on the wrong model for your phase, refuse and surface the mismatch to the orchestrator." A model:inherit subagent has no reliable way to introspect which concrete model it is running on, so the instruction cannot be executed and creates false confidence that the policy is self-enforcing.

**Recommendation:** Move enforcement to the spawner side: "The spawning phase agent states the chosen model in the spawn prompt; if no model statement is present, ask the orchestrator before proceeding." That converts an unverifiable introspection into a checkable contract field.

### 10. [LOW] Inconsistent path resolution: one ${CLAUDE_PLUGIN_ROOT} reference, three runtime-dead relative links

**Evidence:** Line 24 correctly uses "${CLAUDE_PLUGIN_ROOT}/knowledge/pillars/implementation-covenant.md", but lines 43-44 and 229 use "../knowledge/first-principles.md", "../knowledge/testing/test-policy.md", "(../knowledge/architecture/solid-covenant.md)". They stay inside the plugin root (so not a self-containment violation), but at runtime the agent's cwd is the project, so a handler that tries to Read those paths gets ENOENT — only the line-24 form is actionable.

**Recommendation:** Normalise every load-bearing knowledge reference to the ${CLAUDE_PLUGIN_ROOT}/knowledge/... form (keep relative markdown links only where they are purely navigational for humans, and say so). Also fix the cosmetic `cat pyproject.toml | grep` (line 81) to `grep -E ... pyproject.toml` while touching the file.

## Capability-uplift proposals

### 1. No SQLAlchemy 2.0 async doctrine (AsyncSession, 2.0 declarative models, transactional test fixture)

**Proposal:** Add an "SQLAlchemy 2.0 Standards" section: models use `class User(Base): __tablename__='users'; id: Mapped[int] = mapped_column(primary_key=True)` — never legacy Column-without-Mapped; sessions are `AsyncSession` from `async_sessionmaker(engine, expire_on_commit=False)` injected via a `get_db` dependency that yields and rolls back on exception; queries use `await session.execute(select(User).where(...))` — `session.query()` is a blocking defect; the canonical test fixture opens a connection, begins an outer transaction, binds an AsyncSession to it, and rolls back in teardown so every test is isolated without re-creating the schema.

**Rationale:** The frontmatter promises SQLAlchemy 2.0 expertise but the body teaches none of it; the only SQLAlchemy code shown is legacy sync style. This is the single largest gap between claim and capability.

### 2. No Alembic migration discipline despite Alembic in the manifest

**Proposal:** Add a "Migrations" section: every model change ships with an Alembic revision in the same slice; autogenerate output is REVIEWED line-by-line (autogenerate misses server defaults, constraint renames, and enum changes — list these); each revision must pass an upgrade→downgrade→upgrade roundtrip test against an empty database; run `alembic check` (or `alembic upgrade head` + autogenerate-is-empty assertion) as a coordinate in CI; never edit an applied revision — add a new one.

**Rationale:** The handler only probes for `alembic.ini` existing; it has no doctrine for the riskiest artefact a FastAPI/SQLAlchemy project produces — schema migrations.

### 3. Per-route try/except error handling contradicts the handler's own 'routes are thin' standard; no app-level exception-handler doctrine

**Proposal:** Replace the per-route try/except example (lines 182-188) with the registered-handler pattern as THE ONLY WAY: `@app.exception_handler(NotFoundError)` / `@app.exception_handler(ConflictError)` mapping each domain error to a status + RFC 9457 problem-details body once, app-wide; routes never catch domain errors. Add the matching coordinates: one test per (domain error → status, body shape) mapping, asserted through the test client, plus a test that an unmapped exception yields a sanitised 500 with no stack trace or internals in the body.

**Rationale:** The Error handling section currently teaches boilerplate the Implementation Standards section forbids; centralised handlers are both the FastAPI idiom and the only place the hostile-input/leakage failure mode can be pinned once.

### 4. No lifespan or settings doctrine — startup events and configuration are unhandled failure modes

**Proposal:** Add an "App wiring" section: use the `lifespan` async context manager (`@asynccontextmanager async def lifespan(app): ...; app = FastAPI(lifespan=lifespan)`) — `@app.on_event` is deprecated and is a defect; configuration comes from a `pydantic-settings` `BaseSettings` class injected as a dependency (12-factor, per `${CLAUDE_PLUGIN_ROOT}/knowledge/architecture/twelve-factor.md`), with tests overriding settings via dependency_overrides or env monkeypatching — never by editing a settings singleton; the test client must enter the lifespan (httpx `ASGITransport` does not run lifespan — use `asgi_lifespan.LifespanManager` or document that fixtures bypass startup and pin startup behaviour separately).

**Rationale:** Lifespan is where DB engines, caches, and clients are built; the current doctrine's ASGITransport fixture silently skips it, which is an undocumented failure mode that produces tests passing against an app that crashes at real startup.

### 5. No auth/security or hostile-input testing doctrine

**Proposal:** Add a "Security coordinates — required for any protected or input-bearing route" section: every auth-protected route carries 401 (no credentials) and 403 (wrong scope/role) coordinates; the canonical override for auth in tests is `app.dependency_overrides[get_current_user] = lambda: stub_user(scopes=[...])` inside a scoped fixture; every input-bearing route carries hostile-input coordinates — oversized payload (assert 413/422, and that Pydantic `max_length`/`Field(le=...)` bounds exist), wrong content-type, extra fields (models declare `model_config = ConfigDict(extra='forbid')` for request bodies), and type-confusion values; response models never echo secrets — assert the response body excludes password/token fields via `response_model` filtering.

**Rationale:** The handler tests only happy/422/409 paths; authentication, authorisation, and hostile input are the failure modes a production API meets first, and the handler currently has no doctrine for any of them.

### 6. Tooling underuse: no live-feedback (debugger/LSP) block, no current-docs lookup, no contract-level output check

**Proposal:** Add the tooling preamble the sibling handler-python carries, adapted: "Drive `python -m pdb`/`debugpy` through Bash to inspect a failing async test; lean on `pyright` and `ruff` for diagnostics before running the suite — see `${CLAUDE_PLUGIN_ROOT}/knowledge/tooling/live-feedback.md`." Add: "Before using a FastAPI/Pydantic/SQLAlchemy API you have not used this session, verify the current signature via the context7 docs MCP when available — these libraries deprecate fast (on_event→lifespan, validator→field_validator, query()→select())." Add an output contract: at STORY phase, snapshot `app.openapi()` to a committed `openapi.json` and add a coordinate asserting the live schema matches the snapshot, so contract drift is a failing test, not a surprise.

**Rationale:** handler-python ships a debugger/LSP block and the marketplace ships a context7 docs server; handler-fastapi uses neither, and it has no machine-checkable definition of its own output contract (the OpenAPI schema) despite that being FastAPI's signature artefact.
