//! Log tail — reads recent lines from Zion service log files.

use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};

/// A single log line with its source service tag.
#[derive(Debug, Clone)]
pub struct LogEntry {
    pub service: String,
    pub line: String,
}

const SERVICES: &[&str] = &["monolito", "bo-container", "front-student"];

/// Resolve the log root directory: container path first, then host XDG path.
fn log_root() -> PathBuf {
    // Inside container
    let container = PathBuf::from("/workspace/logs/docker");
    if container.exists() {
        return container;
    }

    // Host: XDG_DATA_HOME or ~/.local/share
    let xdg = std::env::var("XDG_DATA_HOME")
        .unwrap_or_else(|_| {
            let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
            format!("{home}/.local/share")
        });
    PathBuf::from(xdg).join("zion/logs/dockerized")
}

/// Read only the very last non-empty line of a service's log file.
#[must_use]
pub fn last_line(svc: &str) -> Option<String> {
    let path = log_root().join(svc).join("service.log");
    tail_file(&path, 5)
        .into_iter()
        .rev()
        .find(|l| !l.trim().is_empty())
}

/// Collect the last `n` lines per service, merging into a flat list.
#[must_use]
pub fn collect(n: usize) -> Vec<LogEntry> {
    let root = log_root();
    let mut all: Vec<LogEntry> = Vec::new();

    for svc in SERVICES {
        let path = root.join(svc).join("service.log");
        for line in tail_file(&path, n) {
            all.push(LogEntry {
                service: svc.to_string(),
                line,
            });
        }
    }

    // No global drain — UI filters by service, so keep all per-service entries
    all
}

/// Read the last `n` lines from a file efficiently (reads tail chunk only).
fn tail_file(path: &Path, n: usize) -> Vec<String> {
    let Ok(mut file) = std::fs::File::open(path) else {
        return Vec::new();
    };

    let Ok(size) = file.seek(SeekFrom::End(0)) else {
        return Vec::new();
    };

    if size == 0 {
        return Vec::new();
    }

    let chunk = 16384u64.min(size);
    let start = size.saturating_sub(chunk);
    if file.seek(SeekFrom::Start(start)).is_err() {
        return Vec::new();
    }

    let mut buf = String::new();
    if file.read_to_string(&mut buf).is_err() {
        // Try lossy
        let mut raw = Vec::new();
        let _ = file.seek(SeekFrom::Start(start));
        if file.read_to_end(&mut raw).is_err() {
            return Vec::new();
        }
        buf = String::from_utf8_lossy(&raw).into_owned();
    }

    let lines: Vec<&str> = buf.lines().collect();
    let skip = lines.len().saturating_sub(n);
    lines[skip..].iter().map(|l| l.to_string()).collect()
}
