//! Roadmap history + git-log proxy synthesis (roadmap #5).
//!
//! Two pure parsers plus one tiny IO wrapper:
//!
//! * [`parse_roadmap`] ingests a structured `ROADMAP.md` into a [`Roadmap`]
//!   (reusing the domain [`Item`] and [`Edge`] types) — `## [N] TITLE` headings
//!   become [`Item`]s (stable slug ids derived from the `[N]` number),
//!   `> STATUS:` lines map onto [`Status`], and dependency lines
//!   (`> DEPENDS ON: #a, #b` and the `→ blocks on #x` tree notation) become
//!   [`Edge`]s.
//! * [`synthesize_from_git_log`] derives proxy historical [`Item`]s (each marked
//!   `synthesized`) from `git log` text, conventional-commit aware.
//!
//! [`parse_roadmap`] returns the raw `items + edges` rather than a [`Flow`]: the
//! ingester is faithful — it keeps a *cyclic* declared dependency as an edge,
//! because rejecting cycles is the [`Flow`] graph validator's job, not the
//! parser's. A caller that wants the validated graph feeds [`Roadmap`] into the
//! [`Flow`] constructors and handles any [`GraphError`](crate::domain::GraphError).
//!
//! The parsers take `&str` and return domain values — **no IO** — so they are
//! exhaustively testable from string fixtures. The only impure parts are the
//! thin [`read_roadmap_file`] / [`run_git_log`] helpers, which read a file or
//! shell `git log` and feed the pure parsers.

use std::collections::BTreeMap;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::domain::{Edge, Item, ItemId, Status};

/// The faithful result of ingesting a structured `ROADMAP.md`: items in display
/// order plus declared dependency edges. Cyclic and otherwise-questionable
/// dependencies are preserved here verbatim; graph validation is a downstream
/// concern (see [`crate::domain::Flow`]).
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Roadmap {
    /// Items in the order their headings appeared.
    pub items: Vec<Item>,
    /// Declared dependency edges (`from` depends on `to`), deduplicated.
    pub edges: Vec<Edge>,
}

impl Roadmap {
    /// Look up an ingested item by id.
    pub fn get(&self, id: &ItemId) -> Option<&Item> {
        self.items.iter().find(|i| &i.id == id)
    }
}

/// The model stamped onto items ingested from the roadmap / synthesized from git
/// (display proxies; the carriage agent resolves the real model later).
const HISTORY_MODEL: &str = "claude-sonnet-4-6";

/// Parse a structured `ROADMAP.md` into a [`Roadmap`] (items + edges).
///
/// Recognised lines (leading whitespace tolerated):
/// * `## [N] TITLE` — opens an item with stable slug id `item-N`.
/// * `> STATUS: <legend>` — sets the open item's status (COMPLETE→Done,
///   IN PROGRESS→Doing, anything else→Do).
/// * `> DEPENDS ON: #a, #b` — the open item depends on `item-a`, `item-b`
///   (a literal `—`/`-` placeholder means "no dependency").
/// * `├─ #from ... → blocks on #a, #b` (inside the dependency-tree block) —
///   `item-from` depends on `item-a`, `item-b`.
///
/// Pure: no IO. Validation (cycles, dangling edges) is the graph's job — this
/// parser ingests faithfully, deduplicating ids and edges, and tolerates
/// garbage lines, duplicate ids (last status/title wins via upsert), and
/// dependency cycles (kept as edges).
pub fn parse_roadmap(md: &str) -> Roadmap {
    let mut items: Vec<Item> = Vec::new();
    // Raw declared edges, collected as we scan; resolved against the final item
    // set afterwards so a forward reference still binds.
    let mut raw_edges: Vec<Edge> = Vec::new();
    // Index of the item opened by the most recent heading; `STATUS`/`DEPENDS ON`
    // bind to it. Tracking the slot (not the id) means the status write hits an
    // exact `&mut` with no fallible re-lookup.
    let mut current: Option<usize> = None;

    for raw in md.lines() {
        let line = raw.trim();

        if let Some(rest) = line.strip_prefix("## [") {
            if let Some((num, title)) = split_heading(rest) {
                if let Some(id) = item_id_for(num) {
                    current = Some(upsert(&mut items, &id, title));
                    continue;
                }
            }
            current = None;
            continue;
        }

        if let Some(rest) = line.strip_prefix("> STATUS:") {
            if let Some(idx) = current {
                items[idx].status = status_from(rest.trim());
            }
            continue;
        }

        if let Some(rest) = line.strip_prefix("> DEPENDS ON:") {
            if let Some(idx) = current {
                let from = items[idx].id.clone();
                for to in dep_ids(rest) {
                    raw_edges.push(Edge {
                        from: from.clone(),
                        to,
                    });
                }
            }
            continue;
        }

        if let Some((from, tos)) = parse_blocks_on(line) {
            for to in tos {
                raw_edges.push(Edge {
                    from: from.clone(),
                    to,
                });
            }
        }
    }

    let edges = resolve_edges(&items, raw_edges);
    Roadmap { items, edges }
}

