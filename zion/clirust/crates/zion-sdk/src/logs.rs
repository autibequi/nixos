//! Log tail — reads recent lines from Zion service log files.

use std::io::{Read, Seek, SeekFrom};
use std::path::{Path, PathBuf};

/// A single log line with its source service tag.
#[derive(Debug, Clone)]
pub struct LogEntry {
    pub service: String,
    pub line: String,
}

/// Collect the last `n` lines across all known service log files.
#[must_use]
pub fn collect(n: usize) -> Vec<LogEntry> {
    let log_root = PathBuf::from("/workspace/logs/docker");
    let services = ["monolito", "bo-container", "front-student"];

    let mut all: Vec<(std::time::SystemTime, LogEntry)> = Vec::new();

    for svc in &services {
        let path = log_root.join(svc).join("service.log");
        if !path.exists() {
            continue;
        }
        for line in tail_file(&path, n) {
            all.push((
                std::time::SystemTime::UNIX_EPOCH,
                LogEntry {
                    service: svc.to_string(),
                    line,
                },
            ));
        }
    }

    // Return last `n` entries across all services
    if all.len() > n {
        all.drain(..all.len() - n);
    }

    all.into_iter().map(|(_, e)| e).collect()
}

/// Read the last `n` lines from a file efficiently.
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

    // Walk backwards to find the nth newline
    let chunk = 8192u64.min(size);
    let start = size.saturating_sub(chunk);
    if file.seek(SeekFrom::Start(start)).is_err() {
        return Vec::new();
    }

    let mut buf = String::new();
    if file.read_to_string(&mut buf).is_err() {
        return Vec::new();
    }

    let lines: Vec<&str> = buf.lines().collect();
    let skip = lines.len().saturating_sub(n);
    lines[skip..]
        .iter()
        .map(|l| l.to_string())
        .collect()
}

/// Read last `n` lines from a host journal log file (plain text, one entry per line).
#[must_use]
pub fn collect_host(n: usize) -> Vec<LogEntry> {
    let path = PathBuf::from("/workspace/logs/host/journal/system.log");
    if !path.exists() {
        return Vec::new();
    }
    tail_file(&path, n)
        .into_iter()
        .map(|line| LogEntry {
            service: "host".to_string(),
            line,
        })
        .collect()
}
