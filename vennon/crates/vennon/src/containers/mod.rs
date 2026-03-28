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

/// Build the exec command for starting an IDE session.
/// Reads YAA_MODEL, YAA_DANGER, YAA_RESUME env vars.
pub fn start_cmd(name: &str) -> String {
    let model_flag = std::env::var("YAA_MODEL")
        .ok()
        .filter(|s| !s.is_empty())
        .map(|m| format!(" --model {m}"))
        .unwrap_or_default();

    let danger = std::env::var("YAA_DANGER").as_deref() == Ok("1");

    let resume_flag = std::env::var("YAA_RESUME")
        .ok()
        .filter(|s| !s.is_empty())
        .map(|id| format!(" --resume {id}"))
        .unwrap_or_default();

    match name {
        "claude" => {
            let mut cmd = "cd /workspace/target && exec claude".to_string();
            if danger {
                cmd.push_str(" --dangerously-skip-permissions");
            }
            cmd.push_str(" --enable-auto-mode");
            cmd.push_str(&model_flag);
            cmd.push_str(&resume_flag);
            cmd
        }
        "opencode" => {
            let mut cmd = "cd /workspace/target && exec opencode".to_string();
            cmd.push_str(&resume_flag);
            cmd
        }
        "cursor" => {
            let mut cmd = format!("cd /workspace/target && exec cursor-agent --force{model_flag}");
            cmd.push_str(&resume_flag);
            cmd
        }
        _ => "cd /workspace/target && exec bash".into(),
    }
}

/// Build the shell command (zsh with fallback to bash).
pub fn shell_cmd() -> &'static str {
    "cd /workspace/target && exec zsh || exec bash"
}
