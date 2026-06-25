# templates/ — Canonical, Parameterized Files

> **Purpose:** The zero-drift source. Each file here is the **exact shipped `forge` file**
> with names replaced by placeholders and every guardrail already applied. Copy them; do
> not hand-author equivalents from memory.

> **IMPORTANT — THE ONLY WAY:** When scaffolding a new project, copy these templates and do
> a single, consistent placeholder substitution. Reinventing any of these files
> reintroduces the trial-and-error documented in [`../06-guardrails-and-antipatterns.md`](../06-guardrails-and-antipatterns.md).

---

## Placeholder legend

| Placeholder | Meaning | Example (`forge`) |
|---|---|---|
| `{{project}}` | project name = root package name = Vercel project name | `forge` |
| `{{crate_prefix}}` | crate-name prefix (→ `<prefix>-core`, `-ui`, `-web`, `-server`, `-mobile`) | `forge` |
| `{{fn_name}}` | first serverless function name (and its `[[bin]]` name) | `greet` |
| `{{vercel_project}}` | linked Vercel project slug | `whatbirdisthats-projects/forge` |

> **GUARDRAIL:** Substitute **all** placeholders consistently. The crate names in the
> manifests, the `--package` flag in `vercel.json`, the `[[bin]]` path in the root
> `Cargo.toml`, and the `dx bundle` output path must all agree, or the build fails.

---

## File-to-destination map

| Template | Destination | Governing doc |
|---|---|---|
| `Cargo.toml.root.tmpl` | `Cargo.toml` (repo root) | `01 §3`, `04 §2` |
| `rust-toolchain.toml.tmpl` | `rust-toolchain.toml` | `03 §3` |
| `vercel.json.tmpl` | `vercel.json` | `04 §4` |
| `cargo-config.toml.tmpl` | `.cargo/config.toml` | `04 §5` (keep `[build]`!) |
| `clippy.toml.tmpl` | `clippy.toml` | `07 §1` |
| `rustfmt.toml.tmpl` | `rustfmt.toml` | — |
| `Dioxus.toml.tmpl` | `Dioxus.toml` | — |
| `CLAUDE.md.tmpl` | `CLAUDE.md` | `07 §3` |
| `ci.yml.tmpl` | `.github/workflows/ci.yml` | `07 §1` |
| `api-function.rs.tmpl` | `api/{{fn_name}}.rs` | `04 §3` |
| `crate-core-lib.rs.tmpl` | `crates/core/src/lib.rs` | `02 §3`, `07 §2` |
| `crate-server-lib.rs.tmpl` | `crates/server/src/lib.rs` | `01`, `07 §2` |
| `crate-ui-component.rs.tmpl` | `crates/ui/src/<component>.rs` (+ `lib.rs` re-export) | `01 §4` |
| `crate-web-main.rs.tmpl` | `crates/web/src/main.rs` | `01` |
| `Cargo.toml.crate.tmpl` | each `crates/*/Cargo.toml` (see the file's sections) | `01 §4` |
| `xtask-main.rs.tmpl` | `xtask/src/main.rs` | `03 §2` |

The optional native mobile crate (`crates/mobile`) mirrors `crates/web` exactly, swapping
the `dioxus` renderer feature `web` → `mobile`. It is an optional extension station.

---

## After substitution

1. `cargo xtask setup` then `cargo xtask check` (`03`).
2. `cargo xtask ci` must be green before any deploy (`07 §1`).
3. Follow [`../08-bootstrap-runbook.md`](../08-bootstrap-runbook.md) for the full line.
