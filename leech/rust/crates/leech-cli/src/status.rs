//! System status collection — agent containers, background sessions, DK services, and stats.

use crate::boot::BootInfo;
use crate::docker::{self, ContainerStats};
use crate::error::Result;
use crate::logs::LogEntry;
use crate::quota::QuotaInfo;

/// A point-in-time snapshot of the Leech system status.
#[derive(Debug, Clone, Default, serde::Serialize, serde::Deserialize)]
pub struct StatusSnapshot {
    pub agents: Vec<SessionInfo>,
    pub background: Vec<SessionInfo>,
    pub dk_services: Vec<DkServiceInfo>,
    /// Leech agent containers (projects-leech-run-*), shown under "projects".
    pub leech: Vec<DkServiceInfo>,
    /// Utility containers: leech-reverseproxy and others (not dk, not leech).
    pub utils: Vec<DkServiceInfo>,
    pub stats: Vec<ContainerStats>,
    pub boot: BootInfo,
    pub quota: QuotaInfo,
    pub logs: Vec<LogEntry>,
    /// Last log line per service name (for inline preview in services panel).
    pub last_log: std::collections::HashMap<String, String>,
}

/// Info about a Leech agent/background session.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SessionInfo {
    pub name: String,
    /// Short display identifier derived from container name (e.g. "975096e6").
    pub short_id: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
    pub mounts: Vec<MountStatus>,
    /// Host path bound to /workspace/mnt (the project directory).
    pub mnt_path: String,
    /// Number of active `claude` processes running inside the container.
    /// > 1 means multiple exec sessions sharing the same container.
    pub session_count: usize,
}

