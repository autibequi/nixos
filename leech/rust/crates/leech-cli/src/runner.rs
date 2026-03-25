//! Service runner — path resolution and config for Docker Compose orchestration.

use crate::paths;
use std::path::PathBuf;

/// Resolve a service name or alias to the canonical name.
pub fn resolve_alias(name: &str) -> &str {
    match name {
        "mono" => "monolito",
        "bo" => "bo-container",
        "front" | "fs" => "front-student",
        "mw" => "monolito-worker",
        "rp" | "proxy" => "reverseproxy",
        other => other,
    }
}

pub const KNOWN_SERVICES: &[&str] = &[
    "monolito",
    "monolito-worker",
    "bo-container",
    "front-student",
    "reverseproxy",
];

/// Source directory for a service (from env var or default).
pub fn service_src_dir(svc: &str) -> PathBuf {
    if svc == "reverseproxy" {
        return docker_base_dir().join("reverseproxy");
    }
    let var = match svc {
        "monolito" | "monolito-worker" => "MONOLITO_DIR",
        "bo-container" => "BO_CONTAINER_DIR",
        "front-student" => "FRONT_STUDENT_DIR",
        _ => "",
    };
    if !var.is_empty() {
        if let Ok(val) = std::env::var(var) {
            if !val.is_empty() {
                return PathBuf::from(val);
            }
        }
    }
    let base = match svc {
        "monolito-worker" => "monolito",
        other => other,
    };
    paths::home().join("projects/estrategia").join(base)
}

/// Base dir for all Docker configs: `<nixos>/leech/docker/`.
fn docker_base_dir() -> PathBuf {
    paths::nixos_dir().join("leech/docker")
}

/// Docker Compose config directory for a service.
pub fn service_config_dir(svc: &str) -> PathBuf {
    let canon = if svc == "monolito-worker" {
        "monolito"
    } else {
        svc
    };
    docker_base_dir().join(canon)
}

/// Main compose file path.
pub fn compose_file(svc: &str) -> PathBuf {
    let dir = service_config_dir(svc);
    if svc == "monolito-worker" {
        dir.join("docker-compose.worker.yml")
    } else {
        dir.join("docker-compose.yml")
    }
}

/// Debug overlay compose file path.
pub fn debug_compose_file(svc: &str) -> PathBuf {
    let dir = service_config_dir(svc);
    if svc == "monolito-worker" {
        dir.join("docker-compose.debug.worker.yml")
    } else {
        dir.join("docker-compose.debug.yml")
    }
}

/// Deps compose file path.
pub fn deps_compose_file(svc: &str) -> PathBuf {
    service_config_dir(svc).join("docker-compose.deps.yml")
}

/// Env file path for a given env.
pub fn env_file(svc: &str, env: &str) -> PathBuf {
    service_config_dir(svc).join("env").join(format!("{env}.env"))
}

/// Docker Compose project name (with optional worktree suffix).
pub fn project_name(svc: &str, worktree: Option<&str>) -> String {
    match worktree {
        Some(wt) => {
            let safe = wt.to_lowercase().replace('/', "-");
            format!("leech-dk-{svc}-wt-{safe}")
        }
        None => format!("leech-dk-{svc}"),
    }
}

/// Log directory for a service.
pub fn log_dir(svc: &str, worktree: Option<&str>) -> PathBuf {
    let base = if std::path::Path::new("/workspace/logs/docker").exists() {
        PathBuf::from("/workspace/logs/docker")
    } else {
        paths::home().join(".local/share/leech/logs/dockerized")
    };
    let dir = base.join(svc);
    match worktree {
        Some(wt) => dir.join(format!("wt-{wt}")),
        None => dir,
    }
}

/// Host ports published by a service (to free before start).
pub fn service_host_ports(svc: &str) -> &'static [u16] {
    match svc {
        "front-student" => &[3005],
        "bo-container" => &[9090],
        "monolito" => &[4004, 2345, 5432, 6379, 4566],
        _ => &[],
    }
}