// ── .i2p/roadmap/ tree ingest (roadmap item [42]) ────────────────────────────
// The marketplace's authoritative roadmap is a file-per-item tree where the
// FOLDER is the status (`backlog`/`do` → Do, `doing` → Doing, `done` → Done) and
// each `.md` carries YAML front-matter. We read it WITHOUT a YAML dependency: the
// fields are flat `key: value` lines, so a minimal hand-rolled reader (matching
// this crate's self-contained ethos) extracts `id`/`title`/`status`/`depends_on`.

/// The four status folders of the tree, in display order (folder name → status).
pub const TREE_FOLDERS: [&str; 4] = ["backlog", "do", "doing", "done"];

/// Map a tree folder name onto a board [`Status`]. `backlog` and `do` are both
/// pre-`Doing` (Do); `doing`/`done` map directly. An unknown folder defaults to Do.
pub fn status_for_folder(folder: &str) -> Status {
    match folder {
        "doing" => Status::Doing,
        "done" => Status::Done,
        _ => Status::Do,
    }
}

/// Parse the leading `---`…`---` front-matter into `key → value` pairs (first
/// fence pair only; values are unquoted scalars). Returns an empty map when the
/// file does not open with a `---` fence. Pure: no IO.
pub fn parse_front_matter(contents: &str) -> BTreeMap<String, String> {
    let mut map = BTreeMap::new();
    let mut lines = contents.lines();
    if lines.next().map(str::trim) != Some("---") {
        return map; // no front-matter block
    }
    for line in lines {
        let trimmed = line.trim();
        if trimmed == "---" {
            break; // end of the front-matter block
        }
        if let Some((k, v)) = line.split_once(':') {
            let key = k.trim().to_string();
            let val = v
                .trim()
                .trim_matches(|c| c == '"' || c == '\'')
                .trim()
                .to_string();
            if !key.is_empty() {
                map.insert(key, val);
            }
        }
    }
    map
}

/// Parse a `depends_on` front-matter value (`"#1, #2"`, `"1 2"`, or a `—`/`-`
/// placeholder) into dependency ids — numeric tokens only, deduplicated.
fn dep_ids_from_front_matter(raw: &str) -> Vec<ItemId> {
    let mut ids: Vec<ItemId> = Vec::new();
    for tok in raw.split(|c: char| c == ',' || c.is_whitespace()) {
        let t = tok.trim().trim_start_matches('#');
        if t.is_empty() || !t.chars().all(|c| c.is_ascii_digit()) {
            continue; // placeholder (— / -) or non-numeric → skip
        }
        if let Some(id) = item_id_for(t) {
            if !ids.contains(&id) {
                ids.push(id);
            }
        }
    }
    ids
}

/// Parse one tree item file (its `folder` sets the status) into an [`Item`] plus
/// its declared dependency edges. `None` when there is no usable `id`. Pure: no IO.
pub fn parse_item_file(folder: &str, contents: &str) -> Option<(Item, Vec<Edge>)> {
    let fm = parse_front_matter(contents);
    let id = item_id_for(fm.get("id")?)?;
    let title = fm.get("title").cloned().unwrap_or_default();
    let mut item = Item::new(id.clone(), &title, HISTORY_MODEL);
    item.status = status_for_folder(folder);
    let edges = fm
        .get("depends_on")
        .map(|d| {
            dep_ids_from_front_matter(d)
                .into_iter()
                .map(|to| Edge {
                    from: id.clone(),
                    to,
                })
                .collect()
        })
        .unwrap_or_default();
    Some((item, edges))
}

