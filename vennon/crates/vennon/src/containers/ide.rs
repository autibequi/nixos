use crate::config::{self, VennonConfig};

/// Set environment variables needed by the IDE docker-compose.yml files.
/// These are interpolated by podman-compose at runtime (${VAR} syntax).
pub fn set_compose_env(config: &VennonConfig) {
    let home = config::home().to_string_lossy().to_string();
    let (uid, gid) = config::user_ids();
    let git = config::git_env();

    std::env::set_var("VENNON_SELF", config.self_path().to_string_lossy().to_string());
    std::env::set_var("VENNON_OBSIDIAN", config.obsidian_path().to_string_lossy().to_string());
    std::env::set_var("VENNON_PROJECTS", config.projects_path().to_string_lossy().to_string());
    std::env::set_var("VENNON_HOST", config.host_path().to_string_lossy().to_string());
    std::env::set_var("VENNON_PATH", config.vennon_path().to_string_lossy().to_string());
    std::env::set_var("VENNON_MEM", &config.settings.memory_limit);
    std::env::set_var("VENNON_UID", uid.to_string());
    std::env::set_var("VENNON_GID", gid.to_string());

    // Git env (read from git config, set for compose interpolation)
    for (k, v) in &git {
        std::env::set_var(k, v);
    }

    // HOME is already set, but ensure it's available
    std::env::set_var("HOME", &home);
}
