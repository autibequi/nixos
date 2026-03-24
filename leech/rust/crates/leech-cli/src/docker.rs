//! Docker CLI wrappers — container listing, inspection, stats, and availability check.

use std::process::Command;

use crate::error::{Result, LeechError};

/// Info about a running Docker container.
#[derive(Debug, Clone)]
pub struct ContainerInfo {
    pub name: String,
    pub status: String,
    pub ports: String,
    pub is_tty: bool,
}

/// CPU/memory stats for a container.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ContainerStats {
    pub name: String,
    pub cpu: String,
    pub mem: String,
}

/// List containers matching a filter.
pub fn list_containers(filter: &str) -> Result<Vec<ContainerInfo>> {
    let output = Command::new("docker")
        .args([
            "ps",
            "-a",
            "--filter",
            filter,
            "--format",
            "{{.Names}}\t{{.Status}}\t{{.Ports}}",
        ])
        .output()
        .map_err(|e| LeechError::Docker(format!("docker ps: {e}")))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut containers = Vec::new();

    for line in stdout.lines() {
        if line.is_empty() {
            continue;
        }
        let parts: Vec<&str> = line.splitn(3, '\t').collect();
        if parts.is_empty() {
            continue;
        }
        containers.push(ContainerInfo {
            name: parts[0].to_string(),
            status: parts.get(1).copied().unwrap_or("").to_string(),
            ports: parts.get(2).copied().unwrap_or("").to_string(),
            is_tty: false, // filled by inspect
        });
    }

    Ok(containers)
}

/// Batch inspect containers for TTY, mounts, and the host path bound to /workspace/mnt.
/// Returns `(name, is_tty, dest_mounts_string, mnt_host_path)`.
pub fn inspect_containers(names: &[String]) -> Result<Vec<(String, bool, String, String)>> {
    if names.is_empty() {
        return Ok(Vec::new());
    }

    let mut cmd = Command::new("docker");
    cmd.args([
        "inspect",
        "--format",
        // Emit dest-only list + a sentinel, then Source:Dest pairs for /workspace/mnt
        "{{.Name}}|{{.Config.Tty}}|{{range .Mounts}}{{.Destination}} {{end}}|{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}",
    ]);
    for name in names {
        cmd.arg(name);
    }

    let output = cmd
        .output()
        .map_err(|e| LeechError::Docker(format!("docker inspect: {e}")))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut results = Vec::new();

    for line in stdout.lines() {
        let line = line.trim_start_matches('/');
        let parts: Vec<&str> = line.splitn(4, '|').collect();
        if parts.len() < 3 {
            continue;
        }
        let name = parts[0].to_string();
        let is_tty = parts[1] == "true";
        let mounts = parts[2].to_string();
        // Extract host path for /workspace/mnt from source:dest pairs
        let mnt_path = if parts.len() >= 4 {
            parts[3]
                .split_whitespace()
                .find(|pair| pair.ends_with(":/workspace/mnt"))
                .and_then(|pair| pair.strip_suffix(":/workspace/mnt"))
                .unwrap_or("")
                .to_string()
        } else {
            String::new()
        };
        results.push((name, is_tty, mounts, mnt_path));
    }

    Ok(results)
}

/// Get docker stats (no-stream) for all containers.
pub fn get_stats() -> Result<Vec<ContainerStats>> {
    let output = Command::new("docker")
        .args([
            "stats",
            "--no-stream",
            "--format",
            "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}",
        ])
        .output()
        .map_err(|e| LeechError::Docker(format!("docker stats: {e}")))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut stats = Vec::new();

    for line in stdout.lines() {
        if line.is_empty() {
            continue;
        }
        let parts: Vec<&str> = line.splitn(3, '\t').collect();
        if parts.len() < 3 {
            continue;
        }
        stats.push(ContainerStats {
            name: parts[0].to_string(),
            cpu: parts[1].to_string(),
            mem: parts[2].to_string(),
        });
    }

    Ok(stats)
}

