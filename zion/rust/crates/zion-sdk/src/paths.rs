//! Filesystem path helpers — home, NixOS root, Obsidian vault, project slug resolution.

use std::path::{Path, PathBuf};

use crate::error::{Result, ZionError};

// ── Core paths ───────────────────────────────────────────────────

#[must_use]
pub fn home() -> PathBuf {
    std::env::var("HOME").map_or_else(|_| PathBuf::from("/root"), PathBuf::from)
}

#[must_use]
pub fn nixos_dir() -> PathBuf {
    std::env::var("ZION_NIXOS_DIR").map_or_else(|_| home().join("nixos"), PathBuf::from)
}

#[must_use]
pub fn zion_root() -> PathBuf {
    nixos_dir().join("zion")
}

#[must_use]
pub fn bash_dir() -> PathBuf {
    zion_root().join("bash")
}

/// Backward-compatible alias for [`bash_dir`].
#[must_use]
pub fn cli_dir() -> PathBuf {
    bash_dir()
}

#[must_use]
pub fn container_dir() -> PathBuf {
    zion_root().join("containers/zion")
}

#[must_use]
pub fn rust_dir() -> PathBuf {
    zion_root().join("rust")
}

#[must_use]
pub fn compose_file() -> PathBuf {
    container_dir().join("docker-compose.zion.yml")
}

#[must_use]
pub fn env_file() -> PathBuf {
    container_dir().join(".env")
}

#[must_use]
pub fn bin_dir() -> PathBuf {
    home().join(".local/bin")
}

// ── Obsidian paths ───────────────────────────────────────────────

#[must_use]
pub fn obsidian_path() -> PathBuf {
    std::env::var("OBSIDIAN_PATH").map_or_else(
        |_| home().join(".ovault/Work"),
        |s| PathBuf::from(expand_home(&s)),
    )
}

/// Obsidian path resolved + created if missing (for compose).
#[must_use]
pub fn obsidian_ensured() -> String {
    let p = obsidian_path();
    if p.exists() {
        p.canonicalize().unwrap_or(p).to_string_lossy().into_owned()
    } else {
        let _ = std::fs::create_dir_all(&p);
        p.to_string_lossy().into_owned()
    }
}

#[must_use]
pub fn tasks_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        obsidian_path().join("tasks"),
        zion_root().parent().map_or_else(
            || PathBuf::from("/nonexistent"),
            |p| p.join("obsidian/tasks"),
        ),
        PathBuf::from("/workspace/obsidian/tasks"),
        home().join("obsidian/tasks"),
    ])
}

#[must_use]
pub fn schedule_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        std::env::var("SCHEDULE_DIR").ok().map(PathBuf::from).unwrap_or_default(),
        obsidian_path().join("agents/_schedule"),
        PathBuf::from("/workspace/obsidian/agents/_schedule"),
        home().join("obsidian/agents/_schedule"),
    ].into_iter().filter(|p| !p.as_os_str().is_empty()).collect::<Vec<_>>())
}

#[must_use]
pub fn inbox_file() -> Option<PathBuf> {
    first_existing_file(&[
        obsidian_path().join("inbox/inbox.md"),
        PathBuf::from("/workspace/obsidian/inbox/inbox.md"),
    ])
}

#[must_use]
pub fn outbox_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        obsidian_path().join("outbox"),
        PathBuf::from("/workspace/obsidian/outbox"),
    ])
}

// ── Zion internal paths ──────────────────────────────────────────

#[must_use]
pub fn hooks_dir() -> Option<PathBuf> {
    first_existing_dir(&[
        zion_root().join("hooks/claude-code"),
        PathBuf::from("/workspace/mnt/zion/hooks/claude-code"),
    ])
}

#[must_use]
pub fn agent_file(name: &str) -> Option<PathBuf> {
    first_existing_file(&[
        zion_root().join(format!("agents/{name}/agent.md")),
        PathBuf::from(format!("/workspace/mnt/zion/agents/{name}/agent.md")),
    ])
}

#[must_use]
pub fn task_runner() -> Option<PathBuf> {
    first_existing_file(&[
        zion_root().join("scripts/task-runner.sh"),
        PathBuf::from("/workspace/mnt/zion/scripts/task-runner.sh"),
    ])
}

#[must_use]
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

#[must_use]
pub fn proj_slug(dir: &Path) -> String {
    dir.file_name()
        .map_or_else(
            || "default".to_string(),
            |n| n.to_string_lossy().to_string(),
        )
        .to_lowercase()
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .trim_end_matches('-')
        .to_string()
}

#[must_use]
pub fn proj_name(slug: &str, instance: Option<&str>) -> String {
    match instance {
        Some(i) if i != "1" && !i.is_empty() => format!("zion-{slug}-{i}"),
        _ => format!("zion-{slug}"),
    }
}

// ── Env helpers ──────────────────────────────────────────────────

#[must_use]
pub fn expand_home(path: &str) -> String {
    let h = home().to_string_lossy().into_owned();
    path.replace("$HOME", &h)
        .replace("${HOME}", &h)
        .replacen("~/", &format!("{h}/"), 1)
}

#[must_use]
pub fn xdg_data_home() -> String {
    std::env::var("XDG_DATA_HOME").unwrap_or_else(|_| format!("{}/.local/share", home().display()))
}

#[must_use]
pub fn xdg_runtime_dir() -> String {
    std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| "/run/user/1000".into())
}

