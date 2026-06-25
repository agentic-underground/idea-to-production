# 08 — Bootstrap Runbook

> **Purpose:** The ordered, executable checklist that carries a brand-new project from an
> empty directory to a verified production deployment. **This is the page the handler
> executes.**
>
> **TL;DR:** Decide the placeholders → scaffold from `templates/` → `cargo xtask setup` →
> write the first failing coordinate → implement → `cargo xtask ci` green → user does
> `vercel login`/`link` → prebuilt preview → verify → prod. Each step cites the doc/template
> that governs it.

---

## 0. Decide the placeholders (once)

Choose the values that every template uses. Record them; substitute them everywhere.

| Placeholder | Meaning | Example (`forge`) |
|---|---|---|
| `{{project}}` | project name = root package name = Vercel project name | `forge` |
| `{{crate_prefix}}` | crate-name prefix | `forge` (→ `forge-core`, `forge-ui`, …) |
| `{{fn_name}}` | the first serverless function name | `greet` |
| `{{vercel_project}}` | the linked Vercel project slug | `whatbirdisthats-projects/forge` |

The placeholder legend and file-to-destination map live in
[`templates/README.md`](templates/README.md).

---

## 1. Scaffold the skeleton (from `templates/`)

> **IMPORTANT — THE ONLY WAY:** Copy the templates; do not hand-author these files from
> memory. The templates are the exact shipped `forge` files, parameterized, with every
> guardrail already applied. Hand-authoring reintroduces drift and the `06` saga.

Create this tree (governing doc in parentheses):

```
{{project}}/
├── Cargo.toml              ← templates/Cargo.toml.root.tmpl        (01 §3, 04 §2)
├── Cargo.lock              ← committed after first build
├── rust-toolchain.toml     ← templates/rust-toolchain.toml.tmpl    (03 §3)
├── vercel.json             ← templates/vercel.json.tmpl            (04 §4)
├── clippy.toml             ← templates/clippy.toml.tmpl            (07 §1)
├── rustfmt.toml            ← templates/rustfmt.toml.tmpl
├── Dioxus.toml             ← templates/Dioxus.toml.tmpl
├── CLAUDE.md               ← templates/CLAUDE.md.tmpl              (07 §3)
├── .cargo/
│   └── config.toml         ← templates/cargo-config.toml.tmpl      (04 §5 — keep [build]!)
├── .github/workflows/
│   └── ci.yml              ← templates/ci.yml.tmpl                 (07 §1)
├── api/
│   └── {{fn_name}}.rs      ← templates/api-function.rs.tmpl        (04 §3)
├── crates/
│   ├── core/{Cargo.toml, src/lib.rs}    ← Cargo.toml.crate.tmpl + crate-core-lib.rs.tmpl   (01, 02 §3)
│   ├── server/{Cargo.toml, src/lib.rs}  ← Cargo.toml.crate.tmpl + crate-server-lib.rs.tmpl (01)
│   ├── ui/{Cargo.toml, src/lib.rs, src/<component>.rs} ← Cargo.toml.crate.tmpl + crate-ui-component.rs.tmpl (01 §4)
│   ├── web/{Cargo.toml, src/main.rs}    ← Cargo.toml.crate.tmpl + crate-web-main.rs.tmpl   (01)
│   └── mobile/{Cargo.toml, src/main.rs} ← (optional extension; same shell as web)
└── xtask/{Cargo.toml, src/main.rs}      ← xtask-main.rs.tmpl       (03 §2)
```

Substitute `{{project}}` / `{{crate_prefix}}` / `{{fn_name}}` throughout. Add a
`.gitignore` for `target/`, `dist/`, `public/`, `.vercel/`.

> **GUARDRAIL:** Verify the root `Cargo.toml` is the **hybrid** (`[workspace]` **and**
> `[package]` with the function `[[bin]]`) and that there is **no** `api/Cargo.toml`
> (`01 §3`, `06 B2`). Verify `.cargo/config.toml` has the empty `[build]` table
> (`04 §5`, `06 B4`).

