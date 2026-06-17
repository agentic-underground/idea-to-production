# PII Definition & Taxonomy

This document defines what counts as Personally Identifiable Information (PII) for the purposes of the `scan-for-pii` skill. Use this taxonomy when training, reviewing, or improving the audit agents.

---

## Core PII Categories

### 1. Personal Identity

**Includes:**
- Real names of individuals (first + last, or full legal name)
- Nicknames or aliases that identify specific people
- Names linked to roles, assignments, or positions
- Maiden names, former names, name changes

**Excludes:**
- Generic placeholder names (John Doe, Test User, Admin)
- Synthetic test fixture names clearly marked as fake
- Public figures' names in published articles
- Generic pseudonyms without identifying context

**Examples (PII):**
```
- "Sarah Chen is the project lead"
- "volunteer_name: Hugo Harris"
- "email_to: 95787+whatbirdisthat@users.noreply.github.com"  # Contains owner's name
```

**Examples (Not PII):**
```
- "TestUser123"
- "synthetic_volunteer_name: Alice Johnson" (in test fixtures)
- "generic_admin_name: Admin"
```

---

### 2. Contact Information

**Includes:**
- Email addresses (personal, work, organizational)
- Phone numbers (all formats: 555-1234, +1(555)123-4567, etc.)
- Mailing addresses (street, city, state, postal code)
- SMS numbers, messaging handles (Signal, WhatsApp, etc.)
- Social media handles linked to real names

**Excludes:**
- Public organizational email addresses (press@company.com, support@)
- Masked/noreply addresses (noreply@github.com, user+bot@domain)
- Generic placeholder contact info in comments

**Examples (PII):**
```
- Email: "jane.smith@gmail.com"
- Phone: "555-123-4567"
- Address: "123 Maple Street, Boston MA 02101"
- Social: "@sarah_chen_actual" (if linked to real person)
```

**Examples (Not PII):**
```
- Email: "support@company.com" (organizational)
- Email: "95787+whatbirdisthat@users.noreply.github.com" (masked)
- Phone: "555-1234" (generic placeholder)
```

---

### 3. Government & Official Identifiers

**Includes:**
- Social Security Numbers (SSN)
- Driver's license numbers
- Passport numbers
- Tax ID numbers
- State ID numbers
- National ID numbers
- Vehicle identification numbers (VINs) when linked to person

**Excludes:**
- De-identified ID numbers
- Test/placeholder IDs (000-00-0000)
- Public record references (published case numbers, arrest records)

**Examples (PII):**
```
- SSN: "123-45-6789"
- Passport: "N12345678"
- Driver's License: "D1234567"
```

---

### 4. Financial Information

**Includes:**
- Bank account numbers
- Routing numbers
- Credit card numbers (full or partial)
- Credit card expiry dates + CVV
- Financial account numbers
- Tax return information
- Salary or compensation data
- Stock portfolio information
- Cryptocurrency wallet addresses (with known owner)

**Excludes:**
- Public stock prices or market data
- General compensation range guides
- Test card numbers (4111111111111111)

**Examples (PII):**
```
- "acct_number: 912345678901"
- "card: 4532-1111-2222-3333"
- "cvv: 123"
- "salary_2025: $85000"
```

---

### 5. Biometric & Health Information

**Includes:**
- Fingerprints, iris scans, facial recognition data
- DNA or genetic information
- Medical conditions or diagnoses
- Medication names or prescriptions
- Health insurance information
- Fertility or pregnancy data
- Mental health records
- Vaccination records (with personal identifiers)

**Excludes:**
- Aggregate health statistics
- General health information without person linkage

**Examples (PII):**
```
- "fingerprint_id: [binary data]"
- "diagnosis: Type 2 Diabetes"
- "insurance_id: AZH123456789"
```

---

### 6. Authentication Credentials

**Includes:**
- Passwords (in any form)
- Password hashes (if deterministic or weak)
- API keys and tokens
- OAuth tokens, refresh tokens, access tokens
- Session tokens and cookies
- SSH private keys, PGP keys, GPG keys
- Encryption keys (symmetric or asymmetric)
- Database credentials (username:password)
- AWS access keys, cloud provider tokens
- Authentication headers (Bearer tokens)
- Temporary/one-time passwords

**Excludes:**
- Public API endpoints (no auth)
- Documentation of auth flow (generic, no real credentials)
- Encrypted/redacted credentials in logs

