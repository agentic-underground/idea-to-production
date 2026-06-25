---
name: scan-for-pii
description: >
  Automated PII (Personally Identifiable Information) and security audit across
  codebases. Scans data files, git history, code, and configuration for sensitive
  information (names, emails, phone numbers, API keys, passwords, credentials).
  Runs parallel audits across data, git, code, and SPA layers. Produces
  comprehensive PII-REPORT.md with findings, risk assessments, and recommendations.
  Trigger with /scan-for-pii [scope] where scope is: full (all systems), data (data files only),
  git (history only), code (source code only), spa (SPA/frontend only), or project-root
  for a specific directory. Default: full scan of current repository.
---

# PII Audit Skill

Comprehensive personally identifiable information (PII) and security credential audit for software projects. Executes **parallel multi-agent scans** across data files, git history, source code, and SPA codebases to identify and report any sensitive information that may have been committed or exposed.

---

## Quick Start

```bash
# Full audit of current repository
/scan-for-pii

# Audit specific scope
/scan-for-pii data                 # data files only
/scan-for-pii git                  # git history only
/scan-for-pii code                 # source code only
/scan-for-pii spa                  # frontend/SPA only
/scan-for-pii /path/to/project     # custom project root
```

---

## What This Skill Does

### 1. **Defines PII Comprehensively**

