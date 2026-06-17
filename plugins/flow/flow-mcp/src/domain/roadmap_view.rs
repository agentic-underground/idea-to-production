//! Pure roadmap renderer (roadmap #15) — no IO. Turns a [`Flow`] into a
//! deterministic, byte-stable text view of its items grouped by the DO·DOING·DONE
//! board, one row per item (id · title · status · gate · tokens · draft). The
//! flow server exposes this over the `render_roadmap` MCP verb and the
//! `GET /api/roadmap/rendered` route so "what's on the roadmap" is answered by
//! local compute (~0 LLM tokens) and is identical to what the board shows.

use super::model::{Flow, Item, Status};

/// Render `flow` as a deterministic, byte-stable text board.
///
/// The output is three sections — `DO`, `DOING`, `DONE` — each listing its items
/// in the flow's display order as `· id · title · status · gate · NNN tok · dN`.
/// An empty section is rendered with a `(none)` placeholder so the shape is
/// stable regardless of contents. Pure: the same flow always yields the same
/// bytes, so it can be cached, diffed, and compared.
pub fn render_roadmap(flow: &Flow) -> String {
    let items = flow.items_in_order();
    let mut out = String::new();
    out.push_str("ROADMAP\n");
    out.push_str(&format!("{} item(s)\n", items.len()));
    for (heading, status) in [
        ("DO", Status::Do),
        ("DOING", Status::Doing),
        ("DONE", Status::Done),
    ] {
        out.push('\n');
        out.push_str(heading);
        out.push('\n');
        let group: Vec<&&Item> = items.iter().filter(|i| i.status == status).collect();
        if group.is_empty() {
            out.push_str("  (none)\n");
        } else {
            for item in group {
                out.push_str(&render_row(item));
                out.push('\n');
            }
        }
    }
    out
}

/// Render one item as a single board row. Kept separate so the column layout is
/// pinned independently of the section grouping.
fn render_row(item: &Item) -> String {
    format!(
        "  · {} · {} · {} · {} · {} tok · d{}",
        item.id.as_str(),
        item.title,
        status_label(item.status),
        gate_label(item),
        item.tokens,
        item.draft,
    )
}

fn status_label(status: Status) -> &'static str {
    match status {
        Status::Do => "DO",
        Status::Doing => "DOING",
        Status::Done => "DONE",
    }
}

fn gate_label(item: &Item) -> &'static str {
    match item.gate {
        super::model::WaitGate::Go => "GO",
        super::model::WaitGate::Wait => "WAIT",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::ids::ItemId;
    use crate::domain::model::{Status, WaitGate};

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    fn item(s: &str) -> Item {
        Item::new(id(s), s, "claude-sonnet-4-6")
    }

    #[test]
    fn empty_flow_renders_all_sections_with_none() {
        let f = Flow::new();
        let out = render_roadmap(&f);
        assert_eq!(
            out,
            "ROADMAP\n0 item(s)\n\nDO\n  (none)\n\nDOING\n  (none)\n\nDONE\n  (none)\n"
        );
    }

    #[test]
    fn single_item_renders_in_do() {
        let mut f = Flow::new();
        f.upsert_item(item("alpha"));
        let out = render_roadmap(&f);
        assert_eq!(
            out,
            "ROADMAP\n1 item(s)\n\nDO\n  · alpha · alpha · DO · GO · 0 tok · d0\n\nDOING\n  (none)\n\nDONE\n  (none)\n"
        );
    }

    #[test]
    fn items_group_by_status_and_keep_display_order() {
        let mut f = Flow::new();
        // Insertion order a, b, c, d — display order is insertion order.
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        f.upsert_item(item("c"));
        f.upsert_item(item("d"));
        f.advance_status(&id("b"), Status::Doing).unwrap();
        f.advance_status(&id("c"), Status::Done).unwrap();
        // d also DOING — must appear after b within the DOING section.
        f.advance_status(&id("d"), Status::Doing).unwrap();
        let out = render_roadmap(&f);
        let doing = out
            .split("DOING\n")
            .nth(1)
            .unwrap()
            .split("\n\nDONE")
            .next()
            .unwrap();
        assert_eq!(
            doing,
            "  · b · b · DOING · GO · 0 tok · d0\n  · d · d · DOING · GO · 0 tok · d0"
        );
        // a stays in DO, c lands in DONE.
        assert!(out.contains("DO\n  · a · a · DO · GO · 0 tok · d0\n"));
        assert!(out.contains("DONE\n  · c · c · DONE · GO · 0 tok · d0\n"));
    }

    #[test]
    fn row_reflects_gate_tokens_and_draft() {
        let mut f = Flow::new();
        f.upsert_item(item("x"));
        f.append_spend(&id("x"), 1234).unwrap();
        f.set_gate(&id("x"), WaitGate::Wait).unwrap();
        f.bump_draft(&id("x")).unwrap();
        f.bump_draft(&id("x")).unwrap();
        let out = render_roadmap(&f);
        assert!(out.contains("  · x · x · DO · WAIT · 1234 tok · d2\n"));
    }

    #[test]
    fn with_dependencies_renders_each_item_once() {
        // Edges do not change the row count or grouping — items render once each.
        let mut f = Flow::new();
        f.upsert_item(item("parent"));
        f.upsert_item(item("child"));
        f.add_connection(id("parent"), id("child")).unwrap();
        let out = render_roadmap(&f);
        assert_eq!(out.matches("· parent ·").count(), 1);
        assert_eq!(out.matches("· child ·").count(), 1);
        assert!(out.starts_with("ROADMAP\n2 item(s)\n"));
    }

    #[test]
    fn is_byte_stable_across_calls() {
        let mut f = Flow::new();
        f.upsert_item(item("a"));
        f.upsert_item(item("b"));
        assert_eq!(render_roadmap(&f), render_roadmap(&f));
    }

    #[test]
    fn status_and_gate_labels_cover_all_variants() {
        assert_eq!(status_label(Status::Do), "DO");
        assert_eq!(status_label(Status::Doing), "DOING");
        assert_eq!(status_label(Status::Done), "DONE");
        let mut go = item("g");
        go.gate = WaitGate::Go;
        assert_eq!(gate_label(&go), "GO");
        go.gate = WaitGate::Wait;
        assert_eq!(gate_label(&go), "WAIT");
    }
}