/// Load the `.i2p/roadmap/` tree at `tree_dir` into a faithful [`Roadmap`]:
/// enumerate `{backlog,do,doing,done}/*.md`, parse each file's front-matter, and
/// take the folder as the status. A missing folder is skipped; an absent tree
/// yields an empty roadmap (never an error). Edges are resolved against the loaded
/// set; cycle rejection stays the graph validator's job. The only IO is the
/// directory reads — parsing is delegated to the pure [`parse_item_file`].
pub fn load_roadmap_tree(tree_dir: &Path) -> Roadmap {
    let mut items: Vec<Item> = Vec::new();
    let mut raw_edges: Vec<Edge> = Vec::new();
    for folder in TREE_FOLDERS {
        let dir = tree_dir.join(folder);
        let entries = match std::fs::read_dir(&dir) {
            Ok(e) => e,
            Err(_) => continue, // missing folder → skip
        };
        let mut paths: Vec<PathBuf> = entries
            .filter_map(|e| e.ok().map(|e| e.path()))
            .filter(|p| p.extension().and_then(|x| x.to_str()) == Some("md"))
            .collect();
        paths.sort(); // deterministic order (id-prefixed filenames sort sensibly)
        for path in paths {
            let Ok(contents) = std::fs::read_to_string(&path) else {
                continue;
            };
            if let Some((item, edges)) = parse_item_file(folder, &contents) {
                // Last file wins on a duplicate id (keeps its folder-derived status).
                match items.iter().position(|i| i.id == item.id) {
                    Some(idx) => items[idx] = item,
                    None => items.push(item),
                }
                raw_edges.extend(edges);
            }
        }
    }
    let edges = resolve_edges(&items, raw_edges);
    Roadmap { items, edges }
}

/// Upsert an item by id, returning its index: replace the title (keeping status)
/// if the id is known, else append a fresh DO item. Last heading wins on a
/// duplicate `[N]`.
fn upsert(items: &mut Vec<Item>, id: &ItemId, title: &str) -> usize {
    match items.iter().position(|i| &i.id == id) {
        Some(idx) => {
            items[idx].title = title.to_string();
            idx
        }
        None => {
            items.push(Item::new(id.clone(), title, HISTORY_MODEL));
            items.len() - 1
        }
    }
}

/// Keep only edges whose endpoints are both known items, dropping self-edges and
/// duplicates. Cyclic-but-otherwise-valid edges are *kept* — cycle rejection is
/// the graph validator's job.
fn resolve_edges(items: &[Item], raw: Vec<Edge>) -> Vec<Edge> {
    let known = |id: &ItemId| items.iter().any(|i| &i.id == id);
    let mut edges: Vec<Edge> = Vec::new();
    for edge in raw {
        if edge.from == edge.to || !known(&edge.from) || !known(&edge.to) {
            continue;
        }
        if !edges.contains(&edge) {
            edges.push(edge);
        }
    }
    edges
}

/// Synthesize proxy historical [`Item`]s from `git log` text.
///
/// Each non-blank line is treated as one commit subject. A conventional-commit
/// subject (`type(scope): subject` or `type: subject`) yields a [`Done`],
/// `synthesized` item titled with the full subject; a non-conventional line
/// yields a `synthesized` Done item titled with the raw line. Ids are stable
/// `commit-N` slugs in log order (so reordering the log re-numbers, but the
/// proxy set stays stable for a given log).
///
/// [`Done`]: Status::Done
///
/// Pure: operates only on the string.
pub fn synthesize_from_git_log(log: &str) -> Vec<Item> {
    log.lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .enumerate()
        // `commit-{n}` (n ≥ 1) is always a valid slug, so `ItemId::new` yields
        // `Ok`; `.ok()` + `flat_map` keeps the function total with no in-source
        // branch for the impossible failure (the `None` case is simply an empty
        // iterator contribution, not an instrumented else-region here).
        .flat_map(|(idx, line)| {
            ItemId::new(&format!("commit-{}", idx + 1)).ok().map(|id| {
                let mut item = Item::new(id, line, HISTORY_MODEL);
                item.status = Status::Done;
                item.synthesized = true;
                item
            })
        })
        .collect()
}

/// Map a `> STATUS:` legend value onto a board [`Status`].
fn status_from(raw: &str) -> Status {
    match raw.to_ascii_uppercase().as_str() {
        "COMPLETE" | "AWAITING MERGE" => Status::Done,
        "IN PROGRESS" => Status::Doing,
        _ => Status::Do,
    }
}

/// Split a `## [` heading remainder (`N] TITLE`) into `(number, title)`.
fn split_heading(rest: &str) -> Option<(&str, &str)> {
    let (num, after) = rest.split_once(']')?;
    let num = num.trim();
    if num.is_empty() {
        return None;
    }
    Some((num, after.trim()))
}

