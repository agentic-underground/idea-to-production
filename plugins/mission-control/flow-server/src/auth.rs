//! Bearer-token auth. The shared token is read from a local file (generated on
//! first run). The web UI's HTTP/WS gate was removed in roadmap #39, so the
//! token is no longer presented over a transport; the type is retained because
//! `AppState` carries it and `main` still loads/creates the token file, keeping
//! the shared-secret on disk for any future re-introduction.

use std::path::Path;
use std::sync::Arc;

/// The shared bearer token.
#[derive(Debug, Clone)]
pub struct Token(Arc<String>);

impl Token {
    /// Wrap a raw token string.
    pub fn new(raw: impl Into<String>) -> Self {
        Token(Arc::new(raw.into()))
    }

    /// Load the token from `path`, generating and persisting a fresh one if the
    /// file is absent.
    pub async fn load_or_create(path: &Path) -> std::io::Result<Self> {
        if let Ok(existing) = tokio::fs::read_to_string(path).await {
            let trimmed = existing.trim().to_string();
            if !trimmed.is_empty() {
                return Ok(Token::new(trimmed));
            }
        }
        if let Some(parent) = path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }
        let generated = generate_token();
        tokio::fs::write(path, &generated).await?;
        Ok(Token::new(generated))
    }

    /// Constant-time-ish equality check against a presented credential.
    pub fn matches(&self, presented: &str) -> bool {
        let expected = self.0.as_bytes();
        let got = presented.as_bytes();
        if expected.len() != got.len() {
            return false;
        }
        let mut diff = 0u8;
        for (a, b) in expected.iter().zip(got.iter()) {
            diff |= a ^ b;
        }
        diff == 0
    }

    /// Extract a presented token from an `Authorization: Bearer` header value,
    /// or `None` if the scheme is absent/wrong.
    pub fn from_bearer_header(value: &str) -> Option<&str> {
        value.strip_prefix("Bearer ").map(str::trim)
    }
}

/// Generate a non-cryptographic-but-unguessable token from process + time
/// entropy. (A network-reachable surface; documented as a shared secret, not a
/// crypto key — sufficient for a LAN governance UI.)
fn generate_token() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    let pid = std::process::id();
    format!("{nanos:x}{pid:x}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn matches_only_exact_token() {
        let t = Token::new("secret");
        assert!(t.matches("secret"));
        assert!(!t.matches("Secret"));
        assert!(!t.matches("secre"));
        assert!(!t.matches("secrets"));
        assert!(!t.matches(""));
    }

    #[test]
    fn parses_bearer_header() {
        assert_eq!(Token::from_bearer_header("Bearer abc"), Some("abc"));
        assert_eq!(Token::from_bearer_header("Bearer  abc "), Some("abc"));
        assert_eq!(Token::from_bearer_header("Basic abc"), None);
        assert_eq!(Token::from_bearer_header("abc"), None);
    }

    #[tokio::test]
    async fn load_or_create_generates_then_reuses() {
        let dir = std::env::temp_dir().join(format!("flow-auth-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        let path = dir.join("token");

        let first = Token::load_or_create(&path).await.unwrap();
        // File now exists and is non-empty.
        let on_disk = std::fs::read_to_string(&path).unwrap();
        assert!(!on_disk.trim().is_empty());
        // Re-loading yields the same token.
        let second = Token::load_or_create(&path).await.unwrap();
        assert!(second.matches(first.0.as_str()));
    }

    #[tokio::test]
    async fn load_or_create_errors_when_path_has_no_parent_and_is_unwritable() {
        // The empty path has no parent (so create_dir_all is skipped) and cannot
        // be written, so the write `?` propagates an error.
        let err = Token::load_or_create(std::path::Path::new("")).await;
        assert!(err.is_err(), "writing the empty path must fail");
    }

    #[tokio::test]
    async fn load_or_create_errors_when_parent_dir_cannot_be_created() {
        // Place the token under a path whose ancestor is an existing *file*, so
        // create_dir_all fails and the `?` propagates.
        let base = std::env::temp_dir().join(format!("flow-auth-file-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&base);
        let _ = std::fs::remove_file(&base);
        std::fs::create_dir_all(&base).unwrap();
        let file = base.join("not-a-dir");
        std::fs::write(&file, "x").unwrap();
        // `file` is a regular file; treating it as a directory must fail.
        let path = file.join("sub").join("token");
        let err = Token::load_or_create(&path).await;
        assert!(err.is_err(), "create_dir_all under a file must fail");
    }

    #[tokio::test]
    async fn load_or_create_ignores_empty_file() {
        let dir = std::env::temp_dir().join(format!("flow-auth-empty-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("token");
        std::fs::write(&path, "   \n").unwrap();
        let t = Token::load_or_create(&path).await.unwrap();
        // A fresh non-empty token replaced the blank file.
        let on_disk = std::fs::read_to_string(&path).unwrap();
        assert!(!on_disk.trim().is_empty());
        assert!(t.matches(on_disk.trim()));
    }
}
