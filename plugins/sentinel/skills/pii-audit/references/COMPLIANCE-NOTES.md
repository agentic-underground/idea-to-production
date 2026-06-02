# Compliance Notes — mapping findings to privacy obligations

This reference maps the PII categories the audit detects to the regulatory obligations they
trigger. It is **orientation, not legal advice** — it tells an engineer *why* a finding matters
and *which regime* cares, so the report's recommendations are grounded. When a real obligation
is in play, escalate to counsel.

---

## Finding type → regime → why it matters

| Finding type | GDPR (EU) | CCPA/CPRA (California) | PCI-DSS | HIPAA (US health) |
|---|---|---|---|---|
| Name + contact (email, phone, address) | Personal data (Art. 4) | Personal information | — | PHI if health-linked |
| Government ID (SSN, passport, licence) | Special category risk | Sensitive PI | — | Identifier |
| Financial / card numbers | Personal data | Sensitive PI | **In scope — primary** | — |
| Health / biometric data | **Special category (Art. 9)** | Sensitive PI | — | **PHI — core** |
| Credentials / API keys / tokens | Security-of-processing (Art. 32) | Reasonable security duty | Access-control failure | Access-control failure |
| Location / precise geolocation | Personal data | Sensitive PI | — | — |
| Online identifiers (IP, device, cookie IDs) | Personal data | Personal information | — | — |

---

## What each regime obligates (the short version)

- **GDPR** — lawful basis required for processing; data minimisation; breach notification within
  **72 hours** of awareness; data-subject rights (access, erasure, portability). A credential or
  personal-data leak in a public repo can constitute a *personal data breach* under Art. 4(12).
- **CCPA/CPRA** — disclosure and deletion rights; a duty to maintain *reasonable security*. A
  leaked dataset of California residents' PI can trigger statutory damages per consumer.
- **PCI-DSS** — cardholder data must never be stored in source, logs, or history in the clear.
  A card number or full track data in a repo is a direct control failure.
- **HIPAA** — PHI (health data tied to an identifiable person) demands access controls and audit
  trails; exposure is a reportable breach.

---

## Severity, reframed through compliance

The audit's risk levels (CRITICAL/HIGH/MEDIUM/LOW/MINIMAL) gain a compliance lens:

| Audit risk | Compliance reading |
|---|---|
| **CRITICAL** | Active credential or special-category data exposed → likely *reportable breach*; rotate + assess notification duty now. |
| **HIGH** | Real personal data of identifiable individuals → data-subject rights and minimisation engaged; remove before any release. |
| **MEDIUM** | Context-dependent (test vs prod, old vs recent) → confirm provenance before deciding. |
| **LOW** | Synthetic/placeholder → document to evidence diligence; no obligation if genuinely synthetic. |
| **MINIMAL** | Clean → record the audit as evidence of reasonable security practice. |

---

## The audit-as-evidence principle

A clean, dated, scoped `PII-REPORT.md` (and `SECURITY-REPORT.md`) is itself useful: under GDPR
Art. 32 and CCPA's reasonable-security duty, demonstrable, repeatable scanning is evidence of
diligence. Keep reports in-repo and re-run on every release.

---

## Cross-border and data-residency flags

When findings include real personal data, note in the report:
- **Whose** data (jurisdiction of the data subjects, if inferable) — determines which regime.
- **Where** it would flow if shipped (public repo = global exposure; treat as worst-case).

Both feed the recommendation: a leak of EU residents' data in a public repo is, by default, a
GDPR breach scenario regardless of where the company sits.

---

## Self-improvement

Every new regulation encountered, or every finding type not covered above, is added to this
table. The audit's job is to *surface and classify*; this reference keeps the classification
honest and current. See `REMEDIATION.md` for how to fix each exposure type.
