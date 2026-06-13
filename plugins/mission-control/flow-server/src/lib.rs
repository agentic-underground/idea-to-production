//! Flow server library: the pure domain core plus the thin IO adapters (store,
//! auth, api, ws, mcp). The binary (`main.rs`) wires them together.

pub mod api;
pub mod auth;
pub mod config;
pub mod domain;
pub mod mcp;
pub mod store;
pub mod ws;
