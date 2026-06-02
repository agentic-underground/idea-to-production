# PII Remediation Strategies

This document provides step-by-step guidance for fixing common PII exposure issues found by the `pii-audit` skill.

---

## Remediation Priority Matrix

| Risk Level | Timeline | Example | Action |
|-----------|----------|---------|--------|
| **CRITICAL** | Immediate (hours) | API key in production code | Rotate credential, clean history, notify security |
| **HIGH** | Urgent (1-2 days) | Real person's email in code | Remove, notify person if applicable, rotate if auth-related |
| **MEDIUM** | Soon (1 week) | Real name with role in comment | Remove identifier, update comment |
| **LOW** | Planned (next sprint) | Test fixture names | Document as synthetic, add lint rules |

---

## Common Findings & Fixes

### 1. API Key or Token in Code

**Example:**
```python
api_key = "sk_live_51IB2Z2ABCD123XYZ456"
requests.get(f"https://api.stripe.com/...", headers={"Authorization": f"Bearer {api_key}"})
```

**Risk:** CRITICAL — Active credentials exposed.

**Fix:**

1. **Rotate the credential immediately:**
   ```bash
   # In your service provider (Stripe, AWS, etc.)
   # Revoke the exposed key
   # Generate a new key
   # Update all systems using it
   ```

2. **Move to environment variable:**
   ```python
   import os
   api_key = os.getenv("STRIPE_API_KEY")
   requests.get(f"https://api.stripe.com/...", headers={"Authorization": f"Bearer {api_key}"})
   ```

3. **Add .env to .gitignore (if not already):**
   ```bash
   echo ".env" >> .gitignore
   echo ".env.local" >> .gitignore
   echo ".env.*.local" >> .gitignore
   ```

4. **Create .env.example with placeholder:**
   ```bash
   # .env.example (commit this)
   STRIPE_API_KEY=sk_test_PLACEHOLDER
   ```

5. **Clean git history** (⚠️ destructive — only if key was critical):
   ```bash
   # Option A: Rewrite history (if repo is private)
   git filter-branch --tree-filter 'sed -i "s/sk_live_51IB2Z2ABCD123XYZ456/sk_test_PLACEHOLDER/g" *' -- --all
   git push origin --force-with-lease [branch]
   
   # Option B: Use git-filter-repo (preferred)
   git filter-repo --replace-text <(echo "sk_live_51IB2Z2ABCD123XYZ456==>sk_test_PLACEHOLDER")
   
   # Option C: Document and monitor (if history rewrite not possible)
   # Leave it but rotate the credential immediately
   ```

6. **Commit the fix:**
   ```bash
   git add -A
   git commit -m "fix(security): move API key to environment variable"
   ```

---

### 2. Database Credentials in Connection String

**Example:**
```python
DATABASE_URL = "postgres://admin:MyPassword123@prod.db.com:5432/myapp"
```

**Risk:** CRITICAL — Database access compromised.

**Fix:**

1. **Rotate database password immediately:**
   ```bash
   # In your database management console
   ALTER USER admin PASSWORD 'NewSecurePassword123!@#';
   ```

2. **Move connection string to environment variable:**
   ```python
   import os
   from urllib.parse import urlparse
   
   database_url = os.getenv("DATABASE_URL")
   # or construct from components:
   db_host = os.getenv("DB_HOST")
   db_user = os.getenv("DB_USER")
   db_pass = os.getenv("DB_PASSWORD")
   database_url = f"postgres://{db_user}:{db_pass}@{db_host}:5432/myapp"
   ```

3. **Update .env and .gitignore:**
   ```bash
   # .env (do not commit)
   DATABASE_URL=postgres://admin:NewPassword@prod.db.com:5432/myapp
   
   # .gitignore
   .env
   .env.local
   ```

4. **Create .env.example:**
   ```bash
   # .env.example (commit this)
   DATABASE_URL=postgres://user:pass@localhost:5432/myapp
   ```

5. **Clean git history:**
   ```bash
   # Rotate password first, then clean history
   git filter-repo --replace-text <(echo "MyPassword123==>ROTATED")
   ```

6. **Commit:**
   ```bash
   git add -A
   git commit -m "fix(security): move database credentials to environment"
   ```

---

### 3. Personal Email in Code/Comments

**Example:**
```javascript
// Email Sarah Chen at sarah.chen@company.com to request API access
// TODO: john.doe@gmail.com — test user, remove before production
```

