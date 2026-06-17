---
description: Scan for committed credentials and secrets (API keys, tokens, private keys, connection strings) across the tree, git history, and build artefacts.
---

Run the **scan-for-secrets** skill.

Scope from `$ARGUMENTS` (default: `full`): `full` (working tree + git history + build artefacts),
`tree` (working tree only — fast pre-commit), `history` (git history only), or a path.

Detect secrets two ways: tight provider regex families (AWS, GCP, GitHub, Slack, Stripe, JWT,
private-key blocks, connection strings — high confidence) and a high-entropy heuristic for novel
secrets (lower confidence, flagged for human review). Redact every match to ≤4 leading
characters — never print a full secret into the report. Write `SECRET-FINDINGS.md`, or return the
findings section when called by `/scan-all`.
