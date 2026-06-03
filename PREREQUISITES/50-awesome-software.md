# 50 — Software I found that is awesome

> **For the Ansible provisioning agent.** A curated, opinionated list of tooling that makes
> Claude Code + this marketplace genuinely high-powered. Two sections: (A) already present on the
> reference machine and worth **pinning** so every box matches, and (B) **high-value additions**
> currently absent. Reference machine: **Debian 13 (trixie)**, surveyed 2026-06-03.

## A. Already installed — pin these in the playbook

| Tool | Version seen | Why it's awesome | Install channel |
|---|---|---|---|
| `rust-analyzer` | (cargo bin) | Best-in-class Rust LSP → semantic nav + live diagnostics for agents. | `rustup component add rust-analyzer` |
| `dx` (Dioxus CLI) | — | Drives the Rust/WASM webapp stack. | `cargo install dioxus-cli --locked` |
| `cargo-zigbuild` + `zig` | zig 0.13 | glibc-correct cross-builds for Vercel's Rust runtime. | `cargo install cargo-zigbuild` + zig release |
| `typst` | 0.14.2 | Fast, no-TeX typesetting — pressroom's default engine. | `cargo install typst-cli` |
| `uv` / `uvx` | 0.11.17 | Fast Python + **ephemeral tool runner**; launches the Semgrep MCP & Python tooling cleanly. | astral install script |
| `node` (Volta) | 24.16 | Playwright MCP, JS/TS toolchains, mermaid-cli. | Volta |
| `dotnet` | 10.0.203 | .NET stack availability. | Microsoft apt feed |
| `rustc`/`cargo` | 1.96 | Rust toolchain. | rustup |
| `ripgrep` | 15.1 | Fast search everywhere. | apt |
| `jq` | 1.7 | JSON in scripts/checks. | apt |
| `gs` (Ghostscript) | — | PDF optimise/merge for pressroom. | apt |
| `pdfinfo` (poppler) | — | PDF verification in build-pdf.sh. | apt (`poppler-utils`) |
| `libreoffice`/`soffice` | — | docx/odt/pptx ⇄ PDF conversion. | apt |
| `firefox` | — | a browser (note: Chromium not present — add for Playwright). | apt |

## B. High-value additions — install these next

### Feedback & code intelligence
- **`@playwright/mcp` + Chromium** — live browser feedback for web handlers. `npm i -g @playwright/mcp playwright && npx playwright install --with-deps chromium`
- **`typescript-language-server` + `typescript`**, **`pyright`** — LSP for JS/TS and Python. `npm i -g …`
- **`gopls`** — Go LSP, if Go is used. `go install golang.org/x/tools/gopls@latest`

### Debuggers
- **`lldb`** (gives `rust-lldb`), **`gdb`** — `apt install lldb gdb`
- **`debugpy`** — `uv tool install debugpy`

### Security (SENTINEL)
- **`osv-scanner`** (Google OSV, all ecosystems), **`gitleaks`** (secrets), **`semgrep`** (SAST), **`cargo-audit`**, **`pip-audit`**, **`govulncheck`**, optionally **`trivy`**/**`grype`**+**`syft`**, **`trufflehog`**.

### Publishing (PRESSROOM)
- **TeX Live** set (`texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended`) — enables the LaTeX engine.
- **`graphviz`** (`dot`), **`@mermaid-js/mermaid-cli`** (`mmdc`), **`pandoc`**, **`librsvg2-bin`** (`rsvg-convert`), **`qpdf`**, **`imagemagick`**.
- A **Libertinus** or **TeX Gyre** font family for the exact Typst look.

### Developer ergonomics (quality-of-life, absent on the box)
- **`gh`** (GitHub CLI) — PR/issue automation. `apt install gh` (GitHub apt repo)
- **`fd`** (fast find), **`bat`** (better cat), **`fzf`** (fuzzy finder), **`delta`** (git diffs), **`httpie`** — `apt`/`cargo`.
- **`pnpm`** — JS monorepos (Volta reports it missing even though node/npm exist).
- **`cargo-nextest`** — faster Rust test runs.

> **Note for the Ansible agent:** the paste-ready task fragments grouped by installer
> (`apt`, `cargo`, `npm`, `uv`, `go`, standalone binaries) are in [`ansible/`](ansible/). They are
> idempotent and tagged so you can include only the groups you want.
