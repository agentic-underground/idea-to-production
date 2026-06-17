//! Bearer-token auth. The web UI's HTTP/WS gate was removed in roadmap #39, so
//! the token is no longer presented over any transport and no token file is
//! loaded — `main` runs the stdio MCP loop with `Token::new("stdio-noop")`. The
//! `Token` type is retained only as a reserved value: `AppState` carries it as a
//! never-read field for back-compat, and `matches`/`from_bearer_header` are kept
//! against a future re-introduction of an authenticated transport.

use std::sync::Arc;

/// The shared bearer token.
#[derive(Debug, Clone)]
pub struct Token(Arc<String>);

impl Token {
    /// Wrap a raw token string.
    pub fn new(raw: impl Into<String>) -> Self {
        Token(Arc::new(raw.into()))
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
}