**Examples (PII):**
```
- "password: MySecureP@ss123"
- "api_key: sk-abc123def456ghi789"
- "DATABASE_URL: postgres://user:password@localhost/db"
- "-----BEGIN PRIVATE KEY-----\n..."
- "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

---

### 7. Temporal Personal Data

**Includes:**
- Birthdates and ages (if linkable to person)
- Anniversary dates, personal event dates
- Medical appointment dates
- Court appearance dates
- Prison release dates
- Divorce dates or other life events

**Excludes:**
- Generic dates without person context
- Historical dates (1776, 1945)

**Examples (PII):**
```
- "dob: 1985-03-14"
- "release_date: 2026-08-22"
- "next_appointment: 2026-06-15"
```

---

### 8. Behavioral & Preference Data

**Includes:**
- Browsing history (if user-identified)
- Purchase history with personal identifiers
- Location tracking data
- Communication logs (emails, messages, chat)
- Job preferences or restrictions
- Availability constraints
- Medical appointment history
- Counseling or therapy notes

**Excludes:**
- Aggregate usage statistics
- De-identified analytics

**Examples (PII):**
```
- "browsing_history: [list of URLs visited by user ID]"
- "preferred_job: Umpire, avoid: Timekeeper"
- "availability: Sundays only"
```

---

### 9. Relationship & Membership Data

**Includes:**
- Family relationships (parent, spouse, children)
- Organizational membership (clubs, unions, political parties)
- Religious affiliation
- Educational institution and enrollment records
- Employee records (department, tenure, performance)
- Criminal history or arrest records

**Excludes:**
- Public organizational directories
- Published employee rosters

**Examples (PII):**
```
- "spouse: David Chen"
- "children: 2 (ages 5, 8)"
- "religious_affiliation: Buddhist"
- "arrest_record: 2015 misdemeanor shoplifting"
```

---

### 10. Digital & Service Identifiers

**Includes:**
- Usernames (if unique or personally identifying)
- Email addresses (personal)
- Phone numbers (cell, home, work)
- IP addresses (residential, if traceable)
- Device identifiers (IMEI, MAC addresses)
- Cryptocurrency wallet addresses (known owner)
- Social media handles with real names
- GitHub usernames linked to real names

**Excludes:**
- Generic username placeholders (user123)
- Masked identifiers
- Aggregate traffic data

**Examples (PII):**
```
- "username: sarah.chen.2024"
- "github_handle: SarahChen" (linked to real person)
- "wallet_address: 0x742d35Cc6634C0532925a3b844Bc2e7595f..." (known owner)
```

---

## Context-Dependent Categories

Some data is PII only in certain contexts:

### Names in Context

| Data | Context | PII? |
|------|---------|------|
| "John Smith" | Alone | No (too generic) |
| "John Smith" | With job title + company | **Yes** |
| "John Smith" | Test fixture (marked synthetic) | No |
| "john_smith_dev" | Test/dev username | No |

### Addresses

| Data | Context | PII? |
|------|---------|------|
| "Boston, MA" | City only | No |
| "123 Oak St, Boston MA 02101" | Full address | **Yes** |
| "Fenway Park, Boston" | Public venue | No |

### Emails

| Data | Context | PII? |
|------|---------|------|
| "support@company.com" | Public org email | No |
| "jane.doe@company.com" | Personal work email | **Yes** |
| "jane.doe@gmail.com" | Personal email | **Yes** |
| "noreply@github.com" | Masked system address | No |

---

## Data That Looks Like PII But Isn't

**Test fixtures:**
```python
# Clearly synthetic — OK
VOLUNTEERS = [
    {"name": "Hugo Harris", "jumper": 1},
    {"name": "Kaiden Height", "jumper": 2},
]
```

**Generic placeholders:**
```
// Not PII — clearly placeholder
const USER_NAME = "User123";
const ADMIN_EMAIL = "admin@example.com";
```

**Published public information:**
```
// OK — from public repo/article
Authors: Sarah Chen, David Lee, Natasha Rodriguez
```

**Aggregate/anonymized data:**
```
// OK — no individual identifiers
"Total users: 1,543"
"Average age group: 25-34"
```

---

## Decision Tree: Is This PII?

```
Is this information about a specific, identifiable person?
├─ YES: Does it reveal something personal or sensitive?
│   ├─ YES: Is it explicitly a test fixture / marked synthetic?
│   │   ├─ YES: Not PII (in that context)
│   │   └─ NO: PII ✓
│   └─ NO: Is it publicly available / organizational info?
│       ├─ YES: Likely not PII
│       └─ NO: PII ✓
└─ NO: Not PII
```

---

## Examples by Severity

### 🔴 CRITICAL (Stop. Remediate immediately.)

```
- password: "sup3rS3cret99!"
- api_key: "sk_live_aB1cD2eF3gH4iJ5kL6mN7oPqRs"
- ssn: "123-45-6789"
- credit_card: "4532-1234-5678-9012"
- private_key: "-----BEGIN PRIVATE KEY-----\n..."
- Database URL: "postgres://admin:p@ssw0rd@prod.db.com/users"
```

### 🟠 HIGH (Fix before shipping)

```
- Real person's email: "sarah.chen@company.com"
- Real person's phone: "555-123-4567"
- Real home address: "123 Oak St, Boston MA 02101"
- Employee record: "Name: David Lee, Salary: $95,000, Dept: Engineering"
- Medical info: "Patient name: Jane Smith, Diagnosis: Type 2 Diabetes"
```

### 🟡 MEDIUM (Review & decide)

```
- Name with role: "Project lead: Sarah Chen"
- Volunteer assignment: "volunteer_name: Hugo Harris, job: Umpire Escort"
- Ambiguous: Is this synthetic test data or real?
```

### 🟢 LOW (Document & monitor)

```
- Synthetic fixture: "TestUser_Name: John Doe"
- Generic placeholder: "default_admin: admin"
- Public org info: "Support email: support@company.com"
```

---

## Skill Application

The `scan-for-pii` skill uses this taxonomy to:

1. **Train agents** — Provide comprehensive definition so agents recognize PII
2. **Classify findings** — Rate severity from CRITICAL to LOW
3. **Reduce false positives** — Exclude known-good patterns (org emails, test data)
4. **Improve over time** — Add patterns the skill misses to this document

When the skill finds something ambiguous, it reports it with the context so humans can decide.

---

## Updates & Feedback

This taxonomy evolves as privacy laws change and PII patterns emerge. Report new patterns via:
- inter-agent messaging artefacts (e.g. a project AGENTS or HELLO registry)
- Project issues
- PR comments in ${CLAUDE_PLUGIN_ROOT}/skills/scan-for-pii/
