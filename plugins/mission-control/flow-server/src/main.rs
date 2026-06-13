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
