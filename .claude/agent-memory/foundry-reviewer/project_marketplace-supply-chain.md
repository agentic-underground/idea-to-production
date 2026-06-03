---
name: marketplace-supply-chain
description: Recurring supply-chain risk class in the idea-to-production marketplace — unpinned third-party executables shipped/recommended by plugins
metadata:
  type: project
---

The marketplace repeatedly ships or recommends floating/unpinned third-party code execution. Same root cause across MCP configs and Ansible provisioning fragments.

Instances seen (branch `empower-marketplace`, reviewed 2026-06-03):
- `plugins/foundry/.mcp.json` → `npx -y @playwright/mcp@latest` (unpinned npm)
- `plugins/sentinel/.mcp.json` → `uvx semgrep-mcp` (unpinned PyPI, on the security plugin)
- `PREREQUISITES/ansible/core-bootstrap.yml` → `curl … | sh` for rustup/uv/Volta
- `PREREQUISITES/ansible/binaries.yml` → `osv-scanner` from `releases/latest`, piped `install.sh` for gitleaks/trivy/grype/syft (no checksum)
- `zig` IS correctly pinned (0.13.0) — the model for the others.

**Why:** registry/CDN compromise or malicious publish → arbitrary code as the user; `@latest` also kills reproducibility. Bounded because Ansible fragments are opt-in and docs say "pin in production", but the MCP `.mcp.json` ships in the plugin.

**How to apply:** On any future review touching `.mcp.json` or `PREREQUISITES/ansible/`, flag unpinned `@latest`/bare-package/`releases/latest`/`curl|sh` as a supply-chain finding. Push for the systematic fix (a "pin + checksum every externally-fetched executable" rule) rather than per-site patches — see [[feedback-approval-gate-claim]].

Also watch the approval-gate safety claim in `PREREQUISITES/40-mcp.md` / `live-feedback.md`: it states "does not silently auto-run" as absolute, but is false under `enableAllProjectMcpServers`/pre-approval/`--dangerously-skip-permissions`. Must be qualified.