**Risk:** HIGH — Privacy violation, person's email exposed.

**Fix:**

1. **Remove the email:**
   ```javascript
   // Email project lead to request API access
   // TODO: Remove test user before production
   ```

2. **If it's a reference to a real process, generalize:**
   ```javascript
   // Email the project owner (see MAINTAINERS.md)
   ```

3. **Update MAINTAINERS.md** (instead of hardcoding in comments):
   ```markdown
   # Maintainers
   
   - Project Lead: [Name] — see PEOPLE.md
   - Security: security@company.com
   ```

4. **Notify the person (if their personal email is exposed):**
   - Send a direct message
   - Apologize for the exposure
   - Assure them the email is being removed
   - Suggest they monitor for unsolicited contact

5. **Commit:**
   ```bash
   git add -A
   git commit -m "fix(privacy): remove personal email addresses from code"
   ```

---

### 4. Real Names in Test Data

**Example:**
```python
# test/fixtures.py
VOLUNTEERS = [
    {"name": "Sarah Chen", "email": "sarah.chen@company.com", "jumper": 1},
    {"name": "David Lee", "email": "david.lee@company.com", "jumper": 2},
]
```

**Risk:** MEDIUM/HIGH — If these are real people, privacy violation.

**Fix:**

1. **Replace with clearly synthetic names:**
   ```python
   # test/fixtures.py
   VOLUNTEERS = [
       {"name": "TestUser1", "email": "test1@example.com", "jumper": 1},
       {"name": "TestUser2", "email": "test2@example.com", "jumper": 2},
   ]
   ```

2. **OR use name generation library:**
   ```python
   from faker import Faker
   fake = Faker()
   
   VOLUNTEERS = [
       {"name": fake.name(), "email": fake.email(), "jumper": i}
       for i in range(1, 11)
   ]
   ```

3. **Document as synthetic:**
   ```python
   """
   Synthetic test fixtures for volunteer scheduling algorithm.
   Names and emails are randomly generated and do not represent real people.
   """
   ```

4. **Commit:**
   ```bash
   git add -A
   git commit -m "fix(test): replace real names with synthetic test data"
   ```

---

### 5. Credentials in Git History

**Example:** Audit finds `password = "OldPassword123"` in a commit from 6 months ago.

**Risk:** MEDIUM — Likely rotated, but verify.

**Fix:**

1. **Check if the password is still in use:**
   ```bash
   # If you can easily verify it's rotated, proceed
   # If unsure, rotate it immediately to be safe
   ```

2. **Option A: Clean history if repo is private:**
   ```bash
   git filter-repo --replace-text <(echo "OldPassword123==>ROTATED")
   git push origin --force-with-lease main  # ⚠️ destructive
   ```

3. **Option B: Document as historical:**
   If cleaning history is not feasible, add a note:
   ```markdown
   # Security Note
   
   This repository contains historical commits with rotated credentials
   (see commit abc1234). These credentials have been revoked and are no longer valid.
   ```

4. **Verify rotation:**
   ```bash
   # Search for any active instances of the old password
   git grep "OldPassword123" --  # should return nothing
   ```

5. **Commit (if changes made):**
   ```bash
   git commit -m "docs(security): note historical credential exposure"
   ```

---

### 6. PII in Test Fixtures (Synthetic)

**Example:**
```python
# conftest.py — clearly marked as synthetic
@pytest.fixture
def volunteer():
    return {"name": "Hugo Harris", "jumper": 1}
```

**Risk:** LOW — If clearly synthetic, acceptable for testing.

**Fix:**

1. **Ensure it's clearly documented:**
   ```python
   """Synthetic test fixtures for roster scheduling algorithm."""
   
   @pytest.fixture
   def volunteer():
       """Synthetic volunteer for testing. Not a real person."""
       return {"name": "Hugo Harris", "jumper": 1}
   ```

2. **Consider Faker for variety:**
   ```python
   from faker import Faker
   fake = Faker()
   
   @pytest.fixture
   def volunteer():
       """Synthetic volunteer using Faker library."""
       return {"name": fake.name(), "jumper": random.randint(1, 50)}
   ```

3. **Add linting rule to prevent real data:**
   ```python
   # conftest.py or pytest.ini
   # Add comment to code review guidelines:
   # "Test fixtures must use Faker or clearly synthetic names"
   ```

4. **No commit needed** if already clearly marked.

---

### 7. Configuration File with Secrets

