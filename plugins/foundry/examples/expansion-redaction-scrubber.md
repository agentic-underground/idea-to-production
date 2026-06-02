# Mode-C Expansion (worked example) — Idea #1: Local-First Redaction & Metadata Scrubber

> Produced by FOUNDER running the §3 EXPANSION PROCEDURE on the market-scan recommendation.
> This is the reference shape for ALL expansions. Hand to `reviewer` with the note:
> "early-iteration expansion — verify internal consistency and QA/CI ready-state before code."

---

## 1 · THESIS & SURFACES

**Thesis.** A tool that strips hidden metadata and truly redacts sensitive content from
documents **entirely on the user's device — nothing is ever uploaded.** The value is
*provable* privacy (verifiable in the browser Network tab) plus heavy parsing/flattening
done locally at native-ish speed. The stack is the moat: this is exactly what Rust/WASM +
local-first does that an upload-based JS+server competitor structurally cannot.

**Surfaces.**
- *Capture:* file drop-zone (images, PDF); redaction-region selection on a rendered page.
- *Display:* before/after preview; a **ScrubReport** (what was found and removed).
- *Navigate:* page thumbnails for multi-page PDFs; tier gate (free vs unlocked).
- *Instrument:* a "0 bytes uploaded" live indicator; per-file processing time readout.
- *API surface:* **none for file data** (deliberate — files never leave the device). Only a
  stateless license-check endpoint, validated client-side where possible.
- *Persistence:* local-first; outputs written only where the user saves them. No server store.
- *Trust boundary:* the file **never crosses the wire.** The only wire traffic is the
  optional license check, which carries no document data. This boundary is the product.

---

## 2 · ARCHITECTURE

```
            forge-core  (scrub engine: parse, detect, strip, flatten — PURE, heavy compute)
              ^      ^
              |      |
          forge-ui   forge-server (license check only — NEVER touches document bytes)
           ^    ^          ^
           |    |          |
      forge-web forge-mobile   api/license.rs (stateless; no file data)
```

| Crate | Responsibility | MUST NOT depend on | Test levels |
|---|---|---|---|
| `forge-core` | parse EXIF/PDF; detect sensitive metadata; strip; flatten redactions | ui, web, mobile, server, any I/O | unit, module, boundary |
| `forge-ui` | drop-zone, preview, region-select, ScrubReport, tier gate | web-sys/native APIs directly | system, STORY |
| `forge-web` | mount App to WASM | core internals | system |
| `forge-mobile` | mount App natively | core internals | system |
| `forge-server` | license validation logic | document data of any kind | unit, module |
| `api/license.rs` | HTTP plumbing for license check | document data of any kind | boundary |

**Heavy-compute core that justifies the stack:** PDF object-graph parsing + true content
flattening (removing the bytes under a redaction box, not drawing a rectangle over them),
and image metadata stripping across formats. This is genuine work, runs locally, needs no
server, and keeps user files private — two of the four stack advantages at once.

**Trust boundaries (explicit):** (1) file→app: in-process only, never the network. (2)
app→license endpoint: the ONLY wire crossing; carries a license key, never document data.

---

## 3 · DOMAIN LEXICON (glossary++)

