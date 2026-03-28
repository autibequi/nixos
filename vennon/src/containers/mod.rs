pub mod ide;

use anyhow::{bail, Result};
use crate::compose::ComposeFile;
use crate::config::VennonConfig;

const IDE_ENGINES: &[&str] = &["claude", "opencode", "cursor"];

/// Check if a name is an IDE container.
pub fn is_ide(name: &str) -> bool {
    IDE_ENGINES.contains(&name)
}

/// Get the compose template for an IDE container.
pub fn get_compose(name: &str, config: &VennonConfig) -> Result<ComposeFile> {
    if is_ide(name) {
        Ok(ide::compose(name, config))
    } else {
        bail!("unknown IDE container: {name}")
    }
}

/// Get the command to exec inside the container after start.
pub fn start_cmd(name: &str) -> &'static str {
    match name {
        "claude" => "cd /workspace/target && exec claude --enable-auto-mode",
        "opencode" => "cd /workspace/target && exec opencode",
        "cursor" => "cd /workspace/target && exec cursor-agent --force",
        _ => "cd /workspace/target && exec bash",
    }
}
