pub mod ide;

const IDE_ENGINES: &[&str] = &["claude", "opencode", "cursor"];

/// Check if a name is an IDE container.
pub fn is_ide(name: &str) -> bool {
    IDE_ENGINES.contains(&name)
}

/// Build the exec command for starting an IDE session.
/// Target dir is bind-mounted at /workspace/target by compose.
pub fn start_cmd(name: &str) -> String {
    let model_flag = std::env::var("YAA_MODEL")
        .ok()
        .filter(|s| !s.is_empty())
        .map(|m| format!(" --model {m}"))
        .unwrap_or_default();

    let resume_raw = std::env::var("YAA_RESUME").ok().filter(|s| !s.is_empty());

    match name {
        "claude" => {
            let mut cmd = "cd /workspace/target && exec claude".to_string();
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
            let mut cmd =
                "cp /workspace/self/scripts/opencode-agents.md /workspace/target/AGENTS.md 2>/dev/null; cd /workspace/target && exec opencode".to_string();
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
            let mut cmd =
                "cp /workspace/self/scripts/cursor-agents.md /workspace/target/AGENTS.md 2>/dev/null; cd /workspace/target && exec cursor-agent --force".to_string();
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
        _ => "cd /workspace/target && exec bash".to_string(),
    }
}

/// Build the shell command (zsh with fallback to bash).
pub fn shell_cmd() -> String {
    "cd /workspace/target && exec zsh || exec bash".to_string()
}
