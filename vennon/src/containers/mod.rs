pub mod claude;

use anyhow::{bail, Result};
use crate::compose::ComposeFile;
use crate::config::VennonConfig;

/// Get the compose template for a named container.
pub fn get_compose(name: &str, config: &VennonConfig) -> Result<ComposeFile> {
    match name {
        "claude" => Ok(claude::compose(config)),
        _ => bail!("unknown container: {name}"),
    }
}

/// Get the command to exec inside the container after start.
pub fn start_cmd(name: &str) -> &'static str {
    match name {
        "claude" => "cd /workspace/target && exec claude --enable-auto-mode",
        _ => "cd /workspace/target && exec bash",
    }
}
