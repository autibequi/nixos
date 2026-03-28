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

/// Target dir is mounted directly at /workspace/target.
fn container_workdir() -> String {
    "/workspace/target".into()
}

/// Build the exec command for starting an IDE session.
pub fn start_cmd(name: &str) -> String {
    let workdir = container_workdir();
    let model_flag = std::env::var("YAA_MODEL")
        .ok()
        .filter(|s| !s.is_empty())
        .map(|m| format!(" --model {m}"))
        .unwrap_or_default();

    let resume_raw = std::env::var("YAA_RESUME").ok().filter(|s| !s.is_empty());

    match name {
        "claude" => {
            let mut cmd = format!("cd {workdir} && exec claude");
            cmd.push_str(" --enable-auto-mode");
            cmd.push_str(&model_flag);
            if let Some(ref id) = resume_raw {
                if id == "continue" {
                    cmd.push_str(" --continue");
                } else {
                    cmd.push_str(&format!(" --resume {id}"));
                }
            }
            cmd
        }
        "opencode" => {
            // Inject AGENTS.md into workdir so opencode reads our context
            let mut cmd = format!(
                "cp /workspace/self/scripts/opencode-agents.md {workdir}/AGENTS.md 2>/dev/null; cd {workdir} && exec opencode"
            );
            if let Some(ref id) = resume_raw {
                if id == "continue" {
                    cmd.push_str(" --continue");
                } else {
                    cmd.push_str(&format!(" --resume {id}"));
                }
            }
            cmd
        }
        "cursor" => {
            // Inject AGENTS.md into workdir so cursor-agent reads our context
            let mut cmd = format!(
                "cp /workspace/self/scripts/cursor-agents.md {workdir}/AGENTS.md 2>/dev/null; cd {workdir} && exec cursor-agent --force"
            );
            cmd.push_str(&model_flag);
            if let Some(ref id) = resume_raw {
                if id == "continue" {
                    cmd.push_str(" --resume");
                } else {
                    cmd.push_str(&format!(" --resume {id}"));
                }
            }
            cmd
        }
        _ => format!("cd {workdir} && exec bash"),
    }
}

/// Build the shell command (zsh with fallback to bash).
pub fn shell_cmd() -> String {
    let workdir = container_workdir();
    format!("cd {workdir} && exec zsh || exec bash")
}
