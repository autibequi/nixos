//! `Engine` enum — supported AI agent backends (Claude, Cursor, OpenCode).

use std::fmt;
use std::str::FromStr;

use crate::error::ZionError;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Engine {
    Claude,
    Cursor,
    OpenCode,
}

impl Engine {
    /// Danger flag for the engine's CLI.
    #[must_use]
    pub fn danger_flag(&self) -> &'static str {
        match self {
            Engine::Claude => " --permission-mode bypassPermissions",
            Engine::Cursor => " --force",
            Engine::OpenCode => "",
        }
    }

    #[must_use]
    pub fn as_str(&self) -> &'static str {
        match self {
            Engine::Claude => "claude",
            Engine::Cursor => "cursor",
            Engine::OpenCode => "opencode",
        }
    }
}

impl fmt::Display for Engine {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for Engine {
    type Err = ZionError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "claude" => Ok(Engine::Claude),
            "cursor" => Ok(Engine::Cursor),
            "opencode" | "oc" => Ok(Engine::OpenCode),
            _ => Err(ZionError::InvalidEngine(s.to_string())),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_valid_engines() {
        assert_eq!("claude".parse::<Engine>().unwrap(), Engine::Claude);
        assert_eq!("cursor".parse::<Engine>().unwrap(), Engine::Cursor);
        assert_eq!("opencode".parse::<Engine>().unwrap(), Engine::OpenCode);
        assert_eq!("oc".parse::<Engine>().unwrap(), Engine::OpenCode);
    }

    #[test]
    fn parse_case_insensitive() {
        assert_eq!("CLAUDE".parse::<Engine>().unwrap(), Engine::Claude);
        assert_eq!("Cursor".parse::<Engine>().unwrap(), Engine::Cursor);
        assert_eq!("OpenCode".parse::<Engine>().unwrap(), Engine::OpenCode);
    }

    #[test]
    fn parse_invalid_engine() {
        assert!("vim".parse::<Engine>().is_err());
        assert!("".parse::<Engine>().is_err());
        assert!("claud".parse::<Engine>().is_err());
    }

    #[test]
    fn display_roundtrip() {
        for engine in [Engine::Claude, Engine::Cursor, Engine::OpenCode] {
            let s = engine.to_string();
            assert_eq!(s.parse::<Engine>().unwrap(), engine);
        }
    }

    #[test]
    fn danger_flags() {
        assert!(Engine::Claude.danger_flag().contains("bypassPermissions"));
        assert!(Engine::Cursor.danger_flag().contains("--force"));
        assert!(Engine::OpenCode.danger_flag().is_empty());
    }
}
