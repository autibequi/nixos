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

/// Translate a host path to the container path.
/// ~/anything → /workspace/home/anything (because ~ is mounted at /workspace/home)
fn container_workdir() -> String {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let target = std::env::var("YAA_TARGET_DIR").unwrap_or_default();

    if target.is_empty() {
        return "/workspace/home".into();
    }

    // If target starts with $HOME, translate to /workspace/home/...
    if target.starts_with(&home) {
        let relative = &target[home.len()..];
        format!("/workspace/home{relative}")
    } else {
        // Fallback: might not be accessible inside container
        "/workspace/home".into()
    }
}

/// Build the exec command for starting an IDE session.
pub fn start_cmd(name: &str) -> String {
    let workdir = container_workdir();
    let model_flag = std::env::var("YAA_MODEL")
        .ok()
        .filter(|s| !s.is_empty())
        .map(|m| format!(" --model {m}"))
        .unwrap_or_default();

    let danger = std::env::var("YAA_DANGER").as_deref() == Ok("1");
    let resume_raw = std::env::var("YAA_RESUME").ok().filter(|s| !s.is_empty());

    match name {
        "claude" => {
            let mut cmd = format!("cd {workdir} && exec claude");
            if danger {
                cmd.push_str(" --dangerously-skip-permissions");
            }
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
            let mut cmd = format!("cd {workdir} && exec opencode");
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
            let mut cmd = format!("cd {workdir} && exec cursor-agent --force");
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
