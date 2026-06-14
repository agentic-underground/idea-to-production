//! Flow server binary: parse config, load/create the token, open the store,
//! build the router, bind, and serve.

use std::net::SocketAddr;
use std::sync::Arc;

use flow_server::api::build_router;
use flow_server::auth::Token;
use flow_server::config::Config;
use flow_server::store::Store;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cfg = Config::from_args(std::env::args().skip(1))?;

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