---

## 2. Install the toolchain

```bash
cd {{project}}
cargo xtask setup     # rust + wasm32 + rustfmt/clippy + dx(--locked) + zig + cargo-zigbuild + system libs
cargo xtask check     # verify; must exit 0
```
Governing doc: `03`. If `check` reports anything missing, fix it before proceeding — do not
push forward with a partial toolchain.

---

## 3. Carry the first vertical slice (the "prove the shape" slice)

Follow the stations (`02 §2`). For the first slice, keep the templates' greeting domain (or
swap its contents for your real first behaviour, keeping the shape).

1. **SPEC** — enumerate the `input → expected output` pairs incl. edge cases.
2. **COORDINATES** — write the failing tests in `core` (unit + `proptest`). Run
   `cargo test -p {{crate_prefix}}-core` and confirm they **fail for the right reason**
   (`02 §3`).
3. **IMPLEMENT** — write the minimum in `core` to turn every coordinate green.
4. **STORY** — wire the `server` glue, the `ui` component, and the `api/{{fn_name}}.rs`
   handler that consume the proven core (`04 §3`).
5. **GATE** — `cargo xtask ci` must be fully green (`07 §1`). Never weaken it.

---

## 4. Local dev loop (optional, while iterating)

```bash
cargo xtask serve     # dx serve, hot-reload web app at localhost
```

---

## 5. Connect Vercel (user-driven, one-time)

> **IMPORTANT — THE ONLY WAY:** These are interactive and require the user's account. Ask
> the user to run them (suggest the `! <command>` form). See `03 §4`.

```bash
npm i -g vercel        # Vercel CLI 54.x (Node 18+)
vercel login           # interactive auth — user only
cd {{project}} && vercel link    # → {{vercel_project}}
```
Then have the user confirm the **Rust-runtime capability is enabled** on the Vercel project.

---

## 6. BUILD → DEPLOY → VERIFY (preview first)

```bash
# from {{project}}/ (where vercel.json lives)
vercel build --yes                 # local: WASM site + cross-compiled function
# Confirm the .func signature (04 §6): runtimeLanguage "rust", runtime "executable".
vercel deploy --prebuilt --yes
vercel curl https://<preview>.vercel.app/api/{{fn_name}}?name=Claude   # previews need auth (05 §4)
```

Run the **verification matrix** (`05 §4`) against the preview. When every row passes,
promote to production:

```bash
vercel build --prod --yes
vercel deploy --prebuilt --prod --yes
curl https://<prod-alias>/api/{{fn_name}}?name=Claude   # prod alias is public
```

The slice is **done** only when the verification matrix passes against the **deployed**
URL (`02 §2`, `05 §4`).

---

## 7. Commit & ship

```bash
git add -A
git commit -m "feat({{fn_name}}): first vertical slice — core + ui + web + api, deployed"
# (open a PR; let reviewer + security-auditor pass before merge — 07 §3)
```
Conventional Commits, one concern per commit (`07 §4`).

---

## 8. Done-checklist (the exit certificate for the whole bootstrap)

- [ ] Root `Cargo.toml` is the hybrid manifest; no `api/Cargo.toml` (`01 §3`, `06 B2`)
- [ ] `.cargo/config.toml` has the empty `[build]` table (`04 §5`, `06 B4`)
- [ ] `vercel.json` has the correct `buildCommand` and **no** `functions` block (`04 §4`)
- [ ] `cargo xtask check` exits 0 (`03`)
- [ ] First slice's coordinates were written failing, then turned green (`02 §3`)
- [ ] `cargo xtask ci` is fully green; the gate was never weakened (`07 §1`)
- [ ] `.func` signature shows `runtimeLanguage: "rust"`, `runtime: "executable"` (`04 §6`)
- [ ] Verification matrix passes against the **production** URL (`05 §4`)

When every box is ticked, the line is proven and the project is producing value. Subsequent
features are just more vertical slices carried down the same stations.