PII includes ANY sensitive information about identifiable people or systems:
- Personal names (especially when linked to roles, assignments, or sensitive contexts)
- Email addresses (personal or work)
- Phone numbers
- Home/personal addresses and postal codes
- Birthdates, age, or personal dates
- Government IDs (SSN, passport, driver's license)
- Financial information (bank accounts, credit cards, payment data)
- API keys, authentication tokens, session credentials
- Passwords or password-like secrets
- Encryption keys (private keys, symmetric keys)
- Any other data classified as private/sensitive about identifiable individuals

**Excludes:**
- Proprietary code logic and business logic
- Generic location names (public parks, venues, clubs)
- Test fixtures clearly documented as synthetic/placeholder data
- Public organizational email addresses
- Masked/noreply system addresses

### 2. **Executes Parallel Audits**

Spawns **4 independent parallel agents** to maximize coverage and speed:

| Agent | Scope | Technique | Output |
|-------|-------|-----------|--------|
| **Data Files Agent** | CSV, JSON, YAML in data/, assets/, config/ | File-by-file inspection | List of findings by file/field |
| **Git History Agent** | All commits, branches, tags | `git log -p`, grep patterns, history traversal | Findings by commit/file, no risk if clean |
| **Source Code Agent** | Python, JavaScript, TypeScript, Go, Java, etc. | String/comment inspection, token detection | Code location, line numbers, context |
| **SPA/Frontend Agent** | Frontend files (JS, TS, HTML, CSS, JSON) | Frontend-specific scanning | UI/config exposure risks |

### 3. **Produces Rich Report**

Creates `PII-REPORT.md` with:
- **Executive summary** — risk level (MINIMAL/LOW/MEDIUM/HIGH)
- **Agent findings** — per-agent detailed results with context
- **Risk assessment** — what was found, where, and why it matters
- **Recommendations** — immediate action items and future-proofing
- **Appendix** — complete file inventory with full paths
- **Methodology** — traceability of how the audit was performed

---

## Usage Modes

### Mode 1: Full Audit (Default)

**When:** Initial security review, before open-sourcing, after significant data changes, periodic compliance checks

**Execution:**
```bash
/scan-for-pii
```

**Scans:**
- All data files in project
- Complete git history (all commits, branches)
- All source code
- SPA/frontend code
- Configuration files

**Output:** Comprehensive `PII-REPORT.md` with all findings aggregated

---

### Mode 2: Targeted Scope Audits

**When:** Incremental checks, specific layer concerns, post-deployment verification

**Examples:**
```bash
/scan-for-pii data              # Just data files (CSV, JSON)
/scan-for-pii git               # Just git history (check for commits with leaks)
/scan-for-pii code              # Just source code (find hardcoded secrets)
/scan-for-pii spa               # Just frontend (check for embedded PII)
/scan-for-pii /path/to/app      # Custom directory
```

**Each scope:**
- Reuses agent infrastructure from full audits
- Produces focused findings
- Faster execution than full scan
- Still generates PII-REPORT.md for consistency

---

## Audit Process

### Phase 1: Scope Definition

1. User invokes `/scan-for-pii [scope]`
2. Skill parses scope (default: full)
3. Locates project root (git root or provided path)
4. Validates readable directories exist

### Phase 2: PII Definition Briefing

All agents receive:
- Comprehensive PII definition (see [`references/PII-DEFINITION.md`](references/PII-DEFINITION.md))
- Project-specific context (language, framework)
- Output format requirements
- Risk classification rules

### Phase 3: Parallel Agent Execution

Each agent:
1. Receives targeted scan instructions
2. Runs independently (no coordination needed)
3. Documents findings with:
   - File/location
   - Type of PII detected
   - Risk classification
   - Example value (redacted if needed)
4. Returns structured markdown findings

### Phase 4: Report Consolidation

Results are merged into single `PII-REPORT.md`:
- Executive summary with overall risk level
- Per-agent findings under labeled sections
- Deduplication (no duplicate findings across agents)
- Aggregated risk assessment
- Recommendations based on findings
- Appendix with complete file inventory

### Phase 5: Commit & Push (Optional)

If findings are acceptable, automatically stage and commit report:
```bash
git add PII-REPORT.md
git commit -m "docs: add PII audit report — [summary]"
git push origin [branch]
```

---

## Findings Classification

Each finding is classified by **risk level**:

| Level | Meaning | Action | Example |
|-------|---------|--------|---------|
| **CRITICAL** | Real PII or active credentials in code | Immediate remediation | API key, password, SSN |
| **HIGH** | Real personal data that should be private | Fix before shipping | Real person's email/phone |
| **MEDIUM** | Borderline data (context matters) | Review and decide | Test data vs production data |
| **LOW** | Unlikely to be real PII | Monitor | Synthetic names in fixtures |
| **MINIMAL** | No PII found | Document | Empty result |

---

## Reference Documents

| Document | Purpose |
|----------|---------|
| [`references/PII-DEFINITION.md`](references/PII-DEFINITION.md) | Detailed PII taxonomy with examples |
| [`references/AUDIT-SCOPE.md`](references/AUDIT-SCOPE.md) | Directories and file types scanned per mode |
| [`references/AGENT-INSTRUCTIONS.md`](references/AGENT-INSTRUCTIONS.md) | Per-agent scan instructions and techniques |
| [`references/REMEDIATION.md`](references/REMEDIATION.md) | How to fix common PII exposure issues |
| [`references/COMPLIANCE-NOTES.md`](references/COMPLIANCE-NOTES.md) | GDPR, CCPA, and other privacy regulations |

---

## Common Questions

**Q: Does the audit catch all PII?**  
A: The audit is comprehensive but not foolproof. It catches patterns and common mistakes (hardcoded keys, email addresses, phone patterns). It won't catch cleverly obfuscated data. Treat it as "trust but verify" — review findings carefully.

**Q: Can I exclude certain files/directories?**  
A: Yes. Pass a `.piiignore` file in project root with patterns (one per line, glob syntax). Files matching are skipped.

**Q: What if I have false positives?**  
A: Comment them in the report. Update `.piiignore` to skip that file/pattern in future audits. Contact skill maintainer if the pattern is systematic.

**Q: Can I audit a third-party project?**  
A: Yes. Provide the full path: `/scan-for-pii /path/to/project`. Audit runs on that tree; report is written to that directory.

**Q: How often should I audit?**  
A: Minimum: before any public release. Recommended: on every PR, via CI, or monthly. The cost is low; the risk of missing a leak is high.

---

## What Gets Reported?

**Reported (if found):**
- ✅ Real personal names linked to sensitive roles/assignments
- ✅ Email addresses (personal, work, organizational)
- ✅ Phone numbers in any format
- ✅ Addresses or location-specific personal data
- ✅ Birthdates, SSNs, passport numbers
- ✅ API keys, tokens, credentials (plaintext or config)
- ✅ Passwords or password-like secrets
- ✅ Private encryption keys
- ✅ Unmasked GitHub tokens or auth headers
- ✅ Database connection strings with credentials
- ✅ Hardcoded usernames/passwords in code

**Not reported (by design):**
- ❌ Proprietary code logic
- ❌ Public organizational contact info
- ❌ Synthetic test fixtures (if clearly documented)
- ❌ Generic location names
- ❌ System account names (noreply@, bot@)
- ❌ Architecture documentation

---

## Skill Dependencies

- **Agent Pool:** 4 parallel agents (Data, Git, Code, SPA)
- **Tools:** Bash, Read, Grep, file inspection
- **Model:** Haiku 4.5 (cost-optimized for scanning tasks)
- **Runtime:** ~2–5 minutes for full audit (depends on repo size)

---

## Output Example

```
# PII Audit Report — MyProject

**Date:** 2026-05-25
**Scope:** Full audit
**Overall Risk:** MINIMAL ✓

## Executive Summary
| Category | Status | Risk Level |
|----------|--------|-----------|
| Data Files | ✓ Clean | MINIMAL |
| Git History | ✓ Clean | MINIMAL |
| Source Code | ✓ Clean | MINIMAL |
| SPA/Frontend | ✓ Clean | MINIMAL |

## DATA FILES
✓ No PII found

## git history trawler
✓ No credentials detected in history

## SOURCE CODE
✓ No hardcoded secrets

## SPA PII
✓ No frontend exposure

## Recommendations
...

## Appendix: Files Referenced
| Filename | Full Path |
|----------|-----------|
...
```

---

## Skill Covenant — Continuous Improvement

This skill carries the **self-improvement covenant**:
- Every PII pattern missed → added to agent instructions
- Every false positive → added to exclusion rules
- Every remediation technique → documented in `REMEDIATION.md`
- Every user finding → folded back into skill definition

Submit feedback by opening an issue on the marketplace repository, or surface it to the user.

---

## Further Reading

- [`references/PII-DEFINITION.md`](references/PII-DEFINITION.md) — Comprehensive taxonomy of what counts as PII
- [`references/AGENT-INSTRUCTIONS.md`](references/AGENT-INSTRUCTIONS.md) — Detailed parallel agent scan methodology
- [`references/COMPLIANCE-NOTES.md`](references/COMPLIANCE-NOTES.md) — GDPR, CCPA, privacy law implications
- [`references/REMEDIATION.md`](references/REMEDIATION.md) — Fix strategies for common exposures