**Example:**
```yaml
# config/production.yaml (committed by mistake)
database:
  host: prod.db.com
  username: admin
  password: SecretPass123!
  
api_keys:
  stripe: sk_live_abc123
  sendgrid: SG.abc123
```

**Risk:** CRITICAL.

**Fix:**

1. **Rotate all exposed credentials:**
   ```bash
   # Stripe, SendGrid, etc. dashboard
   # Revoke exposed keys
   # Generate new keys
   # Update systems using them
   ```

2. **Split into code + config:**
   ```yaml
   # config/production.yaml (commit this — no secrets)
   database:
     host: ${DB_HOST}
     username: ${DB_USER}
     password: ${DB_PASSWORD}
   
   api_keys:
     stripe: ${STRIPE_API_KEY}
     sendgrid: ${SENDGRID_API_KEY}
   ```

3. **Use environment variables:**
   ```python
   import os
   from yaml import safe_load
   
   with open("config/production.yaml") as f:
       config = safe_load(f)
   
   # Substitute env vars
   config["database"]["password"] = os.getenv("DB_PASSWORD")
   config["api_keys"]["stripe"] = os.getenv("STRIPE_API_KEY")
   ```

4. **Add to .gitignore:**
   ```bash
   config/*.local.yaml
   config/**/secrets.yaml
   .env
   .env.local
   ```

5. **Clean history:**
   ```bash
   git filter-repo --replace-text <(echo "SecretPass123!==>ROTATED")
   git push origin --force-with-lease
   ```

6. **Commit:**
   ```bash
   git add -A
   git commit -m "fix(security): externalize secrets to environment variables"
   ```

---

## General Prevention Strategies

### 1. Pre-Commit Hook

Prevent credentials from being committed:

```bash
# .git/hooks/pre-commit
#!/bin/bash

# Check for common patterns
if git diff --cached | grep -iE "password|api_key|secret|token|ssh-rsa|private.*key"; then
    echo "ERROR: Potential secret detected in staged changes!"
    echo "Review the diff and remove sensitive data before committing."
    exit 1
fi

exit 0
```

Install:
```bash
chmod +x .git/hooks/pre-commit
```

### 2. Secret Scanner Tool

Use automated tools:

```bash
# Detect secrets in code
pip install detect-secrets
detect-secrets scan --baseline .secrets.baseline

# Git hook
pip install pre-commit
# Add to .pre-commit-config.yaml:
# - repo: https://github.com/Yelp/detect-secrets
#   rev: v1.4.0
#   hooks:
#     - id: detect-secrets
```

### 3. Environment Variable Best Practices

```python
# ✓ Good
import os
api_key = os.getenv("API_KEY")
if not api_key:
    raise ValueError("API_KEY environment variable not set")

# ✗ Bad
api_key = "hardcoded_key_123"  # Never do this
```

### 4. Secrets Management Tools

For production:
- **AWS Secrets Manager** — rotate, audit, access control
- **HashiCorp Vault** — centralized, encryption
- **Azure Key Vault** — cloud-native
- **1Password / LastPass** — team credential sharing
- **Sealed Secrets** (Kubernetes) — GitOps-friendly

---

## Checklist: After Finding & Fixing PII

- [ ] Credential rotated immediately
- [ ] Code updated to use environment variables
- [ ] `.env` added to `.gitignore`
- [ ] `.env.example` created with placeholders
- [ ] Git history cleaned (if critical)
- [ ] Affected party notified (if personal data)
- [ ] Commit message documents the fix
- [ ] New credentials deployed to all systems
- [ ] Old credentials confirmed deactivated
- [ ] Pre-commit hooks / linting added to prevent recurrence
- [ ] Team educated on secure practices
- [ ] Re-run PII audit to confirm fix

---

## When to Escalate

Contact security team / leadership if:
- Multiple credentials exposed
- Active/recent exposure (last week)
- Real person's PII (address, SSN, etc.)
- Financial data exposed
- Customer/user data leaked
- Regulatory compliance impact (GDPR, CCPA, etc.)
- Unsure about severity

---

## Resources

- [OWASP: Sensitive Data Exposure](https://owasp.org/www-project-top-ten/)
- [GitHub: Removing Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [GitLab: Remove Sensitive Data](https://docs.gitlab.com/ee/user/project/repository/push_rules/push_rules.html)
- [Detect Secrets Library](https://github.com/Yelp/detect-secrets)
- [Pre-Commit Framework](https://pre-commit.com/)
