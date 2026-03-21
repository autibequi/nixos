use std::path::{Path, PathBuf};

use crate::error::{Result, ZionError};

// ── Core paths ───────────────────────────────────────────────────

pub fn home() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/root"))
}

pub fn nixos_dir() -> PathBuf {
    std::env::var("ZION_NIXOS_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| home().join("nixos"))
}

pub fn zion_root() -> PathBuf {
    nixos_dir().join("zion")
}

pub fn cli_dir() -> PathBuf {
    zion_root().join("cli")
}

pub fn clirust_dir() -> PathBuf {
    zion_root().join("clirust")
}

pub fn compose_file() -> PathBuf {
    cli_dir().join("docker-compose.zion.yml")
}

pub fn env_file() -> PathBuf {
    cli_dir().join(".env")
}

pub fn bin_dir() -> PathBuf {
    home().join(".local/bin")
}

// ── Obsidian paths ───────────────────────────────────────────────

pub fn obsidian_path() -> PathBuf {
    std::env::var("OBSIDIAN_PATH")
        .map(|s| PathBuf::from(expand_home(&s)))
        .unwrap_or_else(|_| home().join(".ovault/Work"))
}

/// Obsidian path resolved + created if missing (for compose).
pub fn obsidian_ensured() -> String {
    let p = obsidian_path();
    if p.exists() {
        p.canonicalize()
            .unwrap_or(p.clone())
            .to_string_lossy()
            .to_string()
    } else {
        let _ = std::fs::create_dir_all(&p);
        p.to_string_lossy().to_string()
    }
}

pub fn tasks_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        obsidian_path().join("tasks"),
        PathBuf::from("/workspace/obsidian/tasks"),
        home().join("obsidian/tasks"),
    ])
}

pub fn inbox_file() -> Option<PathBuf> {
    first_existing_file(&[
        obsidian_path().join("inbox/inbox.md"),
        PathBuf::from("/workspace/obsidian/inbox/inbox.md"),
    ])
}

pub fn outbox_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        obsidian_path().join("outbox"),
        PathBuf::from("/workspace/obsidian/outbox"),
    ])
}

// ── Zion internal paths ──────────────────────────────────────────

pub fn hooks_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        zion_root().join("hooks/claude-code"),
        PathBuf::from("/workspace/mnt/zion/hooks/claude-code"),
    ])
}

pub fn agent_file(name: &str) -> Option<PathBuf> {
    first_existing_file(&[
        zion_root().join(format!("agents/{name}/agent.md")),
        PathBuf::from(format!("/workspace/mnt/zion/agents/{name}/agent.md")),
    ])
}

pub fn task_runner() -> Option<PathBuf> {
    first_existing_file(&[
        zion_root().join("scripts/task-runner.sh"),
        PathBuf::from("/workspace/mnt/zion/scripts/task-runner.sh"),
    ])
}

pub fn usage_script() -> Option<PathBuf> {
    first_existing_file(&[
        home().join(".config/waybar/claude-oauth-usage.sh"),
        nixos_dir().join("stow/.config/waybar/claude-oauth-usage.sh"),
        PathBuf::from("/workspace/mnt/stow/.config/waybar/claude-oauth-usage.sh"),
    ])
}

// ── Project resolution ───────────────────────────────────────────

pub fn resolve_dir(dir: Option<&str>) -> Result<PathBuf> {
    let path = match dir {
        Some(d) if !d.is_empty() => PathBuf::from(expand_home(d)),
        _ => home().join("projects"),
    };
    path.canonicalize()
        .map_err(|_| ZionError::DirNotFound(path.display().to_string()))
}

pub fn proj_slug(dir: &Path) -> String {
    dir.file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "default".to_string())
        .to_lowercase()
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .trim_end_matches('-')
        .to_string()
}

pub fn proj_name(slug: &str, instance: Option<&str>) -> String {
    match instance {
        Some(i) if i != "1" && !i.is_empty() => format!("zion-{slug}-{i}"),
        _ => format!("zion-{slug}"),
    }
}

// ── Env helpers ──────────────────────────────────────────────────

pub fn expand_home(path: &str) -> String {
    let h = home().to_string_lossy().to_string();
    path.replace("$HOME", &h)
        .replace("${HOME}", &h)
        .replacen("~/", &format!("{h}/"), 1)
}

pub fn xdg_data_home() -> String {
    std::env::var("XDG_DATA_HOME")
        .unwrap_or_else(|_| format!("{}/.local/share", home().display()))
}

pub fn xdg_runtime_dir() -> String {
    std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/run/user/1000".into())
}

pub fn timestamp() -> String {
    std::process::Command::new("date")
        .arg("+%Y%m%d_%H_%M")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "00000000_00_00".to_string())
}

pub fn date_iso() -> String {
    std::process::Command::new("date")
        .arg("+%Y-%m-%d")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_default()
}

// ── Lookup helpers ───────────────────────────────────────────────

pub fn first_existing_file(candidates: &[PathBuf]) -> Option<PathBuf> {
    candidates.iter().find(|p| p.is_file()).cloned()
}

pub fn first_existing_dir(candidates: &[PathBuf]) -> Option<PathBuf> {
    candidates.iter().find(|p| p.is_dir()).cloned()
}

pub fn in_container() -> bool {
    std::env::var("in_docker").unwrap_or_default() == "1"
        || std::env::var("CLAUDE_ENV").unwrap_or_default() == "container"
}

// ── Tests ────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_proj_slug() {
        assert_eq!(proj_slug(Path::new("/home/user/My Project")), "my-project");
        assert_eq!(proj_slug(Path::new("/tmp/foo-bar")), "foo-bar");
    }

    #[test]
    fn test_proj_name() {
        assert_eq!(proj_name("projects", None), "zion-projects");
        assert_eq!(proj_name("projects", Some("2")), "zion-projects-2");
        assert_eq!(proj_name("projects", Some("1")), "zion-projects");
    }

    #[test]
    fn test_expand_home() {
        // Can't test with real HOME, but test the replacement logic
        let result = expand_home("$HOME/test");
        assert!(!result.contains("$HOME"));
    }
}
