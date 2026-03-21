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
    pub fn danger_flag(&self) -> &'static str {
        match self {
            Engine::Claude => " --permission-mode bypassPermissions",
            Engine::Cursor => " --force",
            Engine::OpenCode => "",
        }
    }

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
