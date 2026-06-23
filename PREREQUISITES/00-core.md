# 00 — Core baseline (shared by all plugins)

The marketplace runs on Claude Code itself; these are the host tools the plugins assume in nearly
every workflow. Validated on **Debian 13 (trixie)**.

| Tool | Tier | Probe | Why | Install (Debian) |
|---|---|---|---|---|
| `git` | required | `git --version` | All plugins read git history / commit. | `apt install git` |
| `bash` ≥ 5 | required | `bash --version` | Every `-check` and build script is bash. | (preinstalled) |
| `jq` | recommended | `jq --version` | JSON parsing in scripts and checks. | `apt install jq` |
| `ripgrep` (`rg`) | recommended | `rg --version` | Fast scanning (security, inspector, searches). | `apt install ripgrep` |
| `node` ≥ 18 (24 validated) | recommended | `node --version` | chrome-devtools MCP, JS/TS toolchains, mermaid-cli. | via [Volta](https://volta.sh) or `apt` |
| `npm` | recommended | `npm --version` | Global installs (LSP, mermaid, playwright). | ships with node |
| `python3` ≥ 3.10 (3.13 validated) | recommended | `python3 --version` | Python handler, several scanners. | `apt install python3` |
| `uv` / `uvx` | recommended | `uv --version` | Fast Python + **ephemeral tool runner** — how we launch the Fetch MCP and Python LSP/scanners without polluting the system. | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `rustc` / `cargo` | recommended | `cargo --version` | Rust handlers, `typst`, several `cargo install` tools. | via [rustup](https://rustup.rs) |
| `curl` | recommended | `curl --version` | Fetching installers / health checks. | `apt install curl` |

Ansible fragment: [`ansible/apt.yml`](ansible/apt.yml) (system packages) and
[`ansible/core-bootstrap.yml`](ansible/core-bootstrap.yml) (Volta / rustup / uv installers).
