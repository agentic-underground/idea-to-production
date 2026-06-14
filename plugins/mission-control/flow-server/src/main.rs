//! Flow server binary: parse config, load/create the token, open the store,
//! build the router, bind, and serve.
//!
//! When `--mcp` is supplied: skip HTTP binding; run the newline-delimited
//! stdio JSON-RPC loop instead. The store is opened identically in both paths.

use std::net::SocketAddr;
use std::sync::Arc;

use flow_server::api::build_router;
use flow_server::auth::Token;
use flow_server::config::Config;
use flow_server::mcp;
use flow_server::store::Store;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = Config::from_args(std::env::args().skip(1))?;

    if cfg.mcp {
        // T37-4: stdio MCP mode. Log a warning only when --port was explicitly
        // supplied, since the TCP listener will not be started.
        if cfg.port_explicit {
            eprintln!("flow-server: --mcp mode active; --port is ignored");
        }

        let store = Arc::new(Store::open(&cfg.data_dir).await?);

        // Seed and restore gates identically to HTTP path so the board state
        // is consistent regardless of which transport is used.
        if let Some(path) = &cfg.roadmap_path {
            match tokio::fs::read_to_string(path).await {
                Ok(md) => {
                    let n = store.ingest_roadmap(&md).await?;
                    eprintln!(
                        "flow-server ingested {n} roadmap item(s) from {}",
                        path.display()
                    );
                }
                Err(e) => eprintln!(
                    "flow-server: no roadmap ingested ({}: {e}); starting empty",
                    path.display()
                ),
            }
        }
        store.restore_gates().await;

        run_stdio(store).await?;
        return Ok(());
    }

    // --- HTTP server path (unchanged) ---

    let token = Token::load_or_create(&cfg.token_path).await?;
    let store = Arc::new(Store::open(&cfg.data_dir).await?);

    // Seed the board from the roadmap if one was given and it reads; an absent or
    // unreadable path degrades gracefully to an empty board (logged, not fatal).
    if let Some(path) = &cfg.roadmap_path {
        match tokio::fs::read_to_string(path).await {
            Ok(md) => {
                let n = store.ingest_roadmap(&md).await?;
                eprintln!(
                    "flow-server ingested {n} roadmap item(s) from {}",
                    path.display()
                );
            }
            Err(e) => eprintln!(
                "flow-server: no roadmap ingested ({}: {e}); starting empty",
                path.display()
            ),
        }
    }

    // Restore gate state from .flow/gates.json AFTER ingest_roadmap, because
    // upsert_item resets every item's gate to Go (WaitGate default). This must
    // run last in the startup sequence. Infallible: missing or malformed file
    // leaves all gates at Go and logs a warning. (EARS-G36-02, EARS-G36-07)
    store.restore_gates().await;

    let router = build_router(store, token, cfg.static_dir.clone());

    let addr = SocketAddr::new(cfg.host, cfg.port);
    let listener = tokio::net::TcpListener::bind(addr).await?;
    eprintln!(
        "flow-server listening on http://{} (token: {})",
        listener.local_addr()?,
        cfg.token_path.display()
    );
    axum::serve(listener, router).await?;
    Ok(())
}

/// T37-3: Newline-delimited stdio JSON-RPC loop.
///
/// Reads one JSON-RPC request per line from stdin, dispatches it through
/// `mcp::dispatch` (the same logic used by the HTTP `/mcp` endpoint), and
/// writes a single newline-terminated JSON-RPC response to stdout.
///
/// On EOF (stdin closed): exits the loop and returns `Ok(())`. The process
/// exits with code 0. On an unparseable line: writes a JSON-RPC -32700 parse
/// error response and continues reading.
async fn run_stdio(store: Arc<Store>) -> Result<(), Box<dyn std::error::Error>> {
    use flow_server::api::AppState;
    use tokio::io::{AsyncBufReadExt, AsyncWriteExt};

    // A dummy token is used because stdio mode has no HTTP auth layer —
    // the token field is never read in this path.
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
        let resp = mcp::dispatch(&state, req).await;
        let mut out = tokio::io::stdout();
        out.write_all(format!("{resp}\n").as_bytes()).await?;
        out.flush().await?;
    }
    Ok(())
}
