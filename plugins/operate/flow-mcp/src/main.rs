//! Flow MCP binary: parse config, open the store, ingest the roadmap source,
//! restore gates, and run the newline-delimited stdio JSON-RPC (MCP) loop.
//!
//! The web governance UI (HTTP + WebSocket + static board) was removed in
//! roadmap #39; the only transport is stdio. The `--mcp` flag is still accepted
//! as a harmless no-op for back-compat — there is no longer an HTTP mode to
//! select against.

use std::sync::Arc;

use flow_mcp::config::Config;
use flow_mcp::mcp;
use flow_mcp::store::Store;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = Config::from_args(std::env::args().skip(1))?;

    let store = Arc::new(Store::open(&cfg.data_dir).await?);

    // Seed the board from the roadmap source (tree or single file); an absent or
    // unreadable source degrades gracefully to an empty board (logged, not fatal).
    ingest_source(&store, &cfg).await?;

    // Restore gate state from .flow/gates.json AFTER ingest_roadmap, because
    // upsert_item resets every item's gate to Go (WaitGate default). This must
    // run last in the startup sequence. Infallible: missing or malformed file
    // leaves all gates at Go and logs a warning. (EARS-G36-02, EARS-G36-07)
    store.restore_gates().await;

    run_stdio(store).await?;
    Ok(())
}

/// Seed the board from the configured roadmap source (roadmap [42]). Resolution:
/// an explicit `--roadmap` path, else the conventional `.i2p/roadmap/` tree in the
/// cwd. A directory source is ingested as the file-per-item tree (folder = status,
/// with `post_status` write-back); a file source is the legacy single `ROADMAP.md`.
/// Degrades gracefully: no source or an unreadable file leaves the board empty
/// (logged, not fatal). A genuine store write error during ingest still propagates.
async fn ingest_source(store: &Store, cfg: &Config) -> Result<(), Box<dyn std::error::Error>> {
    let default_tree = std::path::PathBuf::from(".i2p/roadmap");
    let source = cfg
        .roadmap_path
        .clone()
        .or_else(|| default_tree.is_dir().then_some(default_tree));
    let Some(path) = source else {
        // No source resolved — log the cwd we looked in, so a silently-empty board
        // (e.g. the server spawned from the wrong directory) is diagnosable.
        eprintln!(
            "flow-mcp: no roadmap source (no --roadmap and no .i2p/roadmap/ under {}); starting empty",
            std::env::current_dir()
                .map(|p| p.display().to_string())
                .unwrap_or_else(|_| ".".into())
        );
        return Ok(());
    };
    if path.is_dir() {
        let n = store.ingest_roadmap_tree(&path).await?;
        eprintln!(
            "flow-mcp ingested {n} roadmap item(s) from the {} tree",
            path.display()
        );
        return Ok(());
    }
    match tokio::fs::read_to_string(&path).await {
        Ok(md) => {
            let n = store.ingest_roadmap(&md).await?;
            eprintln!(
                "flow-mcp ingested {n} roadmap item(s) from {}",
                path.display()
            );
        }
        Err(e) => eprintln!(
            "flow-mcp: no roadmap ingested ({}: {e}); starting empty",
            path.display()
        ),
    }
    Ok(())
}

/// Newline-delimited stdio JSON-RPC loop (the sole MCP transport).
///
/// Reads one JSON-RPC request per line from stdin, dispatches it through
/// `mcp::dispatch`, and writes a single newline-terminated JSON-RPC response to
/// stdout.
///
/// On EOF (stdin closed): exits the loop and returns `Ok(())`. The process
/// exits with code 0. On an unparseable line: writes a JSON-RPC -32700 parse
/// error response and continues reading.
async fn run_stdio(store: Arc<Store>) -> Result<(), Box<dyn std::error::Error>> {
    use flow_mcp::api::AppState;
    use flow_mcp::auth::Token;
    use tokio::io::{AsyncBufReadExt, AsyncWriteExt};

    // No token file is loaded: stdio has no auth transport, so the reserved
    // `token` field is filled with a placeholder and is never read in this path.
    let state = AppState {
        store,
        token: Token::new("stdio-noop"),
    };

    let stdin = tokio::io::stdin();
    let mut reader = tokio::io::BufReader::new(stdin);
    let mut line = String::new();

    loop {
        line.clear();
        let n = reader.read_line(&mut line).await?;
        if n == 0 {
            // EOF — clean exit
            break;
        }
        let trimmed = line.trim();
        if trimmed.is_empty() {
            // Blank line: treat as a parse error (no valid JSON-RPC request).
            let err = serde_json::json!({
                "jsonrpc": "2.0",
                "id": null,
                "error": { "code": -32700, "message": "Parse error" }
            });
            let mut out = tokio::io::stdout();
            out.write_all(format!("{err}\n").as_bytes()).await?;
            out.flush().await?;
            continue;
        }
        let req: serde_json::Value = match serde_json::from_str(trimmed) {
            Ok(v) => v,
            Err(_) => {
                // JSON-RPC parse error — write the error response and continue.
                let err = serde_json::json!({
                    "jsonrpc": "2.0",
                    "id": null,
                    "error": { "code": -32700, "message": "Parse error" }
                });
                let mut out = tokio::io::stdout();
                out.write_all(format!("{err}\n").as_bytes()).await?;
                out.flush().await?;
                continue;
            }
        };
        // JSON-RPC notifications carry no `id` (e.g. `notifications/initialized`
        // after the handshake) and MUST NOT receive a response — replying to one
        // is a protocol violation that some clients reject.
        let is_notification = req.get("id").is_none();
        let resp = mcp::dispatch(&state, req).await;
        if is_notification {
            continue;
        }
        let mut out = tokio::io::stdout();
        out.write_all(format!("{resp}\n").as_bytes()).await?;
        out.flush().await?;
    }
    Ok(())
}