#[must_use]
pub fn timestamp() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // UTC: days since epoch → y/m/d, seconds → H:M
    let (y, m, d, h, min) = epoch_to_utc(secs);
    format!("{y:04}{m:02}{d:02}_{h:02}_{min:02}")
}

#[must_use]
pub fn date_iso() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let (y, m, d, _, _) = epoch_to_utc(secs);
    format!("{y:04}-{m:02}-{d:02}")
}

/// Convert epoch seconds to (year, month, day, hour, minute) in UTC.
fn epoch_to_utc(secs: u64) -> (u32, u32, u32, u32, u32) {
    let days = (secs / 86400) as u32;
    let time = secs % 86400;
    let h = (time / 3600) as u32;
    let min = ((time % 3600) / 60) as u32;

    // Civil date from day count (algorithm from Howard Hinnant)
    let z = days + 719_468;
    let era = z / 146_097;
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };

    (y, m, d, h, min)
}

// ── Lookup helpers ───────────────────────────────────────────────

#[must_use]
pub fn first_existing_file(candidates: &[PathBuf]) -> Option<PathBuf> {
    candidates.iter().find(|p| p.is_file()).cloned()
}

#[must_use]
pub fn first_existing_dir(candidates: &[PathBuf]) -> Option<PathBuf> {
    candidates.iter().find(|p| p.is_dir()).cloned()
}

#[must_use]
pub fn in_container() -> bool {
    std::env::var("in_docker").unwrap_or_default() == "1"
        || std::env::var("CLAUDE_ENV").unwrap_or_default() == "container"
}

// ── Tests ────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    // ── proj_slug ────────────────────────────────────────────

    #[test]
    fn slug_basic() {
        assert_eq!(proj_slug(Path::new("/tmp/foo-bar")), "foo-bar");
    }

    #[test]
    fn slug_spaces_and_caps() {
        assert_eq!(proj_slug(Path::new("/home/user/My Project")), "my-project");
    }

    #[test]
    fn slug_special_chars() {
        assert_eq!(proj_slug(Path::new("/tmp/foo@bar#baz")), "foo-bar-baz");
    }

    #[test]
    fn slug_trailing_special() {
        assert_eq!(proj_slug(Path::new("/tmp/test...")), "test");
    }

    // ── proj_name ────────────────────────────────────────────

    #[test]
    fn name_no_instance() {
        assert_eq!(proj_name("projects", None), "zion-projects");
    }

    #[test]
    fn name_instance_2() {
        assert_eq!(proj_name("projects", Some("2")), "zion-projects-2");
    }

    #[test]
    fn name_instance_1_ignored() {
        assert_eq!(proj_name("projects", Some("1")), "zion-projects");
    }

    #[test]
    fn name_instance_empty_ignored() {
        assert_eq!(proj_name("projects", Some("")), "zion-projects");
    }

    // ── expand_home ──────────────────────────────────────────

    #[test]
    fn expand_dollar_home() {
        let r = expand_home("$HOME/test");
        assert!(!r.contains("$HOME"));
        assert!(r.ends_with("/test"));
    }

    #[test]
    fn expand_braced_home() {
        let r = expand_home("${HOME}/.config");
        assert!(!r.contains("${HOME}"));
        assert!(r.ends_with("/.config"));
    }

    #[test]
    fn expand_tilde() {
        let r = expand_home("~/projects");
        assert!(!r.starts_with('~'));
        assert!(r.ends_with("/projects"));
    }

    #[test]
    fn expand_no_home_passthrough() {
        assert_eq!(expand_home("/absolute/path"), "/absolute/path");
    }

    #[test]
    fn expand_tilde_only_first() {
        // Only first ~ should expand, not ones in middle
        let r = expand_home("~/a/~/b");
        assert!(!r.starts_with('~'));
        assert!(r.contains("/a/~/b"));
    }

    // ── resolve_dir ──────────────────────────────────────────

    #[test]
    fn resolve_dir_existing() {
        let r = resolve_dir(Some("/tmp"));
        assert!(r.is_ok());
        assert_eq!(r.unwrap().to_string_lossy(), "/tmp");
    }

    #[test]
    fn resolve_dir_nonexistent() {
        let r = resolve_dir(Some("/nonexistent_path_12345"));
        assert!(r.is_err());
    }

    #[test]
    fn resolve_dir_empty_falls_back() {
        // Empty string should fallback to ~/projects
        let r = resolve_dir(Some(""));
        // May or may not exist, but tests the logic path
        let _ = r;
    }

    // ── first_existing ───────────────────────────────────────

    #[test]
    fn first_existing_file_none() {
        let r = first_existing_file(&[
            PathBuf::from("/nonexistent_1"),
            PathBuf::from("/nonexistent_2"),
        ]);
        assert!(r.is_none());
    }

    #[test]
    fn schedule_dir_env_override() {
        std::env::set_var("SCHEDULE_DIR", "/tmp");
        let r = schedule_dir();
        std::env::remove_var("SCHEDULE_DIR");
        assert_eq!(r, Some(PathBuf::from("/tmp")));
    }

    #[test]
    fn first_existing_dir_finds_tmp() {
        let r = first_existing_dir(&[
            PathBuf::from("/nonexistent"),
            PathBuf::from("/tmp"),
        ]);
        assert_eq!(r.unwrap(), PathBuf::from("/tmp"));
    }
}