/// Build the stable slug id for a roadmap item number, e.g. `5` → `item-5`.
/// Returns `None` if the number token is not slug-safe.
fn item_id_for(num: &str) -> Option<ItemId> {
    let token = num.trim();
    let slug = format!("item-{}", token.to_ascii_lowercase());
    ItemId::new(&slug).ok()
}

/// Parse the right-hand side of a `> DEPENDS ON:` line into dependency ids.
/// `—`, `-` and empty placeholders yield no ids.
fn dep_ids(rest: &str) -> Vec<ItemId> {
    extract_hash_ids(rest)
}

/// Parse a dependency-tree row (`├─ #2 ... → blocks on #1, #3`) into
/// `(from_id, [to_ids])`, or `None` if the row is not a `blocks on` row with a
/// recognisable `#from` source.
fn parse_blocks_on(line: &str) -> Option<(ItemId, Vec<ItemId>)> {
    let idx = line.find("blocks on")?;
    let (before, after) = line.split_at(idx);
    let from = first_hash_id(before)?;
    let tos = extract_hash_ids(after);
    if tos.is_empty() {
        return None;
    }
    Some((from, tos))
}

/// Collect every `#token` in `text` as an item id (deduplicated, order-stable),
/// skipping tokens that do not form a slug-safe item number.
fn extract_hash_ids(text: &str) -> Vec<ItemId> {
    let mut ids: Vec<ItemId> = Vec::new();
    // `hash_tokens` yields only `[a-z0-9]` runs, so `item_id_for` is always
    // `Some` here; `flatten` keeps the loop total without an unreachable `else`
    // for the impossible `None`. The dedup branch below *is* reachable (tested).
    for id in hash_tokens(text).into_iter().filter_map(item_id_for) {
        if !ids.contains(&id) {
            ids.push(id);
        }
    }
    ids
}

/// The first `#token` in `text` as an item id, if any.
fn first_hash_id(text: &str) -> Option<ItemId> {
    hash_tokens(text).into_iter().find_map(item_id_for)
}

/// Split `text` on `#`, taking the leading run of `[a-z0-9]` after each `#` as a
/// token. An empty run (e.g. a stray `#` or `# `) is dropped.
fn hash_tokens(text: &str) -> Vec<&str> {
    text.split('#')
        .skip(1)
        .map(|seg| {
            let end = seg
                .find(|c: char| !c.is_ascii_alphanumeric())
                .unwrap_or(seg.len());
            &seg[..end]
        })
        .filter(|tok| !tok.is_empty())
        .collect()
}

/// Read a roadmap markdown file and parse it. The **only** impure entry point
/// for the roadmap parser; the parsing itself is [`parse_roadmap`].
pub fn read_roadmap_file(path: impl AsRef<Path>) -> io::Result<Roadmap> {
    let md = std::fs::read_to_string(path)?;
    Ok(parse_roadmap(&md))
}