/// Count running `claude` processes inside a container via `docker top`.
/// Returns 0 if the container is not running or docker top fails.
pub fn count_claude_procs(container: &str) -> usize {
    let output = Command::new("docker")
        .args(["top", container])
        .output()
        .unwrap_or_else(|_| std::process::Output {
            status: std::process::ExitStatus::default(),
            stdout: Vec::new(),
            stderr: Vec::new(),
        });

    if !output.status.success() {
        return 0;
    }

    String::from_utf8_lossy(&output.stdout)
        .lines()
        .skip(1) // skip header row
        // Match .claude-unwrapped (nix store path) with an active PTY — filters out subprocesses
        .filter(|line| line.contains(".claude-unwrapped") && line.contains("pts/"))
        .count()
}

/// Find the CID of a running container by exact name. Returns None if not found.
pub fn find_running_container(name: &str) -> Option<String> {
    let filter = format!("name=^/{name}$");
    let output = Command::new("docker")
        .args(["ps", "-q", "--filter", &filter])
        .output()
        .ok()?;
    let cid = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if cid.is_empty() { None } else { Some(cid) }
}

/// Find the name of a compose-managed persistent (oneoff=False) container for a service.
pub fn find_compose_container(project: &str, service: &str) -> Option<String> {
    let output = Command::new("docker")
        .args([
            "ps",
            "--filter", &format!("label=com.docker.compose.project={project}"),
            "--filter", &format!("label=com.docker.compose.service={service}"),
            "--filter", "label=com.docker.compose.oneoff=False",
            "--format", "{{.Names}}",
        ])
        .output()
        .ok()?;
    let name = String::from_utf8_lossy(&output.stdout).lines().next()?.to_string();
    if name.is_empty() { None } else { Some(name) }
}

/// Rename a container. Silently ignores errors (container may already have the target name).
pub fn rename_container(old: &str, new: &str) {
    let _ = Command::new("docker").args(["rename", old, new]).output();
}

/// Replace the current process with `docker run` using the given args directly.
/// Used for ghost mode where we bypass docker-compose entirely.
pub fn exec_replace_docker(args: &[&str]) -> Result<()> {
    use std::os::unix::process::CommandExt;
    let mut cmd = Command::new("docker");
    cmd.args(args);
    let err = cmd.exec();
    Err(LeechError::Docker(format!("docker run failed: {err}")))
}

/// Replace the current process with `docker exec -it` into a container.
/// Passes env vars and runs bash_cmd inside the container.
pub fn exec_replace(cid: &str, env: &[(&str, &str)], bash_cmd: &str) -> Result<()> {
    use std::os::unix::process::CommandExt;
    let mut cmd = Command::new("docker");
    cmd.arg("exec").arg("-it");
    for (k, v) in env {
        cmd.arg("-e").arg(format!("{k}={v}"));
    }
    cmd.args([cid, "/bin/bash", "-c", bash_cmd]);
    let err = cmd.exec(); // replaces the process; only returns on error
    Err(LeechError::Docker(format!("docker exec failed: {err}")))
}

/// Batch-inspect a list of containers to extract their APP_ENV value.
/// Returns a map of container_name → env string (empty if not found).
pub fn get_dk_app_envs(names: &[String]) -> std::collections::HashMap<String, String> {
    if names.is_empty() {
        return std::collections::HashMap::new();
    }
    let mut cmd = Command::new("docker");
    cmd.args(["inspect", "--format", "{{.Name}}|{{range .Config.Env}}{{.}} {{end}}"]);
    for n in names {
        cmd.arg(n);
    }
    let output = match cmd.output() {
        Ok(o) => o,
        Err(_) => return std::collections::HashMap::new(),
    };
    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut map = std::collections::HashMap::new();
    for line in stdout.lines() {
        let parts: Vec<&str> = line.splitn(2, '|').collect();
        if parts.len() != 2 { continue; }
        let name = parts[0].trim_start_matches('/').to_string();
        for env_var in parts[1].split_whitespace() {
            if let Some(val) = env_var.strip_prefix("APP_ENV=") {
                map.insert(name, val.to_string());
                break;
            }
        }
    }
    map
}

/// Check if Docker is accessible.
#[must_use]
pub fn is_available() -> bool {
    Command::new("docker")
        .args(["info"])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}
