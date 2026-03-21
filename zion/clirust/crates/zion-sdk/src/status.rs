use crate::docker::{self, ContainerStats};
use crate::error::Result;

/// A point-in-time snapshot of the Zion system status.
#[derive(Debug, Clone, Default)]
pub struct StatusSnapshot {
    pub agents: Vec<SessionInfo>,
    pub background: Vec<SessionInfo>,
    pub dk_services: Vec<DkServiceInfo>,
    pub stats: Vec<ContainerStats>,
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
    let docker_available = docker::is_available();
    if !docker_available {
        return Ok(StatusSnapshot::default());
    }

    // Collect containers in parallel using threads
    let leech_handle =
        std::thread::spawn(|| docker::list_containers("ancestor=claude-nix-sandbox"));
    let dk_handle = std::thread::spawn(|| docker::list_containers("name=zion-dk-"));
    let stats_handle = std::thread::spawn(docker::get_stats);

    let leech_containers = leech_handle.join().unwrap()?;
    let dk_containers = dk_handle.join().unwrap()?;
    let stats = stats_handle.join().unwrap()?;

    // Inspect leech containers for TTY + mounts
    let names: Vec<String> = leech_containers.iter().map(|c| c.name.clone()).collect();
    let inspect_data = docker::inspect_containers(&names)?;

    let mount_checks = [
        ("/workspace/mnt", "mnt"),
        ("/workspace/obsidian", "obs"),
        ("/workspace/zion", "zion"),
        ("/workspace/logs/docker", "logs"),
    ];

    let mut agents = Vec::new();
    let mut background = Vec::new();

    for container in &leech_containers {
        let is_up = container.status.to_lowercase().starts_with("up");

        // Find TTY and mounts from inspect
        let (is_tty, mount_str) = inspect_data
            .iter()
            .find(|(n, _, _)| *n == container.name)
            .map(|(_, tty, mounts)| (*tty, mounts.as_str()))
            .unwrap_or((true, ""));

        let mounts: Vec<MountStatus> = mount_checks
            .iter()
            .map(|(path, label)| MountStatus {
                label: label.to_string(),
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
            DkServiceInfo {
                name: c.name.clone(),
                status: c.status.clone(),
                is_up,
                cpu,
                mem,
            }
        })
        .collect();

    Ok(StatusSnapshot {
        agents,
        background,
        dk_services,
        stats,
    })
}

fn find_stats(stats: &[ContainerStats], name: &str) -> (String, String) {
    stats
        .iter()
        .find(|s| s.name == name || s.name.contains(name))
        .map(|s| (s.cpu.clone(), s.mem.clone()))
        .unwrap_or_default()
}