/// Whether a service is a Node.js project.
pub fn is_node_service(svc: &str) -> bool {
    matches!(svc, "bo-container" | "front-student")
}

/// Resolve a worktree by short name. Returns the worktree path if found.
pub fn resolve_worktree(svc: &str, name: Option<&str>) -> Option<PathBuf> {
    let name = name?;
    let base = service_src_dir(svc);
    if !base.is_dir() {
        return None;
    }
    let out = std::process::Command::new("git")
        .args(["-C", &base.to_string_lossy(), "worktree", "list"])
        .output()
        .ok()?;
    for line in String::from_utf8_lossy(&out.stdout).lines() {
        let path = line.split_whitespace().next()?;
        let leaf = std::path::Path::new(path).file_name()?.to_str()?;
        if leaf == name {
            let p = PathBuf::from(path);
            if p.is_dir() {
                return Some(p);
            }
        }
    }
    None
}

/// Environment variable exports needed for docker compose.
pub fn compose_env_vars(
    svc: &str,
    env: &str,
    src_dir: &std::path::Path,
    vertical: &str,
) -> Vec<(String, String)> {
    let mut vars = Vec::new();

    vars.push((
        "LEECH_NIXOS_DIR".into(),
        paths::nixos_dir().to_string_lossy().into_owned(),
    ));
    vars.push(("APP_ENV".into(), env.into()));

    // APP_ENV_FILE mapping
    let env_file_suffix = match env {
        "sand" => "sandbox",
        "local" => "local",
        "devbox" => "devbox",
        other => other,
    };
    vars.push(("APP_ENV_FILE".into(), env_file_suffix.into()));

    // NPM_SCRIPT_ENV mapping
    let npm_env = match env {
        "sand" => "sandbox",
        "local" => "local",
        other => other,
    };
    vars.push(("NPM_SCRIPT_ENV".into(), npm_env.into()));

    // Vertical
    vars.push(("VERTICAL".into(), vertical.into()));

    // Service source dir overrides
    let home = paths::home();
    let default = |v: &str, fallback: &str| -> String {
        std::env::var(v)
            .ok()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| {
                home.join("projects/estrategia")
                    .join(fallback)
                    .to_string_lossy()
                    .into_owned()
            })
    };

    let (mono, bo, front) = match svc {
        "monolito" | "monolito-worker" => (
            src_dir.to_string_lossy().into_owned(),
            default("BO_CONTAINER_DIR", "bo-container"),
            default("FRONT_STUDENT_DIR", "front-student"),
        ),
        "bo-container" => (
            default("MONOLITO_DIR", "monolito"),
            src_dir.to_string_lossy().into_owned(),
            default("FRONT_STUDENT_DIR", "front-student"),
        ),
        "front-student" => (
            default("MONOLITO_DIR", "monolito"),
            default("BO_CONTAINER_DIR", "bo-container"),
            src_dir.to_string_lossy().into_owned(),
        ),
        _ => (
            default("MONOLITO_DIR", "monolito"),
            default("BO_CONTAINER_DIR", "bo-container"),
            default("FRONT_STUDENT_DIR", "front-student"),
        ),
    };

    vars.push(("MONOLITO_DIR".into(), mono));
    vars.push(("BO_CONTAINER_DIR".into(), bo));
    vars.push(("FRONT_STUDENT_DIR".into(), front));

    // Container-to-host path fixup
    if std::env::var("CLAUDE_ENV").as_deref() == Ok("container") {
        if let Ok(host_home) = std::env::var("HOST_HOME") {
            let container_home = "/home/claude";
            for (_, v) in vars.iter_mut() {
                if v.starts_with(container_home) {
                    *v = v.replacen(container_home, &host_home, 1);
                }
            }
            vars.push(("HOST_SSH_DIR".into(), format!("{host_home}/.ssh")));
            vars.push(("HOST_NPMRC".into(), format!("{host_home}/.npmrc")));
        }
    }

    vars
}
