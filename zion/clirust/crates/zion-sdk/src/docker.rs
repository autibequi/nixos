use std::process::Command;

use crate::error::{Result, ZionError};

/// Info about a running Docker container.
#[derive(Debug, Clone)]
pub struct ContainerInfo {
    pub name: String,
    pub status: String,
    pub ports: String,
    pub is_tty: bool,
}

/// CPU/memory stats for a container.
#[derive(Debug, Clone)]
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
        .map_err(|e| ZionError::Docker(format!("docker ps: {e}")))?;

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
            status: parts.get(1).unwrap_or(&"").to_string(),
            ports: parts.get(2).unwrap_or(&"").to_string(),
            is_tty: false, // filled by inspect
        });
    }

    Ok(containers)
}

/// Batch inspect containers for TTY and mounts.
pub fn inspect_containers(names: &[String]) -> Result<Vec<(String, bool, String)>> {
    if names.is_empty() {
        return Ok(Vec::new());
    }

    let mut cmd = Command::new("docker");
    cmd.args([
        "inspect",
        "--format",
        "{{.Name}}|{{.Config.Tty}}|{{range .Mounts}}{{.Destination}} {{end}}",
    ]);
    for name in names {
        cmd.arg(name);
    }

    let output = cmd
        .output()
        .map_err(|e| ZionError::Docker(format!("docker inspect: {e}")))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut results = Vec::new();

    for line in stdout.lines() {
        let line = line.trim_start_matches('/');
        let parts: Vec<&str> = line.splitn(3, '|').collect();
        if parts.len() < 3 {
            continue;
        }
        let name = parts[0].to_string();
        let is_tty = parts[1] == "true";
        let mounts = parts[2].to_string();
        results.push((name, is_tty, mounts));
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
        .map_err(|e| ZionError::Docker(format!("docker stats: {e}")))?;

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

/// Check if Docker is accessible.
pub fn is_available() -> bool {
    Command::new("docker")
        .args(["info"])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}