| term | plain definition | code shape | invariants | owning station | failure modes |
|---|---|---|---|---|---|
| **ScrubJob** | one document queued for scrubbing | `struct ScrubJob{ source: SourceDoc, regions: Vec<Region> }` | source is a recognised type; regions ⊆ page bounds | SLICE | unsupported type; region out of bounds |
| **SourceDoc** | the input file, typed by format | `enum SourceDoc{ Jpeg, Png, Heic, Pdf }` | constructed only from a sniffed/validated header | SLICE | spoofed extension; corrupt header |
| **MetadataTag** | a removable hidden datum | `struct MetadataTag{ kind: TagKind, raw: Bytes }` | listed in the known-removable set | SLICE | unknown vendor tag (report, don't silently keep) |
| **Region** | an area to flatten/remove | `struct Region{ page: u32, rect: Rect }` | rect within page; page < page_count | SLICE/DESIGN | zero-area rect; page overflow |
| **ScrubReport** | what was found & removed | `struct ScrubReport{ removed: Vec<MetadataTag>, flattened: Vec<Region>, residual: Vec<MetadataTag> }` | residual MUST be empty on a successful "clean" claim | HARDEN | residual non-empty but UI claims clean (BLOCKER) |
| **CleanOutput** | the scrubbed file | `struct CleanOutput{ bytes: Bytes }` | contains NONE of the removed tags' bytes | HARDEN | a stripped tag survives in output (security BLOCKER) |
| **Tier** | free vs unlocked capability | `enum Tier{ Free, Unlocked }` | gate decided before a paid op runs | SLICE | paid op runs while Free (revenue + trust bug) |

**Pedantic note for the reviewer:** the single most expensive ambiguity here is "redacted."
It means **the underlying bytes are gone**, not visually covered. Any code path that draws
over content and calls it redacted is a security defect, not a UI choice.

---

## 4 · QA DEFINITION (ready-state, hand to reviewer)

| Level | What it tests | Representative cases | Perf sample |
|---|---|---|---|
| **unit** | each strip/flatten/detect fn in `core` | empty file; max-size; unicode XMP; spoofed header; zero-area region; multi-page | time |
| **module** | `forge-core` public surface (`scrub(job)->Result<(CleanOutput,ScrubReport)>`) | each `SourceDoc` variant; all-tags-present; no-tags-present | time |
| **boundary** | serialised `ScrubReport` ↔ UI; `api/license` contract | report round-trips; malformed license payload rejected | time + payload size |
| **system** | assembled web app, one platform, end-to-end | drop image → strip EXIF → save; drop PDF → flatten region → save | time + wasm bundle delta |
| **STORY** | user journey, asserted as behaviour | "a journalist strips GPS from a photo and the output provably contains no GPS tag" | time, **gated** |

**Critical property tests (must exist):**
- *No residual:* for any input and any removed tag set, the `CleanOutput` bytes contain none
  of the removed tags. (This is the product's core promise — assert it for all inputs.)
- *Never panics:* `scrub` returns `Result` for absolutely any byte input, including garbage.
- *Idempotence:* scrubbing a CleanOutput again removes nothing and reports clean.

**STORY perf-delta:** baseline = the recorded median processing time for the representative
1-page PDF and 12-MP JPEG on the CI runner. **Budget: +15%.** A STORY exceeding budget vs
baseline does not merge. The gate runs with the STORY suite.

---

## 5 · CI DEFINITION (ready-state)

Gate sequence (blocking unless noted):
1. `cargo fmt --all -- --check` — block.
2. `cargo clippy --workspace --all-targets -- -D warnings` — block.
3. **unit + module + boundary** tests (`cargo test --workspace`) — block.
4. **system** tests (assembled web build + headless run) — block.
5. **STORY** tests **+ perf-delta gate** vs recorded baseline (+15% budget) — block.
6. `cargo build -p forge-web --target wasm32-unknown-unknown --release` — block.
7. mobile build check (`cargo build -p forge-mobile`) per target — warn (until Slice 4),
   then block.
8. `cargo audit` / `cargo deny` on dependencies — warn → block once baseline clean.

**Consistency check for the reviewer:** confirm this sequence matches
`.github/workflows/ci.yml`. Today CI implements steps 1–3 and 6; steps 4, 5, 7, 8 are the
ready-state additions this expansion specifies. The gap between "specified here" and
"implemented in CI" is itself a tracked finding — close it as the relevant slices land, and
do not claim the STORY perf-delta gate exists until step 5 is actually wired. (FOUNDER's
discovery would currently return `STORY perf-delta gate [✗]` → `CONTRACT UNMET` until then.)

---

## Handoff note
`reviewer`: verify (a) the lexicon invariants are internally consistent with the QA
properties (esp. *no residual* ↔ `CleanOutput` invariant ↔ the "redacted means bytes gone"
note), and (b) the CI ready-state is honestly distinguished from the CI as-built. Return
REQUEST CHANGES if the perf-delta gate is described as present before it is wired.
