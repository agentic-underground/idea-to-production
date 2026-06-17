//! Pure annotation formatter (roadmap #4 comment loop) — no IO. Turns a human
//! comment on an item into a deterministic, byte-stable markdown block that the
//! store appends to the item's plan document. Keeping the formatter pure means
//! the only IO (resolving the plan path and appending) lives in [`crate::store`],
//! and the block layout is pinned by tests independently of the file write.

use super::ids::ItemId;

/// Format a human comment as a markdown annotation block for an item's plan.
///
/// The block is self-contained and append-safe: it opens with a blank line so it
/// never runs into preceding content, carries a heading naming the item, and
/// renders the comment verbatim. The output is deterministic for a given
/// `(id, comment)` pair so it can be diffed and tested.
pub fn format_annotation(id: &ItemId, comment: &str) -> String {
    let body = comment.trim_end();
    format!(
        "\n<!-- annotation: {id} -->\n### Annotation on `{id}`\n\n{body}\n",
        id = id.as_str(),
        body = body,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn id(s: &str) -> ItemId {
        ItemId::new(s).unwrap()
    }

    #[test]
    fn formats_a_simple_comment() {
        let out = format_annotation(&id("flow-server"), "ship it");
        assert_eq!(
            out,
            "\n<!-- annotation: flow-server -->\n### Annotation on `flow-server`\n\nship it\n"
        );
    }

    #[test]
    fn trims_only_trailing_whitespace() {
        // Leading whitespace is preserved (it may be meaningful markdown); trailing
        // whitespace/newlines are trimmed so the block ends with exactly one '\n'.
        let out = format_annotation(&id("a"), "  indented body  \n\n");
        assert_eq!(
            out,
            "\n<!-- annotation: a -->\n### Annotation on `a`\n\n  indented body\n"
        );
    }

    #[test]
    fn empty_comment_yields_empty_body_line() {
        let out = format_annotation(&id("a"), "");
        assert_eq!(out, "\n<!-- annotation: a -->\n### Annotation on `a`\n\n\n");
    }

    #[test]
    fn multiline_comment_is_rendered_verbatim() {
        let out = format_annotation(&id("a"), "line one\nline two");
        assert!(out.contains("line one\nline two\n"));
        assert!(out.ends_with("line one\nline two\n"));
    }

    #[test]
    fn is_byte_stable_across_calls() {
        assert_eq!(
            format_annotation(&id("a"), "same"),
            format_annotation(&id("a"), "same")
        );
    }
}