fn container_short_id(name: &str) -> String {
    // "leech-projects-leech-run-975096e652b6" → "975096e6"
    if let Some(suffix) = name.split("leech-run-").nth(1) {
        return suffix.chars().take(8).collect();
    }
    // canonical "leech-projects" — last segment after last '-'
    name.rsplit('-').next().unwrap_or(name).to_string()
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MountStatus {
    pub label: String,
    pub present: bool,
}

/// Info about a dockerized service (leech-dk-*).
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct DkServiceInfo {
    pub name: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
    /// Host path bound to /workspace/mnt (populated for leech containers).
    pub mnt_path: String,
    /// APP_ENV value detected from running container (empty when stopped).
    pub env: String,
    /// Current git branch of the service's source directory (empty if undetectable).
    #[serde(default)]
    pub branch: String,
}

/// Return the source directory for a given service name, checking env vars first.
fn svc_git_dir(svc: &str) -> String {
    let env_key = match svc {
        "monolito"      => "MONOLITO_DIR",
        "bo-container"  => "BO_CONTAINER_DIR",
        "front-student" => "FRONT_STUDENT_DIR",
        _               => "",
    };
    if !env_key.is_empty() {
        if let Ok(dir) = std::env::var(env_key) {
            if !dir.is_empty() { return dir; }
        }
    }
    format!("/workspace/mnt/estrategia/{}", svc)
}

/// Read the current git branch of a directory by parsing .git/HEAD directly.
fn read_git_branch(dir: &str) -> String {
    let dot_git = std::path::Path::new(dir).join(".git");
    let head_path = if dot_git.is_dir() {
        dot_git.join("HEAD")
    } else if dot_git.is_file() {
        // git worktree: .git is a file with "gitdir: /real/.git/worktrees/name"
        let content = std::fs::read_to_string(&dot_git).unwrap_or_default();
        if let Some(rest) = content.strip_prefix("gitdir: ") {
            std::path::PathBuf::from(rest.trim()).join("HEAD")
        } else {
            return String::new();
        }
    } else {
        return String::new();
    };
    let content = std::fs::read_to_string(head_path).unwrap_or_default();
    content
        .strip_prefix("ref: refs/heads/")
        .unwrap_or("")
        .trim()
        .to_string()
}

/// Collect a full status snapshot.
pub fn collect() -> Result<StatusSnapshot> {
    // Boot info and logs are cheap — collect immediately
    let boot = crate::boot::collect();
    let logs = crate::logs::collect(100);

    // Last log line per service (for inline preview)
    let last_log: std::collections::HashMap<String, String> =
        ["monolito", "bo-container", "front-student"]
            .iter()
            .filter_map(|&svc| {
                crate::logs::last_line(svc).map(|line| (svc.to_string(), line))
            })
            .collect();

    // Quota: run script in background thread
    let quota_handle = std::thread::spawn(|| {
        crate::paths::usage_script()
            .map(|p| crate::quota::collect(&p))
            .unwrap_or_default()
    });

    if !docker::is_available() {
        let quota = quota_handle.join().unwrap_or_default();
        return Ok(StatusSnapshot {
            boot,
            quota,
            logs,
            last_log,
            ..Default::default()
        });
    }

    // Collect containers in parallel using threads
    let leech_handle =
        std::thread::spawn(|| docker::list_containers("ancestor=leech"));
    let dk_handle = std::thread::spawn(|| docker::list_containers("name=leech-dk-"));
    let utils_handle = std::thread::spawn(|| docker::list_containers("name=leech-"));
    let stats_handle = std::thread::spawn(docker::get_stats);

    let leech_containers = leech_handle.join().unwrap_or_else(|_| Ok(Vec::new()))?;
    let dk_containers = dk_handle.join().unwrap_or_else(|_| Ok(Vec::new()))?;
    let utils_raw = utils_handle.join().unwrap_or_else(|_| Ok(Vec::new()))?;
    let stats = stats_handle.join().unwrap_or_else(|_| Ok(Vec::new()))?;
    let quota = quota_handle.join().unwrap_or_default();

    // Inspect leech containers for TTY + mounts
    let names: Vec<String> = leech_containers.iter().map(|c| c.name.clone()).collect();
    let inspect_data = docker::inspect_containers(&names)?;

    let mount_checks = [
        ("/workspace/mnt", "mnt"),
        ("/workspace/obsidian", "obs"),
        ("/workspace/self", "leech"),
        ("/workspace/logs/docker", "logs"),
    ];

    let mut agents = Vec::new();
    let mut background = Vec::new();

    // Count claude procs in parallel for all running leech containers
    let proc_counts: std::collections::HashMap<String, usize> = {
        let handles: Vec<_> = leech_containers
            .iter()
            .filter(|c| c.status.to_lowercase().starts_with("up"))
            .map(|c| {
                let name = c.name.clone();
                std::thread::spawn(move || (name.clone(), docker::count_claude_procs(&name)))
            })
            .collect();
        handles.into_iter().filter_map(|h| h.join().ok()).collect()
    };

    for container in &leech_containers {
        let is_up = container.status.to_lowercase().starts_with("up");

        // Find TTY and mounts from inspect
        let (is_tty, mount_str, mnt_path) = inspect_data
            .iter()
            .find(|(n, _, _, _)| *n == container.name)
            .map_or((true, "", String::new()), |(_, tty, mounts, mnt)| {
                (*tty, mounts.as_str(), mnt.clone())
            });

        let mounts: Vec<MountStatus> = mount_checks
            .iter()
            .map(|(path, label)| MountStatus {
                label: (*label).to_string(),
                present: mount_str.contains(path),
            })
            .collect();

        // Find stats
        let (cpu, mem) = find_stats(&stats, &container.name);
        let session_count = proc_counts.get(&container.name).copied().unwrap_or(0);

        let info = SessionInfo {
            name: container.name.clone(),
            short_id: container_short_id(&container.name),
            status: container.status.clone(),
            is_up,
            cpu,
            mem,
            mounts,
            mnt_path,
            session_count,
        };

        if is_tty {
            agents.push(info);
        } else {
            background.push(info);
        }
    }

    // Detect APP_ENV for running app containers (leech-dk-*-app)
    let running_app_names: Vec<String> = dk_containers.iter()
        .filter(|c| c.status.to_lowercase().starts_with("up") && c.name.ends_with("-app"))
        .map(|c| c.name.clone())
        .collect();
    let app_envs = docker::get_dk_app_envs(&running_app_names);

    // DK services
    let dk_services: Vec<DkServiceInfo> = dk_containers
        .iter()
        .map(|c| {
            let is_up = c.status.to_lowercase().starts_with("up");
            let (cpu, mem) = find_stats(&stats, &c.name);
            let env = app_envs.get(&c.name).cloned().unwrap_or_default();
            // Read git branch only for main app containers (not deps like postgres/redis)
            let branch = if c.name.ends_with("-app") {
                let svc = c.name
                    .strip_prefix("leech-dk-").unwrap_or("")
                    .strip_suffix("-app").unwrap_or("");
                read_git_branch(&svc_git_dir(svc))
            } else {
                String::new()
            };
            DkServiceInfo { name: c.name.clone(), status: c.status.clone(), is_up, cpu, mem, mnt_path: String::new(), env, branch }
        })
        .collect();

    // Utility containers: leech-* excluding dk and leech (agent) containers
    let dk_names: std::collections::HashSet<&str> =
        dk_containers.iter().map(|c| c.name.as_str()).collect();
    let leech_names: std::collections::HashSet<&str> =
        leech_containers.iter().map(|c| c.name.as_str()).collect();

    // Detect leech containers by name pattern (catches containers not found by ancestor filter)
    // Also catches leech-projects / leech-projects-host (agent infra, not utils)
    let is_leech_name = |name: &str| name.contains("leech-run-") || name.contains("-projects");

    let (leech_extra, true_utils): (Vec<_>, Vec<_>) = utils_raw
        .into_iter()
        .filter(|c| !dk_names.contains(c.name.as_str()) && !leech_names.contains(c.name.as_str()))
        .partition(|c| is_leech_name(&c.name));

    // Inspect leech_extra to get TTY + mnt_path, then merge into agents/background
    let leech_extra_names: Vec<String> = leech_extra.iter().map(|c| c.name.clone()).collect();
    let leech_inspect = docker::inspect_containers(&leech_extra_names).unwrap_or_default();

    for c in leech_extra {
        let is_up = c.status.to_lowercase().starts_with("up");
        let (cpu, mem) = find_stats(&stats, &c.name);
        let (is_tty, mount_str, mnt_path) = leech_inspect
            .iter()
            .find(|(n, _, _, _)| n == c.name.trim_start_matches('/'))
            .map_or((true, "", String::new()), |(_, tty, mounts, mnt)| {
                (*tty, mounts.as_str(), mnt.clone())
            });
        let mounts: Vec<MountStatus> = mount_checks
            .iter()
            .map(|(path, label)| MountStatus {
                label: (*label).to_string(),
                present: mount_str.contains(path),
            })
            .collect();
        let session_count = proc_counts.get(&c.name).copied().unwrap_or(0);
        let info = SessionInfo {
            name: c.name.clone(),
            short_id: container_short_id(&c.name),
            status: c.status.clone(),
            is_up,
            cpu,
            mem,
            mounts,
            mnt_path,
            session_count,
        };
        if is_tty { agents.push(info); } else { background.push(info); }
    }

    let leech: Vec<DkServiceInfo> = Vec::new();

    let utils: Vec<DkServiceInfo> = true_utils
        .into_iter()
        .map(|c| {
            let is_up = c.status.to_lowercase().starts_with("up");
            let (cpu, mem) = find_stats(&stats, &c.name);
            DkServiceInfo { name: c.name.clone(), status: c.status.clone(), is_up, cpu, mem, mnt_path: String::new(), env: String::new(), branch: String::new() }
        })
        .collect();

    Ok(StatusSnapshot {
        agents,
        background,
        dk_services,
        leech,
        utils,
        stats,
        boot,
        quota,
        logs,
        last_log,
    })
}

fn find_stats(stats: &[ContainerStats], name: &str) -> (String, String) {
    stats
        .iter()
        .find(|s| s.name == name || s.name.contains(name))
        .map_or_else(
            || (String::new(), String::new()),
            |s| (s.cpu.clone(), s.mem.clone()),
        )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_status_snapshot_default() {
        let snap = StatusSnapshot::default();
        assert!(snap.agents.is_empty());
        assert!(snap.background.is_empty());
        assert!(snap.dk_services.is_empty());
        assert!(snap.stats.is_empty());
    }

    #[test]
    fn test_find_stats_missing() {
        let stats: Vec<ContainerStats> = Vec::new();
        let (cpu, mem) = find_stats(&stats, "nonexistent");
        assert!(cpu.is_empty());
        assert!(mem.is_empty());
    }

    #[test]
    fn test_find_stats_found() {
        let stats = vec![ContainerStats {
            name: "my-container".to_string(),
            cpu: "5%".to_string(),
            mem: "100MiB".to_string(),
        }];
        let (cpu, mem) = find_stats(&stats, "my-container");
        assert_eq!(cpu, "5%");
        assert_eq!(mem, "100MiB");
    }
}
