//! Story test for item [37]: subprocess stdio integration.
//!
//! Spawns the flow-mcp binary with --mcp, sends JSON-RPC requests over
//! stdin, reads responses from stdout, and verifies clean exit on stdin close.
//!
//! This file lives under `tests/` so cargo sets CARGO_BIN_EXE_flow-mcp
//! to the compiled binary path before running the test.
//!
//! NOTE: cargo test builds the binary before running integration tests, so
//! no manual build step is needed. If you see "failed to spawn" errors,
//! first run: cargo build -p flow-mcp
//!
//! Traces to: EVT-37-2, EVT-37-3, EVT-37-6, EVT-37-7
//! Emits: STORY_PROVEN

use tokio::io::{AsyncBufReadExt, AsyncWriteExt};

fn tempdir(tag: &str) -> std::path::PathBuf {
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);
    let n = COUNTER.fetch_add(1, Ordering::Relaxed);
    let dir =
        std::env::temp_dir().join(format!("flow-story-stdio-{tag}-{}-{n}", std::process::id()));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

/// Core story: send a list_items request, read the response, close stdin,
/// assert exit code 0.
///
/// STORY_PROVEN: this test exercises the full stdio round-trip:
///   1. Binary spawned with --mcp
///   2. tools/call list_items request written to stdin
///   3. JSON-RPC response read from stdout and validated
///   4. stdin closed → process exits with code 0
#[tokio::test]
async fn story_stdio_list_items_roundtrip() {
    let dir = tempdir("list-items");
    let bin = env!("CARGO_BIN_EXE_flow-mcp");
    let mut child = tokio::process::Command::new(bin)
        .arg("--mcp")
        .arg("--data")
        .arg(&dir)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .spawn()
        .expect("failed to spawn flow-mcp --mcp");

    let stdin = child.stdin.take().unwrap();
    let stdout = child.stdout.take().unwrap();

    let request = r#"{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_items","arguments":{}}}"#;

    let mut writer = tokio::io::BufWriter::new(stdin);
    writer
        .write_all(format!("{request}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();
    // Drop writer to close stdin → triggers EOF → clean exit
    drop(writer);

    let mut reader = tokio::io::BufReader::new(stdout);
    let mut response_line = String::new();
    reader.read_line(&mut response_line).await.unwrap();

    let resp: serde_json::Value =
        serde_json::from_str(response_line.trim()).expect("response must be valid JSON");

    assert_eq!(resp["jsonrpc"], "2.0", "must be JSON-RPC 2.0");
    assert_eq!(resp["id"], 1, "id must echo request id");
    assert!(
        resp["result"].is_object(),
        "result must be present, got: {resp:?}"
    );

    // Verify the grouped shape (pending/in_progress/done)
    assert!(
        resp["result"]["pending"].is_object(),
        "list_items result must have pending object, got: {resp:?}"
    );
    assert!(
        resp["result"]["in_progress"].is_array(),
        "list_items result must have in_progress array, got: {resp:?}"
    );
    assert!(
        resp["result"]["done"].is_array(),
        "list_items result must have done array, got: {resp:?}"
    );

    let status = child.wait().await.unwrap();
    assert!(
        status.success(),
        "flow-mcp --mcp must exit 0 on stdin close, got: {status}"
    );
}

/// Verify stdin close with NO requests → exit code 0 immediately.
#[tokio::test]
async fn story_stdio_empty_stdin_exits_cleanly() {
    let dir = tempdir("empty-stdin");
    let bin = env!("CARGO_BIN_EXE_flow-mcp");
    let mut child = tokio::process::Command::new(bin)
        .arg("--mcp")
        .arg("--data")
        .arg(&dir)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .spawn()
        .expect("failed to spawn flow-mcp --mcp");

    // Close stdin immediately — no requests sent
    drop(child.stdin.take());

    let status = child.wait().await.unwrap();
    assert!(
        status.success(),
        "flow-mcp --mcp must exit 0 when stdin is immediately closed, got: {status}"
    );
}

/// Verify malformed JSON → parse error response (-32700) written to stdout,
/// loop continues, then a valid request produces a valid response, exit 0.
///
/// Traces to: EVT-37-7
#[tokio::test]
async fn story_stdio_malformed_json_produces_parse_error() {
    let dir = tempdir("malformed");
    let bin = env!("CARGO_BIN_EXE_flow-mcp");
    let mut child = tokio::process::Command::new(bin)
        .arg("--mcp")
        .arg("--data")
        .arg(&dir)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .spawn()
        .expect("failed to spawn flow-mcp --mcp");

    let stdin = child.stdin.take().unwrap();
    let stdout = child.stdout.take().unwrap();

    let mut writer = tokio::io::BufWriter::new(stdin);
    // First line: garbage
    writer.write_all(b"not-valid-json\n").await.unwrap();
    // Second line: valid request
    let valid_req = r#"{"jsonrpc":"2.0","id":99,"method":"tools/list","params":{}}"#;
    writer
        .write_all(format!("{valid_req}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();
    drop(writer);

    let mut reader = tokio::io::BufReader::new(stdout);

    // First response: parse error
    let mut first_line = String::new();
    reader.read_line(&mut first_line).await.unwrap();
    let first: serde_json::Value =
        serde_json::from_str(first_line.trim()).expect("parse error response must be valid JSON");
    assert_eq!(
        first["error"]["code"],
        serde_json::json!(-32700),
        "malformed JSON must produce -32700 parse error, got: {first:?}"
    );

    // Second response: valid tools/list result
    let mut second_line = String::new();
    reader.read_line(&mut second_line).await.unwrap();
    let second: serde_json::Value =
        serde_json::from_str(second_line.trim()).expect("second response must be valid JSON");
    assert_eq!(second["id"], 99, "second response id must match");
    assert!(
        second["result"].is_object(),
        "second response must have a result, got: {second:?}"
    );

    let status = child.wait().await.unwrap();
    assert!(status.success(), "must exit 0, got: {status}");
}
