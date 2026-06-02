# Parallel Agent Instructions for PII Audit

This document provides detailed instructions for each of the four parallel agents that execute in the `pii-audit` skill. Each agent runs independently and returns findings in a standardized markdown format for consolidation.

---

## Shared Instructions (All Agents)

### PII Definition

Use the taxonomy in `PII-DEFINITION.md`. At minimum, scan for:

**Always flag:**
- Real personal names (linked to roles, assignments, sensitive contexts)
- Email addresses (personal, work, organizational if private)
- Phone numbers
- Addresses or location-specific personal data
- Government IDs (SSN, passport, driver's license)
- API keys, tokens, passwords, credentials
- Private encryption keys
- Financial information (account numbers, card numbers, salary data)
- Biometric or health information

**Context-dependent:**
- Names only if they identify real individuals in sensitive contexts
- Dates only if linked to person + sensitive info
- Usernames only if they uniquely identify a real person

**Acceptable (do not flag):**
- Synthetic test fixture names (if clearly marked as test data)
- Public organizational email addresses
- Generic placeholder credentials (example.com, test@test.com)
- Masked system addresses (noreply@, bot@)
- Published public information

### Finding Format

Each finding must include:

```markdown
**File:** `/full/path/to/file`
**Type:** [name | email | phone | address | id | credential | key | other]
**Risk:** [CRITICAL | HIGH | MEDIUM | LOW]
**Context:** [relevant code snippet or description]
**Example (redacted):** [example value with sensitive parts redacted, e.g., sarah.chen@*****.com]
```

### Output Format

Return findings as a markdown section with agent name as heading:

```markdown
## [AGENT NAME]

### Summary
[1-2 sentences about what was scanned and overall findings]

### Findings

**Finding 1:**
**File:** ...
**Type:** ...
(etc.)

**Finding 2:**
...

### Conclusion
**Status:** [CLEAN | FINDINGS]
**Risk Level:** [MINIMAL | LOW | MEDIUM | HIGH | CRITICAL]
[1-2 sentence summary of implications]
```

If no findings, report:

```markdown
## [AGENT NAME]

### Summary
Scanned [scope] for PII. No sensitive information detected.

### Findings
✓ CLEAN — No PII found

### Conclusion
**Status:** CLEAN
**Risk Level:** MINIMAL ✓
```

---

## Agent 1: Data Files Audit

**Scope:** CSV, JSON, YAML, TOML, XML data files in project

**Directories to scan (in order):**
1. `data/` (top level)
2. `*/data/` (any subdirectory named data)
3. `assets/`
4. `config/`
5. `fixtures/`
6. `datasets/`
7. Any file ending in `.json` at project root (e.g., `roster-data.json`)

**File types:**
- `.csv` — inspect all columns for PII
- `.json` — traverse all keys/values
- `.yaml`, `.yml` — scan all fields
- `.toml` — scan all key-value pairs
- `.xml` — scan all elements and attributes
- `.parquet`, `.orc` — if readable, sample data

**Instructions:**

1. **List all data files** in the above directories
2. **For each file:**
   - Read entire contents
   - Look for column names or keys that hint at PII (name, email, phone, address, ssn, password, api_key, token, etc.)
   - Scan values in those columns for actual PII
   - Check for inline comments containing PII
3. **Document findings** with file path, field/column name, type, and example values (redacted)
4. **Report context** — is this a production data file, test fixture, or configuration?

**Special cases:**
- **SQL dump files** — if present, scan for INSERT statements with PII
- **Database snapshots** — flag any clear production data
- **Test fixtures** — note if clearly synthetic (e.g., comment "// test data")
- **Gitignored data files** — if present on disk (untracked), note that they're gitignored

**Example output:**

```markdown
## DATA FILES

### Summary
Scanned data/, roster-spa/data/, and project root for CSV, JSON, YAML files. Found volunteer names in fixtures.

### Findings

**Finding 1: Volunteer Names in Fixtures**
**File:** `data/volunteers.csv`
**Type:** name (linked to job assignments)
**Risk:** LOW
**Context:** Test fixture data for roster scheduling algorithm. Names are synthetic but realistic-looking (Hugo Harris, Kaiden Height, etc.)
**Example:** volunteer_name: "Hugo Harris", job: "Umpire Escort"

**Finding 2: Snapshot Data**
**File:** `roster-spa/roster-data.json`
**Type:** name (in test data)
**Risk:** LOW
**Context:** Committed test fixture. Same volunteer names as volunteers.csv.

### Conclusion
**Status:** FINDINGS (low-risk fixtures)
**Risk Level:** LOW ✓
Test fixture names are clearly marked as synthetic data for algorithm testing. No real PII or production data exposed.
```

---

## Agent 2: Git History Audit

**Scope:** Git history (all commits, branches, tags)

**Instructions:**

1. **Initialize git scan:**
   ```bash
   cd /path/to/project
   git config credential.helper store  # (safely enable credential view if needed)
   ```

2. **Scan all commits:**
   ```bash
   git log --all --pretty=format:"%h %s" > /tmp/commits.txt
   git log -p --all > /tmp/git_diff.patch  # (warning: large files)
   ```

3. **Look for PII in:**
   - Commit messages (esp. "Added password" or config changes)
   - Commit diffs (added files with credentials)
   - Author emails (if personally identifying)
   - Commit bodies and notes

4. **Search for patterns:**
   ```bash
   git log -p --all | grep -i "password\|api_key\|token\|secret\|ssn\|credit_card\|private.*key"
   git log -p --all | grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"  # emails
   git log -p --all | grep -E "^\+.*password.*=" # added password assignments
   ```

5. **Check for deleted but history-preserved files:**
   ```bash
   git log --all --full-history -- ".env" ".secrets" "credentials.json"
   ```

6. **Document findings** with:
   - Commit hash (abbreviated)
   - Commit message
   - File affected
   - Type of PII
   - When discovered (e.g., "still in history")

7. **Risk assessment:**
   - **CRITICAL:** Active credentials still valid (passwords, API keys)
   - **HIGH:** Credentials in recent commits (might still be live)
   - **MEDIUM:** Credentials in old commits (might be rotated, but verify)
   - **LOW:** Credentials in very old commits (likely rotated)

**Special cases:**
- **Rewritten history** — if branches have been force-pushed, note that history might not be complete
- **Sensitive commits in branches** — scan feature branches, develop, staging, etc. not just main
- **Submodules** — if present, scan submodule history too
- **Git hooks** — check `.git/hooks/` for leaks

**Example output:**

```markdown
## git history trawler

### Summary
Comprehensive scan of git history across all commits and branches. Searched commit messages, diffs, and author info for PII and credentials. Verified gitignore rules for sensitive files.

### Findings
✓ CLEAN — No credentials or real PII found in history

### Conclusion
**Status:** CLEAN
**Risk Level:** MINIMAL ✓
Repository practices properly protect sensitive information. `.gitignore` correctly excludes `.env`, `.secrets`, and credential files. No passwords, API keys, or real personal data committed.
```

---

## Agent 3: Source Code Audit

**Scope:** All source code files (Python, JavaScript, TypeScript, Java, Go, Ruby, etc.)

**Directories to scan:**
- `src/`, `lib/`, `app/`, `main/` — source code
- `test/`, `spec/`, `tests/` — test files (look for hardcoded credentials, real data)
- Any `.py`, `.js`, `.ts`, `.tsx`, `.go`, `.java`, `.rb`, `.php`, `.cs` file

**Instructions:**

1. **Enumerate all source files:**
   ```bash
   find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" \
           -o -name "*.go" -o -name "*.java" -o -name "*.rb" -o -name "*.php" \) \
           ! -path "*/node_modules/*" ! -path "*/.venv/*" ! -path "*/venv/*"
   ```

2. **For each file, scan for:**
   - **Strings containing PII:**
     ```python
     password = "MyPassword123"
     api_key = "sk_live_..."
     email = "person@gmail.com"
     ```
   - **Comments with PII:**
     ```python
     # TODO: Add Sarah Chen's email: sarah.chen@company.com
     # NOTE: Use prod credentials: user=admin, pass=secret123
     ```
   - **Hardcoded config:**
     ```python
     DATABASE_URL = "postgres://admin:pass@prod.db.com/myapp"
     SLACK_WEBHOOK = "https://hooks.slack.com/services/T123/B456/abc..."
     ```
   - **Test data with real info:**
     ```python
     test_user_email = "jane.doe@company.com"  # Real person's email!
     ```

3. **Pattern matching (language-agnostic):**
   - `password\s*[:=]\s*["\'].*["\']` — password assignments
   - `api_key\s*[:=]\s*["\'].*["\']` — API keys
   - `token\s*[:=]\s*["\'].*["\']` — tokens
   - `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}` — email addresses
   - `(?:sk_live|pk_live|rk_live)_[a-zA-Z0-9]{20,}` — Stripe keys
   - `AWS[_-]?[A-Z]+[_-]?[A-Z]+` — AWS credentials patterns
   - `-----BEGIN (RSA|DSA|EC) (PRIVATE KEY|PUBLIC KEY)-----` — crypto keys

4. **Exclude false positives:**
   - Test fixtures marked with `@pytest.fixture`, `describe(` (Jest), etc.
   - Example/placeholder values (example@example.com, test123, demo_key)
   - Documentation (comments describing how to set credentials, not actual credentials)
   - Mocked/stubbed values in tests

5. **Document findings** with:
   - File path
   - Line number(s)
   - Snippet of code (redacted if sensitive)
   - Type of PII
   - Risk level

**Example output:**

```markdown
## PYTHON CODE

### Summary
Scanned 122 Python files (excluding .venv) for hardcoded credentials, API keys, passwords, and personal information in strings and comments. No real PII detected.

### Findings

**Finding 1: Test Fixtures with Names**
**File:** `test/conftest.py`
**Type:** name (in test fixture)
**Risk:** LOW
**Context:** Synthetic test fixture names in parametrized tests. Names are clearly fake (Rachel Williams, Helen Martinez).
**Example:** `pytest.mark.parametrize("volunteer", ["Rachel Williams", "Helen Martinez"])`

### Conclusion
**Status:** CLEAN
**Risk Level:** MINIMAL ✓
All personal-like data in code are clearly synthetic test fixtures. No hardcoded credentials, API keys, passwords, or real personal information detected.
```

---

## Agent 4: SPA/Frontend Audit

**Scope:** Frontend codebase (JavaScript, TypeScript, React, Vue, HTML, CSS)

**Directories to scan:**
- `roster-spa/`, `frontend/`, `client/`, `web/`, `public/` — any frontend directory
- `.js`, `.ts`, `.jsx`, `.tsx` files
- `.html` files
- `.json` config files (package.json, build configs)
- `.css` (esp. for embedded URLs with credentials)
- Environment templates (`.env.example`, `config.example.js`)

**Instructions:**

1. **Enumerate all frontend files:**
   ```bash
   find ./roster-spa -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" \
           -o -name "*.tsx" -o -name "*.html" -o -name "*.json" \) \
           ! -path "*/node_modules/*"
   ```

2. **Scan for embedded PII:**
   - **API endpoints with credentials:**
     ```javascript
     const API_URL = "https://user:password@api.example.com/";
     const API_KEY = "sk_live_abc123def456";
     ```
   - **Local storage/session storage code:**
     ```javascript
     localStorage.setItem("user_email", "jane@company.com");
     sessionStorage.setItem("auth_token", "eyJh...");
     ```
   - **Environment variables hardcoded:**
     ```javascript
     const SLACK_WEBHOOK = process.env.SLACK_WEBHOOK || "https://hooks.slack.com/...";
     ```
   - **Config files with credentials:**
     ```json
     {
       "api_url": "https://admin:pass@api.prod.com",
       "db_connection": "postgres://root:root@localhost"
     }
     ```
   - **Comments with PII:**
     ```javascript
     // FIXME: Email Sarah Chen at sarah.chen@company.com to fix this
     // DEBUG: Use test user email@gmail.com
     ```
   - **HTML comments:**
     ```html
     <!-- TODO: Replace with real API key from admin@company.com -->
     ```

3. **Pattern matching (frontend-specific):**
   - API URLs with embedded auth (`.com/user:pass@`)
   - Bearer tokens in code (`Authorization: Bearer eyJ...`)
   - AWS/GCP/Firebase config objects with credentials
   - Third-party API keys (Stripe, Twilio, SendGrid, etc.)
   - Database connection strings
   - Webhook URLs with sensitive paths

4. **Check build artifacts:**
   - `dist/`, `build/` — are credentials embedded in bundled code?
   - `.env.local` (if not gitignored) — contains credentials?
   - Source maps — do they expose API keys from source?

5. **Document findings** with:
   - File path
   - Exact location (line, function, etc.)
   - Exposed type (API key, email, credential, etc.)
   - Risk level
   - Remediation (move to env var, use build-time secrets, etc.)

**Example output:**

```markdown
## SPA PII

### Summary
Comprehensive scan of roster-spa/ directory. Examined JavaScript, TypeScript, HTML, CSS, and JSON config files for embedded PII, API keys, credentials, and personal information. Found test fixture data only.

### Findings

**Finding 1: Volunteer Names in Test Fixture**
**File:** `roster-spa/roster-data.json`
**Type:** name (test fixture)
**Risk:** LOW
**Context:** Committed test fixture for CI and local testing. Names are synthetic (Hugo Harris, Kaiden Height, etc.).
**Example:** `"volunteer_name": "Hugo Harris"`

### Conclusion
**Status:** CLEAN
**Risk Level:** LOW ✓
SPA code is secure. No API keys, credentials, or real PII exposed. Test fixture names are clearly synthetic data. No hardcoded secrets in config or environment setup.
```

---

## Report Consolidation

After all 4 agents return findings:

1. **Merge findings** under appropriate section headings (DATA FILES, git history trawler, PYTHON CODE, SPA PII)
2. **Deduplicate** — same finding reported by 2 agents gets listed once with "confirmed by"
3. **Aggregate risk** — overall risk = highest individual finding
4. **Create executive summary** — quick table of findings per component
5. **Append recommendations** — based on findings, what should be done?
6. **Add appendix** — complete file inventory scanned

---

## Edge Cases & Decisions

| Situation | Decision | Rationale |
|-----------|----------|-----------|
| **Synthetic fixture named "Hugo Harris"** | Report as LOW | Clearly test data, but document to show audit is thorough |
| **Email "support@company.com"** | Don't report | Organizational, public info |
| **Email "john.smith@company.com" in code** | Report as HIGH | Personal work email, privacy concern |
| **API key in `.env` (gitignored)** | Report with note "gitignored" | Still a risk if someone commits it |
| **Old password in git history** | Report as MEDIUM/HIGH | Might be rotated, but verify |
| **Test user "testuser@example.com"** | Don't report | Generic placeholder |
| **Ambiguous: is this real?** | Report with context | Let human decide |

---

## Model & Performance Notes

- **Model:** Haiku 4.5 (cost-optimized for scanning)
- **Parallelization:** All 4 agents run independently, no coordination
- **Timeout:** 5 minutes per agent (total ~5 min for full audit)
- **Output:** Each agent returns structured markdown, no extra explanation

---

## Continuous Improvement

- Every missed PII pattern → add to detection rules
- Every false positive → add to exclusion patterns
- Every new privacy regulation → update PII-DEFINITION.md
- User feedback → implement in next skill iteration
