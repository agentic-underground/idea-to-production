//! Flow server library: the pure domain core plus the thin IO adapters (store,
//! auth, api, ws, mcp). The binary (`main.rs`) wires them together.

pub mod api;
pub mod auth;
pub mod config;
pub mod domain;
pub mod history;
pub mod mcp;
pub mod store;
pub mod ws;

// Router-/store-level contract tests run in-crate (a single instrumented test
// binary) so coverage is measured against one library copy rather than being
// fragmented across separate integration-test binaries.
#[cfg(test)]
mod http_contract_intest;
#[cfg(test)]
mod http_surface_intest;
#[cfg(test)]
mod mcp_contract_intest;
#[cfg(test)]
mod mcp_surface_intest;
#[cfg(test)]
mod store_contract_intest;
#[cfg(test)]
mod ws_contract_intest;
