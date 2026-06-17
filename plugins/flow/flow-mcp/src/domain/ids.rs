//! Stable slug [`ItemId`] — parse-don't-validate. Once you hold an `ItemId`,
//! its invariants (non-empty, `[a-z0-9-]`, well-formed hyphens, bounded length)
//! are guaranteed; no downstream code re-checks them.

use std::fmt;

use serde::{Deserialize, Serialize};

use super::error::IdError;

/// Maximum length of a slug id, in characters.
pub const MAX_ID_LEN: usize = 64;

/// A validated, stable slug identifier for a flow item.
///
/// The display order number (`[N]`) is *not* the identity — this slug is, so
/// reordering, board moves, and re-sequencing never break edges or telemetry.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize)]
#[serde(transparent)]
pub struct ItemId(String);

impl ItemId {
    /// Parse a candidate slug into an [`ItemId`], or fail with a typed [`IdError`].
    ///
    /// Rules: non-empty, at most [`MAX_ID_LEN`] characters, only `[a-z0-9-]`,
    /// no leading/trailing `-`, and no `--`.
    pub fn new(candidate: &str) -> Result<Self, IdError> {
        if candidate.is_empty() {
            return Err(IdError::Empty);
        }
        let got = candidate.chars().count();
        if got > MAX_ID_LEN {
            return Err(IdError::TooLong {
                max: MAX_ID_LEN,
                got,
            });
        }
        for ch in candidate.chars() {
            let ok = ch.is_ascii_lowercase() || ch.is_ascii_digit() || ch == '-';
            if !ok {
                return Err(IdError::InvalidChar { ch });
            }
        }
        if candidate.starts_with('-') || candidate.ends_with('-') || candidate.contains("--") {
            return Err(IdError::MalformedHyphen);
        }
        Ok(ItemId(candidate.to_string()))
    }

    /// Borrow the underlying slug string.
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for ItemId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

impl<'de> Deserialize<'de> for ItemId {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let raw = String::deserialize(deserializer)?;
        ItemId::new(&raw).map_err(serde::de::Error::custom)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    #[test]
    fn accepts_a_simple_slug() {
        let id = ItemId::new("flow-server").expect("valid slug");
        assert_eq!(id.as_str(), "flow-server");
        assert_eq!(id.to_string(), "flow-server");
    }

    #[test]
    fn accepts_digits_and_single_token() {
        assert!(ItemId::new("item15").is_ok());
        assert!(ItemId::new("a").is_ok());
        assert!(ItemId::new("a1-b2-c3").is_ok());
    }

    #[test]
    fn rejects_empty() {
        assert_eq!(ItemId::new(""), Err(IdError::Empty));
    }

    #[test]
    fn rejects_too_long() {
        let long = "a".repeat(MAX_ID_LEN + 1);
        assert_eq!(
            ItemId::new(&long),
            Err(IdError::TooLong {
                max: MAX_ID_LEN,
                got: MAX_ID_LEN + 1
            })
        );
    }

    #[test]
    fn accepts_exactly_max_len() {
        let at_max = "a".repeat(MAX_ID_LEN);
        assert!(ItemId::new(&at_max).is_ok());
    }

    #[test]
    fn rejects_uppercase() {
        assert_eq!(ItemId::new("Flow"), Err(IdError::InvalidChar { ch: 'F' }));
    }

    #[test]
    fn rejects_space_and_underscore() {
        assert_eq!(
            ItemId::new("flow server"),
            Err(IdError::InvalidChar { ch: ' ' })
        );
        assert_eq!(
            ItemId::new("flow_server"),
            Err(IdError::InvalidChar { ch: '_' })
        );
    }

    #[test]
    fn rejects_leading_trailing_and_double_hyphen() {
        assert_eq!(ItemId::new("-flow"), Err(IdError::MalformedHyphen));
        assert_eq!(ItemId::new("flow-"), Err(IdError::MalformedHyphen));
        assert_eq!(ItemId::new("flow--server"), Err(IdError::MalformedHyphen));
    }

    #[test]
    fn serde_round_trips_valid() {
        let id = ItemId::new("flow-server").unwrap();
        let json = serde_json::to_string(&id).unwrap();
        assert_eq!(json, "\"flow-server\"");
        let back: ItemId = serde_json::from_str(&json).unwrap();
        assert_eq!(back, id);
    }

    #[test]
    fn serde_rejects_invalid_slug_on_deserialize() {
        // Valid JSON string, but not a valid slug: ItemId::new rejects it.
        let err = serde_json::from_str::<ItemId>("\"Flow Server\"");
        assert!(err.is_err());
    }

    #[test]
    fn serde_rejects_non_string_on_deserialize() {
        // Not a string at all: String::deserialize itself fails (the `?` path).
        let err = serde_json::from_str::<ItemId>("123");
        assert!(err.is_err());
    }

    proptest! {
        #[test]
        fn never_panics_on_any_input(s in ".*") {
            let _ = ItemId::new(&s);
        }

        #[test]
        fn valid_slugs_round_trip(s in "[a-z0-9]([a-z0-9]|-[a-z0-9]){0,30}") {
            let id = ItemId::new(&s).expect("generator yields valid slugs");
            prop_assert_eq!(id.as_str(), s.as_str());
        }
    }
}
