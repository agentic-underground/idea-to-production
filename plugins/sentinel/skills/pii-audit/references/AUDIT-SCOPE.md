# Audit Scope — what each mode scans

This reference defines exactly which directories and file types each `/pii-audit` scope covers,
and how the `.piiignore` exclusion file works. It is the contract the four parallel agents read
so coverage is deterministic and traceable.

---

## Scope matrix

| Scope (`/pii-audit <scope>`) | Agents run | Trees scanned | Skips |
|---|---|---|---|
| `full` (default) | Data, Git, Code, SPA | entire repo from git root | `.piiignore` matches, vendored deps |
| `data` | Data only | `data/ assets/ config/ fixtures/ datasets/` + root data files | source, history |
| `git` | Git only | full history, all branches, tags, `.git/hooks/` | working tree |
| `code` | Code only | `src/ lib/ app/ main/ test/ spec/ tests/` | history, data |
| `spa` | SPA/Frontend only | `frontend/ client/ web/ public/` + any SPA dir | backend, history |
| `<path>` | Data, Code, SPA (no git unless it's a repo root) | the given directory tree | outside the path |

Mode → agent mapping is authoritative: a scope never silently runs more or fewer agents than
listed. If a scope finds the relevant tree absent, the agent reports `CLEAN — tree not present`
rather than skipping silently (no-silent-caps rule).

---

## File types by agent

| Agent | Extensions |
|---|---|
| **Data Files** | `.csv .json .yaml .yml .toml .xml .parquet .orc .sql` |
| **Git History** | all blobs in history (diff-level grep) + commit metadata |
| **Source Code** | `.py .js .ts .tsx .jsx .go .java .rb .php .cs .rs .kt .swift .scala .c .cpp .h` |
| **SPA/Frontend** | `.js .ts .jsx .tsx .html .css .scss .json` + `.env.example`, build configs |

---

## Always-excluded paths (every scope)

These are never scanned for PII (vendored / generated / ephemeral):

```
**/node_modules/**   **/.venv/**   **/venv/**   **/.git/objects/**
**/dist/**           **/build/**   **/.next/**  **/__pycache__/**
**/*.min.js          **/*.map      **/vendor/**  **/target/**
```

Build artefacts (`dist/`, `build/`, source maps) are exempt from the *PII* pass but ARE scanned
by the **secret-scan** skill, because bundled secrets are a real leak vector. Keep the two
concerns distinct.

---

## The `.piiignore` file

Place a `.piiignore` at the project root to exclude additional paths or known-false-positive
patterns. Syntax mirrors `.gitignore` (one glob per line; `#` comments; `!` negation).

```gitignore
# .piiignore — paths and patterns the PII audit should skip
tests/fixtures/synthetic-roster.csv     # documented synthetic data
docs/sample-config.example.json         # placeholder credentials only
*.snapshot.json                          # generated test snapshots
```

Rules:
- A `.piiignore` match removes the file from scanning **and** is recorded in the report appendix
  under "Excluded by .piiignore" — exclusions are always disclosed, never hidden.
- `.piiignore` cannot exclude git history (a leak already in history is not suppressible by a
  working-tree file). The Git History agent ignores it by design.
- When the audit produces a false positive, the recommended remediation is to add a *narrow*
  `.piiignore` entry (a specific file, not a broad `**`), so future audits stay tight.

---

## Scope-to-report contract

Whatever the scope, the consolidated `PII-REPORT.md` always states:
1. The exact scope invoked and the resolved project root.
2. Which agents ran and which trees each one actually found.
3. Any `.piiignore` exclusions applied.

This makes a `data`-only report visibly different from a `full` report — a reader can never
mistake a narrow scan for a clean bill of health across the whole repo.
