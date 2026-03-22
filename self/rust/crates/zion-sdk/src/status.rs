//! System status collection — agent containers, background sessions, DK services, and stats.

use crate::boot::BootInfo;
use crate::docker::{self, ContainerStats};
use crate::error::Result;
use crate::logs::LogEntry;
use crate::quota::QuotaInfo;

/// A point-in-time snapshot of the Zion system status.
#[derive(Debug, Clone, Default)]
pub struct StatusSnapshot {
    pub agents: Vec<SessionInfo>,
    pub background: Vec<SessionInfo>,
    pub dk_services: Vec<DkServiceInfo>,
    /// Utility containers: zion-reverseproxy and others (not dk, not leech).
    pub utils: Vec<DkServiceInfo>,
    pub stats: Vec<ContainerStats>,
    pub boot: BootInfo,
    pub quota: QuotaInfo,
    pub logs: Vec<LogEntry>,
    /// Last log line per service name (for inline preview in services panel).
    pub last_log: std::collections::HashMap<String, String>,
}

/// Info about a Zion agent/background session.
#[derive(Debug, Clone)]
pub struct SessionInfo {
    pub name: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
    pub mounts: Vec<MountStatus>,
    /// Host path bound to /workspace/mnt (the project directory).
    pub mnt_path: String,
}

#[derive(Debug, Clone)]
pub struct MountStatus {
    pub label: String,
    pub present: bool,
}

/// Info about a dockerized service (zion-dk-*).
#[derive(Debug, Clone)]
pub struct DkServiceInfo {
    pub name: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
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
        std::thread::spawn(|| docker::list_containers("ancestor=claude-nix-sandbox"));
    let dk_handle = std::thread::spawn(|| docker::list_containers("name=zion-dk-"));
    let utils_handle = std::thread::spawn(|| docker::list_containers("name=zion-"));
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
        ("/workspace/self", "zion"),
        ("/workspace/logs/docker", "logs"),
    ];

    let mut agents = Vec::new();
    let mut background = Vec::new();

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

        let info = SessionInfo {
            name: container.name.clone(),
            status: container.status.clone(),
            is_up,
            cpu,
            mem,
            mounts,
            mnt_path,
        };

        if is_tty {
            agents.push(info);
        } else {
            background.push(info);
        }
    }

    // DK services
    let dk_services: Vec<DkServiceInfo> = dk_containers
        .iter()
        .map(|c| {
            let is_up = c.status.to_lowercase().starts_with("up");
            let (cpu, mem) = find_stats(&stats, &c.name);
            DkServiceInfo { name: c.name.clone(), status: c.status.clone(), is_up, cpu, mem }
        })
        .collect();

    // Utility containers: zion-* excluding dk and leech (agent) containers
    let dk_names: std::collections::HashSet<&str> =
        dk_containers.iter().map(|c| c.name.as_str()).collect();
    let leech_names: std::collections::HashSet<&str> =
        leech_containers.iter().map(|c| c.name.as_str()).collect();
    let utils: Vec<DkServiceInfo> = utils_raw
        .into_iter()
        .filter(|c| !dk_names.contains(c.name.as_str()) && !leech_names.contains(c.name.as_str()))
        .map(|c| {
            let is_up = c.status.to_lowercase().starts_with("up");
            let (cpu, mem) = find_stats(&stats, &c.name);
            DkServiceInfo { name: c.name.clone(), status: c.status.clone(), is_up, cpu, mem }
        })
        .collect();

    Ok(StatusSnapshot {
        agents,
        background,
        dk_services,
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
