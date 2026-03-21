use std::path::{Path, PathBuf};

use crate::error::{Result, ZionError};

/// Home directory.
pub fn home() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/root"))
}

/// NixOS repo root ($ZION_NIXOS_DIR or ~/nixos).
pub fn nixos_dir() -> PathBuf {
    std::env::var("ZION_NIXOS_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| home().join("nixos"))
}

/// Zion CLI dir (nixos/zion/cli).
pub fn cli_dir() -> PathBuf {
    nixos_dir().join("zion/cli")
}

/// Docker compose file path.
pub fn compose_file() -> PathBuf {
    cli_dir().join("docker-compose.zion.yml")
}

/// .env file for compose.
pub fn env_file() -> PathBuf {
    cli_dir().join(".env")
}

/// Obsidian vault path.
pub fn obsidian_path() -> PathBuf {
    std::env::var("OBSIDIAN_PATH")
        .map(|s| PathBuf::from(expand_home(&s)))
        .unwrap_or_else(|_| home().join(".ovault/Work"))
}

/// Expand $HOME and ~ in a path string to the actual home directory.
pub fn expand_home(path: &str) -> String {
    let h = home();
    let home_str = h.to_string_lossy();
    path.replace("$HOME", &home_str)
        .replace("${HOME}", &home_str)
        .replacen("~/", &format!("{}/", home_str), 1)
}

/// Resolve and canonicalize a mount directory.
/// Falls back to ~/projects if not specified.
pub fn resolve_dir(dir: Option<&str>) -> Result<PathBuf> {
    let path = match dir {
        Some(d) if !d.is_empty() => PathBuf::from(d),
        _ => home().join("projects"),
    };
    path.canonicalize()
        .map_err(|_| ZionError::DirNotFound(path.display().to_string()))
}

/// Generate a slug from a directory basename (lowercase, alphanumeric + hyphen).
pub fn proj_slug(dir: &Path) -> String {
    let name = dir
        .file_name()
        .map(|n| n.to_string_lossy().to_string())
        .unwrap_or_else(|| "default".to_string());
    name.to_lowercase()
        .chars()
        .map(|c| if c.is_ascii_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .trim_end_matches('-')
        .to_string()
}

/// Project name for compose (zion-<slug>[-<instance>]).
pub fn proj_name(slug: &str, instance: Option<&str>) -> String {
    let mut name = format!("zion-{slug}");
    if let Some(inst) = instance {
        if inst != "1" && !inst.is_empty() {
            name = format!("{name}-{inst}");
        }
    }
    name
}

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
}
