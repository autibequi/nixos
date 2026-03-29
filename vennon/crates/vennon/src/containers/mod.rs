pub mod ide;

const IDE_ENGINES: &[&str] = &["claude", "opencode", "cursor"];

/// Check if a name is an IDE container.
pub fn is_ide(name: &str) -> bool {
    IDE_ENGINES.contains(&name)
}

/// Translate YAA_TARGET_DIR (host path) to a container path.
/// Checks projects → host → home mounts in order.
fn resolve_target_path() -> String {
    let target = std::env::var("YAA_TARGET_DIR").unwrap_or_default();
    let projects = std::env::var("YAA_PROJECTS_DIR").unwrap_or_default();
    let host_dir = std::env::var("YAA_HOST_DIR").unwrap_or_default();
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());

    if target.is_empty() {
        return "/workspace/projects".into();
    }

    // ~/projects/... → /workspace/projects/...
    if !projects.is_empty() && target.starts_with(&projects) {
        let relative = &target[projects.len()..];
        return format!("/workspace/projects{relative}");
    }

    // ~/nixos/... → /workspace/host/...
    if !host_dir.is_empty() && target.starts_with(&host_dir) {
        let relative = &target[host_dir.len()..];
        return format!("/workspace/host{relative}");
    }

    // ~/anything → /workspace/home/anything
    if target.starts_with(&home) {
        let relative = &target[home.len()..];
        return format!("/workspace/home{relative}");
    }

    "/workspace/projects".into()
}

/// Create symlink /workspace/target → resolved path, then return the setup command prefix.
fn setup_target() -> String {
    let resolved = resolve_target_path();
    format!("ln -sfn {resolved} /workspace/target && cd /workspace/target")
}

/// Build the exec command for starting an IDE session.
pub fn start_cmd(name: &str) -> String {
    let setup = setup_target();
    let model_flag = std::env::var("YAA_MODEL")
        .ok()
        .filter(|s| !s.is_empty())
        .map(|m| format!(" --model {m}"))
        .unwrap_or_default();

    let resume_raw = std::env::var("YAA_RESUME").ok().filter(|s| !s.is_empty());

    match name {
        "claude" => {
            let mut cmd = format!("{setup} && exec claude");
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
            let mut cmd = format!(
                "cp /workspace/self/scripts/opencode-agents.md /workspace/target/AGENTS.md 2>/dev/null; {setup} && exec opencode"
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
            let mut cmd = format!(
                "cp /workspace/self/scripts/cursor-agents.md /workspace/target/AGENTS.md 2>/dev/null; {setup} && exec cursor-agent --force"
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
        _ => format!("{setup} && exec bash"),
    }
}

/// Build the shell command (zsh with fallback to bash).
pub fn shell_cmd() -> String {
    let setup = setup_target();
    format!("{setup} && exec zsh || exec bash")
}
