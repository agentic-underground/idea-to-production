# 12-Factor App Reference

> For CODE_QUALITY skill — Lens: 12-Factor App.
> Load when reviewing deployed services, containerised applications, or any
> application that runs in a managed execution environment (cloud, PaaS, container).

---

## Overview

The [12-Factor App](https://12factor.net) methodology defines twelve principles for building
software-as-a-service applications that are portable, scalable, and maintainable. Violations
predict operational problems: configuration drift, deployment failures, scaling bottlenecks,
and environment-specific bugs.

---

## Factor I — Codebase

> *One codebase tracked in version control, many deploys.*

**Compliant:** One git repository, deployed to multiple environments (staging, production).
**Violations:**
- Multiple repos for one app that aren't microservices
- Shared code between apps via copy-paste rather than a shared library
- Separate branches per environment (environment config should not be in the codebase)

**Checks:**
```bash
git remote -v           # Confirm single origin
git branch -a           # No env-specific branches (main, staging, prod are wrong)
```

---

## Factor II — Dependencies

> *Explicitly declare and isolate dependencies.*

**Compliant:** All dependencies declared in a manifest (`requirements.txt`, `pyproject.toml`,
`package.json`, `go.mod`). No reliance on system-wide packages. Isolation via venv/container.

**Violations:**
- `import requests` with no corresponding entry in requirements
- Relying on a system-installed tool (`curl`, `imagemagick`) without declaring it
- Pinned to `*` or wide ranges that allow silent breakage

**Checks:**
```bash
# Python: check for undeclared imports
pip install pipreqs && pipreqs . --print | diff - requirements.txt

# Node: check for unlisted imports
npx depcheck
```

---

## Factor III — Config

> *Store config in the environment.*

**Compliant:** All values that vary between environments (DB URLs, API keys, feature flags,
port numbers) come from environment variables. The codebase is identical across deploys.

**Violations:**
```python
# BAD — hardcoded environment-specific value
DB_URL = "postgresql://localhost/mydb"

# BAD — config file committed to repo
config = json.load(open("config.prod.json"))

# BAD — different code branches per environment
if os.getenv("ENV") == "prod":
    ...
```

**Compliant pattern:**
```python
import os
DB_URL = os.environ["DATABASE_URL"]  # Fails fast if unset — intentional
```

**Checks:**
- Search for hardcoded localhost, IPs, API key strings, or environment names in source
- Verify `.env` files are in `.gitignore` (never committed)
- Confirm secrets are not in `settings.json`, `config.yaml`, or similar

```bash
grep -rn "localhost\|127.0.0.1\|api_key\s*=\|password\s*=" src/ --include="*.py"
grep -rn "process.env\." src/ | wc -l   # Should be > 0 for JS configs
```

---

## Factor IV — Backing Services

> *Treat backing services as attached resources.*

**Compliant:** Databases, queues, caches, email services, and external APIs are all accessed
via URLs or credentials from the environment. Swapping from a local PostgreSQL to a managed
RDS requires only a config change, not a code change.

**Violations:**
- Direct import of a DB driver with hardcoded connection string
- Code that behaves differently when connecting to a local vs remote service
- Backing service URL embedded in code

**Check:** Can you point the app at a different database instance with only an environment variable change?

---

## Factor V — Build, Release, Run

> *Strictly separate build and run stages.*

**Compliant:** Three distinct stages:
1. **Build**: Convert code into an executable bundle (compile, collect assets, install deps)
2. **Release**: Combine build with config (creates a release with a unique ID)
3. **Run**: Execute the app in the execution environment

**Violations:**
- Code that modifies files at runtime in ways that affect future runs
- No versioned releases (you can't roll back to a prior release)
- Config baked into the build artifact

---

## Factor VI — Processes

> *Execute the app as one or more stateless processes.*

**Compliant:** Each process is stateless. Any state that must persist is stored in a backing
service (DB, cache, object store). Processes can be killed and restarted without data loss.

**Violations:**
```python
# BAD — in-memory session state
sessions = {}  # dies when the process restarts

# BAD — writing to local filesystem as persistent storage
with open("/app/data/user_uploads/file.jpg", "wb") as f:
    ...
```

**Check:** Can you kill the process and restart it without users losing work or sessions?

---

## Factor VII — Port Binding

> *Export services via port binding.*

**Compliant:** The app is self-contained and exports HTTP (or other protocol) by binding to
a port. It does not rely on runtime injection of a web server.

**Violations:**
- Application requires Apache/nginx to be configured externally to run
- App talks to a specific named host rather than binding itself

**Compliant pattern (Python/FastAPI):**
```python
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))
```

---

## Factor VIII — Concurrency

> *Scale out via the process model.*

**Compliant:** App supports horizontal scaling by spawning more instances. Work is divided
by process type (web processes, worker processes). Each process type scales independently.

**Violations:**
- Singleton state that breaks when two instances run simultaneously
- File locks that prevent concurrent instances
- Scheduled jobs that assume only one instance exists

**Check:** Can two instances of this app run simultaneously without conflicts?

---

## Factor IX — Disposability

> *Maximise robustness with fast startup and graceful shutdown.*

**Compliant:** Processes start quickly (< 5 seconds). On SIGTERM, processes finish current
requests and exit cleanly. Crash-safe: a process that dies mid-request can be restarted
without leaving the system in a bad state.

**Violations:**
- Long startup sequences (loading large files, running migrations at boot)
- No SIGTERM handler — process dies mid-request, leaving partial DB writes
- Database transactions not rolled back on crash

**Check:**
```bash
# Measure startup time
time python -c "import app; app.create_app()"

# Verify graceful shutdown handler exists
grep -n "SIGTERM\|signal\|atexit" src/
```

---

## Factor X — Dev/Prod Parity

> *Keep development, staging, and production as similar as possible.*

**Compliant:** All environments use the same backing services (same DB engine, same cache,
same queue). Differences are config only. Deployments happen frequently (continuous delivery).

**Violations:**
- Dev uses SQLite; prod uses PostgreSQL
- Dev uses an in-memory cache; prod uses Redis
- Differences handled by `if os.getenv("ENV") == "dev"` branches

**Check:** Do unit tests mock the database? (This creates dev/prod parity risk — see test-policy.md)

---

## Factor XI — Logs

> *Treat logs as event streams.*

**Compliant:** The app writes logs to stdout/stderr as an ordered time series of events.
The execution environment (not the app) routes them to a destination (file, log aggregator).
The app never writes to or manages log files.

**Violations:**
```python
# BAD — app manages its own log files
logging.FileHandler("/var/log/myapp/app.log")

# BAD — structured data in unstructured log
print(f"User {user.id} logged in at {datetime.now()}")  # can't query this
```

**Compliant pattern:**
```python
import structlog
log = structlog.get_logger()
log.info("user.login", user_id=user.id)  # structured, goes to stdout
```

---

## Factor XII — Admin Processes

> *Run admin/management tasks as one-off processes.*

**Compliant:** Database migrations, one-off scripts, and REPL sessions run as one-off
processes in the same environment as the app (same config, same codebase). They are
not baked into the app's startup sequence.

**Violations:**
- Migrations run automatically on every app start
- Admin scripts committed to a separate repo with different dependencies
- Manual SQL run directly against the production database

**Compliant pattern:**
```bash
# Run migration as a one-off process
docker run myapp:v1.2 python manage.py migrate

# or
heroku run python manage.py migrate
```

---

## 12-Factor Score Card

Rate the application on each factor: ✅ Compliant / 🟡 Partial / 🔴 Violation

| Factor | Status | Notes |
|---|---|---|
| I Codebase | | |
| II Dependencies | | |
| III Config | | |
| IV Backing Services | | |
| V Build/Release/Run | | |
| VI Processes | | |
| VII Port Binding | | |
| VIII Concurrency | | |
| IX Disposability | | |
| X Dev/Prod Parity | | |
| XI Logs | | |
| XII Admin Processes | | |

---

## Finding Format

```
### 12-Factor App
**Status:** [✅ / 🟡 / 🟠 / 🔴]

**Findings:**
- [Factor N — Name] [Violation description at file:line if applicable].
  [Specific fix recommended].

**Coverage impact:** [How test coverage relates to detecting this violation]
```
