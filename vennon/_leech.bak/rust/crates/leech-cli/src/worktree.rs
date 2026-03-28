//! Worktree listing — collects git worktrees across all known services.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

use crate::runner;

/// A git worktree entry for a service.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorktreeInfo {
    pub service: String,
    pub name: String,
    pub path: String,
    pub branch: String,
    pub is_main: bool,
}

/// List all worktrees across known services.
/// If `filter_service` is Some, only list for that service.
pub fn list_worktrees(filter_service: Option<&str>) -> Vec<WorktreeInfo> {
    let services: Vec<&str> = match filter_service {
        Some(svc) => vec![runner::resolve_alias(svc)],
        None => vec!["monolito", "bo-container", "front-student"],
    };

    let mut result = Vec::new();

    for svc in services {
        let src_dir = runner::service_src_dir(svc);
        if !src_dir.is_dir() {
            continue;
        }

        let output = std::process::Command::new("git")
            .args(["-C", &src_dir.to_string_lossy(), "worktree", "list"])
            .output();

        let output = match output {
            Ok(o) if o.status.success() => o,
            _ => continue,
        };

        let stdout = String::from_utf8_lossy(&output.stdout);
        let main_dir = src_dir.to_string_lossy().into_owned();

        for line in stdout.lines() {
            if line.trim().is_empty() {
                continue;
            }
            // Format: "/path/to/worktree  abc1234 [branch-name]"
            let parts: Vec<&str> = line.splitn(2, char::is_whitespace).collect();
            let wt_path = parts.first().unwrap_or(&"").trim();
            let rest = parts.get(1).unwrap_or(&"").trim();

            let branch = rest
                .find('[')
                .and_then(|start| {
                    rest.find(']').map(|end| rest[start + 1..end].to_string())
                })
                .unwrap_or_default();

            let name = PathBuf::from(wt_path)
                .file_name()
                .map(|f| f.to_string_lossy().into_owned())
                .unwrap_or_default();

            let is_main = wt_path.trim_end_matches('/') == main_dir.trim_end_matches('/');

            result.push(WorktreeInfo {
                service: svc.to_string(),
                name,
                path: wt_path.to_string(),
                branch,
                is_main,
            });
        }
    }

    result
}