/// Shell `git log` in `repo_dir` and synthesize proxy historical items from its
/// output. The **only** impure entry point for the git-log synthesis; the
/// synthesis itself is [`synthesize_from_git_log`].
///
/// Per roadmap #5's "IF the git log is empty or unreadable THEN show the
/// roadmap-native history only", this never errors: an unspawnable/erroring
/// `git`, or an empty log, both yield an empty vector. The byte output is read
/// via `unwrap_or_default`, so a failed spawn collapses to no proxy items.
pub fn run_git_log(repo_dir: impl AsRef<Path>) -> Vec<Item> {
    let stdout = Command::new("git")
        .arg("-C")
        .arg(repo_dir.as_ref())
        .args(["log", "--pretty=%s"])
        .output()
        .map(|o| o.stdout)
        .unwrap_or_default();
    let log = String::from_utf8_lossy(&stdout);
    synthesize_from_git_log(&log)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn iid(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    // ---- parse_roadmap: happy path -------------------------------------

    #[test]
    fn parses_well_formed_roadmap_items_and_statuses() {
        let md = "\
## [1] Flow server
> STATUS: IN PROGRESS
> DEPENDS ON: —

## [5] Roadmap history
> STATUS: COMPLETE
> DEPENDS ON: #1

## [2] Canvas
> STATUS: PENDING
> DEPENDS ON: #1, #5
";
        let flow = parse_roadmap(md);
        let items: Vec<_> = flow
            .items
            .iter()
            .map(|i| (i.id.as_str().to_string(), i.title.clone(), i.status))
            .collect();
        assert_eq!(
            items,
            vec![
                (
                    "item-1".to_string(),
                    "Flow server".to_string(),
                    Status::Doing
                ),
                (
                    "item-5".to_string(),
                    "Roadmap history".to_string(),
                    Status::Done
                ),
                ("item-2".to_string(), "Canvas".to_string(), Status::Do),
            ]
        );
        // edges: 5->1, 2->1, 2->5
        let mut edges: Vec<_> = flow
            .edges
            .iter()
            .map(|e| (e.from.as_str().to_string(), e.to.as_str().to_string()))
            .collect();
        edges.sort();
        assert_eq!(
            edges,
            vec![
                ("item-2".to_string(), "item-1".to_string()),
                ("item-2".to_string(), "item-5".to_string()),
                ("item-5".to_string(), "item-1".to_string()),
            ]
        );
    }

    #[test]
    fn all_status_legends_map_correctly() {
        let md = "\
## [1] A
> STATUS: COMPLETE
## [2] B
> STATUS: IN PROGRESS
## [3] C
> STATUS: PENDING
## [4] D
> STATUS: AWAITING MERGE
## [5] E
> STATUS: DEFERRED
## [6] F
> STATUS: SUSPENDED
";
        let flow = parse_roadmap(md);
        let s = |n: &str| flow.get(&iid(n)).unwrap().status;
        assert_eq!(s("item-1"), Status::Done);
        assert_eq!(s("item-2"), Status::Doing);
        assert_eq!(s("item-3"), Status::Do);
        assert_eq!(s("item-4"), Status::Done); // AWAITING MERGE → Done
        assert_eq!(s("item-5"), Status::Do);
        assert_eq!(s("item-6"), Status::Do);
    }

    #[test]
    fn status_legend_is_case_insensitive() {
        let md = "## [1] A\n> STATUS: complete\n## [2] B\n> STATUS: In Progress\n";
        let flow = parse_roadmap(md);
        assert_eq!(flow.get(&iid("item-1")).unwrap().status, Status::Done);
        assert_eq!(flow.get(&iid("item-2")).unwrap().status, Status::Doing);
    }

    #[test]
    fn parses_blocks_on_tree_notation() {
        let md = "\
```
EPIC #0 root
 ├─ #1 Flow server   [atomic]
 ├─ #2 Canvas                       → blocks on #1
 └─ #4 Loop                         → blocks on #2, #3
```

## [1] Flow server
> STATUS: IN PROGRESS
## [2] Canvas
> STATUS: PENDING
## [3] Telemetry
> STATUS: PENDING
## [4] Loop
> STATUS: PENDING
";
        let flow = parse_roadmap(md);
        let mut edges: Vec<_> = flow
            .edges
            .iter()
            .map(|e| (e.from.as_str().to_string(), e.to.as_str().to_string()))
            .collect();
        edges.sort();
        assert_eq!(
            edges,
            vec![
                ("item-2".to_string(), "item-1".to_string()),
                ("item-4".to_string(), "item-2".to_string()),
                ("item-4".to_string(), "item-3".to_string()),
            ]
        );
    }

    #[test]
    fn tolerates_leading_whitespace_on_directives() {
        let md = "  ## [7] Indented\n    > STATUS: COMPLETE\n      > DEPENDS ON: #1\n## [1] Dep\n> STATUS: PENDING\n";
        let flow = parse_roadmap(md);
        assert_eq!(flow.get(&iid("item-7")).unwrap().status, Status::Done);
        assert_eq!(flow.edges.len(), 1);
        assert_eq!(flow.edges[0].from, iid("item-7"));
        assert_eq!(flow.edges[0].to, iid("item-1"));
    }

    // ---- parse_roadmap: unhappy path -----------------------------------

    #[test]
    fn empty_input_yields_empty_flow() {
        let flow = parse_roadmap("");
        assert!(flow.items.is_empty());
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn item_without_status_defaults_to_do() {
        let md = "## [1] No status here\n";
        let flow = parse_roadmap(md);
        assert_eq!(flow.get(&iid("item-1")).unwrap().status, Status::Do);
    }

    #[test]
    fn malformed_heading_missing_bracket_is_ignored() {
        // No closing ']' — split_heading returns None.
        let md = "## [1 broken heading\n> STATUS: COMPLETE\n";
        let flow = parse_roadmap(md);
        assert!(flow.items.is_empty());
        // The orphan STATUS line (no current item) is harmlessly dropped.
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn heading_with_empty_number_is_ignored() {
        let md = "## [] No number\n> STATUS: COMPLETE\n";
        let flow = parse_roadmap(md);
        assert!(flow.items.is_empty());
    }

    #[test]
    fn heading_with_unsluggable_number_is_ignored() {
        // A '_' is not slug-safe, so item_id_for returns None and the heading is
        // skipped; the following STATUS line then has no current item.
        let md = "## [1_2] Bad id\n> STATUS: COMPLETE\n";
        let flow = parse_roadmap(md);
        assert!(flow.items.is_empty());
    }

    #[test]
    fn status_and_depends_before_any_item_are_dropped() {
        let md = "> STATUS: COMPLETE\n> DEPENDS ON: #1\n";
        let flow = parse_roadmap(md);
        assert!(flow.items.is_empty());
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn depends_on_placeholder_dash_yields_no_edges() {
        let md = "## [1] Atomic\n> STATUS: PENDING\n> DEPENDS ON: — (atomic; foundation)\n";
        let flow = parse_roadmap(md);
        assert!(flow.edges.is_empty());
    }

    // ---- parse_roadmap: abuse ------------------------------------------

    #[test]
    fn garbage_lines_are_ignored() {
        let md = "\
random nonsense !@#$%^&*()
## [1] Real
> STATUS: COMPLETE
the # quick brown # fox
> not a directive
## [2] Real two
> STATUS: PENDING
";
        let flow = parse_roadmap(md);
        assert_eq!(flow.items.len(), 2);
        // '#' followed by non-alphanumerics (space) contributes no ids/edges.
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn duplicate_item_ids_upsert_last_title_and_status() {
        let md = "\
## [1] First title
> STATUS: PENDING
## [1] Second title
> STATUS: COMPLETE
";
        let flow = parse_roadmap(md);
        assert_eq!(flow.items.len(), 1);
        let it = flow.get(&iid("item-1")).unwrap();
        assert_eq!(it.title, "Second title");
        assert_eq!(it.status, Status::Done);
    }

    #[test]
    fn duplicate_edges_are_deduplicated() {
        let md = "\
## [1] A
> STATUS: PENDING
## [2] B
> STATUS: PENDING
> DEPENDS ON: #1, #1
> DEPENDS ON: #1
";
        let flow = parse_roadmap(md);
        assert_eq!(flow.edges.len(), 1);
    }

    #[test]
    fn cyclic_dependencies_are_kept_as_edges() {
        // 1 depends on 2, 2 depends on 1 — a cycle. The parser keeps both edges;
        // rejecting cycles is the graph validator's job, not the ingester's.
        let md = "\
## [1] A
> STATUS: PENDING
> DEPENDS ON: #2
## [2] B
> STATUS: PENDING
> DEPENDS ON: #1
";
        let flow = parse_roadmap(md);
        let mut edges: Vec<_> = flow
            .edges
            .iter()
            .map(|e| (e.from.as_str().to_string(), e.to.as_str().to_string()))
            .collect();
        edges.sort();
        assert_eq!(
            edges,
            vec![
                ("item-1".to_string(), "item-2".to_string()),
                ("item-2".to_string(), "item-1".to_string()),
            ]
        );
    }

    #[test]
    fn self_dependency_is_dropped() {
        let md = "## [1] A\n> STATUS: PENDING\n> DEPENDS ON: #1\n";
        let flow = parse_roadmap(md);
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn dependency_on_unknown_item_is_dropped() {
        let md = "## [1] A\n> STATUS: PENDING\n> DEPENDS ON: #99\n";
        let flow = parse_roadmap(md);
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn blocks_on_without_source_hash_is_ignored() {
        // "blocks on #1" with no '#from' before it → parse_blocks_on returns None.
        let md = "## [1] A\n> STATUS: PENDING\n no source here blocks on #1\n";
        let flow = parse_roadmap(md);
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn blocks_on_without_target_hash_is_ignored() {
        let md = "## [1] A\n> STATUS: PENDING\n ├─ #1 thing blocks on nothing\n";
        let flow = parse_roadmap(md);
        assert!(flow.edges.is_empty());
    }

    #[test]
    fn stray_hash_tokens_are_skipped() {
        // A bare '#' and a '# ' produce empty tokens, dropped by hash_tokens.
        let md =
            "## [1] A\n> STATUS: PENDING\n## [2] B\n> STATUS: PENDING\n> DEPENDS ON: #, # , #1\n";
        let flow = parse_roadmap(md);
        assert_eq!(flow.edges.len(), 1);
        assert_eq!(flow.edges[0].to, iid("item-1"));
    }

    // ---- synthesize_from_git_log ---------------------------------------

    #[test]
    fn synthesizes_done_items_from_conventional_commits() {
        let log = "\
feat(server): add the flow store
fix: correct a cycle check
docs(readme): explain the board
";
        let items = synthesize_from_git_log(log);
        assert_eq!(items.len(), 3);
        for it in &items {
            assert_eq!(it.status, Status::Done);
            assert!(it.synthesized);
            assert_eq!(it.model, "claude-sonnet-4-6");
        }
        assert_eq!(items[0].id.as_str(), "commit-1");
        assert_eq!(items[0].title, "feat(server): add the flow store");
        assert_eq!(items[1].id.as_str(), "commit-2");
        assert_eq!(items[1].title, "fix: correct a cycle check");
        assert_eq!(items[2].id.as_str(), "commit-3");
    }

    #[test]
    fn synthesizes_non_conventional_lines_verbatim() {
        let log = "just a plain commit subject\nAnother One Without A Type\n";
        let items = synthesize_from_git_log(log);
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].title, "just a plain commit subject");
        assert_eq!(items[1].title, "Another One Without A Type");
        assert!(items
            .iter()
            .all(|i| i.synthesized && i.status == Status::Done));
    }

    #[test]
    fn empty_log_yields_no_items() {
        assert!(synthesize_from_git_log("").is_empty());
    }

    #[test]
    fn blank_and_whitespace_lines_are_skipped() {
        let log = "\n   \nfeat: real\n\t\nfix: another\n   \n";
        let items = synthesize_from_git_log(log);
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].id.as_str(), "commit-1");
        assert_eq!(items[0].title, "feat: real");
        assert_eq!(items[1].id.as_str(), "commit-2");
        assert_eq!(items[1].title, "fix: another");
    }

    // ---- IO wrappers (thin; exercised against temp fixtures) -----------

    #[test]
    fn read_roadmap_file_round_trips_through_parser() {
        // Both the happy and the missing-path cases call the same `&Path`
        // monomorphization of the generic `read_roadmap_file`, so one
        // instantiation exercises both the `?`-error and the `Ok` exits.
        let dir = std::env::temp_dir().join(format!("flow-history-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("ROADMAP.md");
        std::fs::write(&path, "## [1] One\n> STATUS: COMPLETE\n").unwrap();
        let flow = read_roadmap_file(path.as_path()).unwrap();
        assert_eq!(flow.get(&iid("item-1")).unwrap().status, Status::Done);
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn read_roadmap_file_missing_path_is_io_error() {
        let missing = Path::new("/no/such/roadmap/file.md");
        let err = read_roadmap_file(missing);
        assert!(err.is_err());
    }

    #[test]
    fn run_git_log_on_a_repo_synthesizes_items() {
        // Build a throwaway git repo with two commits, then synthesize from it.
        let dir = std::env::temp_dir().join(format!("flow-gitlog-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let git = |args: &[&str]| {
            Command::new("git")
                .arg("-C")
                .arg(&dir)
                .args(args)
                .output()
                .unwrap()
        };
        git(&["init", "-q"]);
        git(&["config", "user.email", "t@t.t"]);
        git(&["config", "user.name", "t"]);
        git(&["commit", "--allow-empty", "-q", "-m", "feat: first"]);
        git(&["commit", "--allow-empty", "-q", "-m", "fix: second"]);
        let items = run_git_log(&dir);
        assert_eq!(items.len(), 2);
        assert!(items
            .iter()
            .all(|i| i.synthesized && i.status == Status::Done));
        // newest first in git log order
        assert_eq!(items[0].title, "fix: second");
        assert_eq!(items[1].title, "feat: first");
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn run_git_log_on_a_nonexistent_directory_yields_no_items() {
        // git is invoked with -C on a path that does not exist; git exits
        // non-zero with empty stdout, so synthesis yields no proxy items. Per
        // roadmap #5 this is the "empty or unreadable log" degrade-to-nothing
        // path, not an error.
        let items = run_git_log("/no/such/repo/dir/at/all");
        assert!(items.is_empty());
    }

    // ---- .i2p/roadmap/ tree ingest (roadmap [42]) ----------------------

    fn tree_tempdir(tag: &str) -> PathBuf {
        use std::sync::atomic::{AtomicU64, Ordering};
        static N: AtomicU64 = AtomicU64::new(0);
        let n = N.fetch_add(1, Ordering::Relaxed);
        let dir = std::env::temp_dir().join(format!("flow-tree-{tag}-{}-{n}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        dir
    }

    fn write_item(root: &Path, folder: &str, name: &str, body: &str) {
        let dir = root.join(folder);
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join(name), body).unwrap();
    }

    #[test]
    fn front_matter_parses_fields_and_strips_quotes() {
        let fm = parse_front_matter(
            "---\nid: 42\ntitle: \"A: colon title\"\nstatus: PENDING\n---\nbody\n",
        );
        assert_eq!(fm.get("id").map(String::as_str), Some("42"));
        assert_eq!(fm.get("title").map(String::as_str), Some("A: colon title"));
        assert_eq!(fm.get("status").map(String::as_str), Some("PENDING"));
    }

    #[test]
    fn front_matter_absent_without_opening_fence() {
        assert!(parse_front_matter("# heading\nid: 1\n").is_empty());
    }

    #[test]
    fn status_for_folder_maps_each_lane() {
        assert_eq!(status_for_folder("backlog"), Status::Do);
        assert_eq!(status_for_folder("do"), Status::Do);
        assert_eq!(status_for_folder("doing"), Status::Doing);
        assert_eq!(status_for_folder("done"), Status::Done);
        assert_eq!(status_for_folder("anything-else"), Status::Do);
    }

    #[test]
    fn parse_item_file_uses_folder_status_and_hash_deps() {
        let (item, edges) = parse_item_file(
            "doing",
            "---\nid: 7\ntitle: Seven\ndepends_on: \"#1, #3\"\n---\n",
        )
        .unwrap();
        assert_eq!(item.id, iid("item-7"));
        assert_eq!(item.title, "Seven");
        assert_eq!(item.status, Status::Doing);
        assert_eq!(
            edges,
            vec![
                Edge {
                    from: iid("item-7"),
                    to: iid("item-1")
                },
                Edge {
                    from: iid("item-7"),
                    to: iid("item-3")
                },
            ]
        );
    }

    #[test]
    fn parse_item_file_dash_placeholder_yields_no_edges() {
        let (_item, edges) = parse_item_file(
            "backlog",
            "---\nid: 2\ntitle: Two\ndepends_on: \"—\"\n---\n",
        )
        .unwrap();
        assert!(edges.is_empty());
    }

    #[test]
    fn parse_item_file_none_without_id() {
        assert!(parse_item_file("backlog", "---\ntitle: No id\n---\n").is_none());
    }

    #[test]
    fn load_roadmap_tree_groups_items_by_folder_and_resolves_edges() {
        let root = tree_tempdir("load");
        write_item(
            &root,
            "backlog",
            "16-epic.md",
            "---\nid: 16\ntitle: Epic\ndepends_on: \"—\"\n---\n",
        );
        write_item(
            &root,
            "doing",
            "42-tree.md",
            "---\nid: 42\ntitle: Tree\ndepends_on: \"#16\"\n---\n",
        );
        write_item(
            &root,
            "done",
            "01-first.md",
            "---\nid: 1\ntitle: First\n---\n",
        );
        // non-.md and a missing `do/` folder are tolerated.
        std::fs::write(root.join("backlog").join("notes.txt"), "ignore me").unwrap();

        let rm = load_roadmap_tree(&root);
        assert_eq!(rm.items.len(), 3);
        let status_of = |id: &str| rm.get(&iid(id)).unwrap().status;
        assert_eq!(status_of("item-16"), Status::Do);
        assert_eq!(status_of("item-42"), Status::Doing);
        assert_eq!(status_of("item-1"), Status::Done);
        // The `#16` dep resolves (both endpoints known).
        assert_eq!(
            rm.edges,
            vec![Edge {
                from: iid("item-42"),
                to: iid("item-16")
            }]
        );
        std::fs::remove_dir_all(&root).unwrap();
    }

    #[test]
    fn load_roadmap_tree_absent_is_empty_not_error() {
        let rm = load_roadmap_tree(Path::new("/no/such/roadmap/tree/anywhere"));
        assert!(rm.items.is_empty() && rm.edges.is_empty());
    }
}
