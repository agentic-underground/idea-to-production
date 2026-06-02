# 12-Factor App Checklist

*https://12factor.net — for deployed services and containers*

| Factor | Principle | Smell |
|---|---|---|
| **I. Codebase** | One codebase, many deploys | Multiple apps in one repo without clear boundaries |
| **II. Dependencies** | Explicitly declare and isolate | `pip install` in entrypoint; global npm installs |
| **III. Config** | Store in the environment | Hardcoded URLs, credentials, or environment names in code |
| **IV. Backing services** | Treat as attached resources | Can't swap dev DB for prod DB by changing an env var |
| **V. Build/Release/Run** | Strict separation | Build process modifies running code |
| **VI. Processes** | Execute as stateless processes | Session stored in process memory (not Redis/DB) |
| **VII. Port binding** | Export services via port binding | App requires a pre-installed web server |
| **VIII. Concurrency** | Scale via the process model | Can't run multiple instances (file locks, in-memory state) |
| **IX. Disposability** | Fast startup, graceful shutdown | Startup > 30s; no SIGTERM handler |
| **X. Dev/prod parity** | Keep environments as similar as possible | "Works on my machine"; different DBs in dev vs prod |
| **XI. Logs** | Treat as event streams | App writes to log files (not stdout) |
| **XII. Admin processes** | Run admin tasks as one-off processes | DB migrations in app startup; no way to run migrations independently |

---

# Pragmatic Programmer Principles Reference

*Andrew Hunt & David Thomas — The Pragmatic Programmer*

## Core Principles

- **DRY — Don't Repeat Yourself** (knowledge, not just text)
- **Orthogonality** — changes in one component don't require changes in others
- **Reversibility** — avoid irreversible decisions; keep options open
- **Tracer Bullets** — build thin end-to-end slices before filling in detail
- **Prototypes** — build to learn, then throw away
- **Estimation** — make and track estimates; learn from the difference
- **The Broken Window Theory** — don't leave bad code in place; it breeds more

## Practical Habits

- **Fix broken windows.** One piece of bad code normalises all bad code.
- **Be a catalyst for change.** Don't just accept bad situations; improve them.
- **Remember the big picture.** Periodically zoom out and check direction.
- **Make quality a requirements issue.** "Good enough" needs to be defined, not assumed.
- **Invest in your knowledge portfolio.** Learn new things regularly.
- **Communicate clearly.** Code is communication. So are commit messages.

## The Pragmatic Programmer Smell Checklist

```
[ ] Duplication of knowledge (DRY violation)
[ ] Tight coupling (change A requires changing B)
[ ] Hardcoded assumptions (not reversible)
[ ] No end-to-end slice tested (tracer bullet missing)
[ ] Broken windows left unaddressed
[ ] No estimation or tracking of estimates
[ ] "It works on my machine" (dev/prod parity missing)
[ ] Magic numbers without named constants
[ ] Code that surprises the reader
[ ] Missing or misleading error messages
```
