//! Log tail — reads recent lines from Leech service log files.

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
    PathBuf::from(xdg).join("leech/logs/dockerized")
}

/// Strip ANSI/VT100 escape sequences from a string.
/// Handles CSI sequences (\x1b[...X), OSC (\x1b]...\x07/ST), and bare \x1b.
fn strip_ansi(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == 0x1b {
            i += 1;
            if i >= bytes.len() {
                break;
            }
            match bytes[i] {
                // CSI: \x1b[ ... <final byte 0x40–0x7e>
                b'[' => {
                    i += 1;
                    while i < bytes.len() && !(0x40..=0x7e).contains(&bytes[i]) {
                        i += 1;
                    }
                    i += 1; // skip final byte
                }
                // OSC: \x1b] ... \x07 or \x1b\\
                b']' => {
                    i += 1;
                    while i < bytes.len() && bytes[i] != 0x07 {
                        if bytes[i] == 0x1b && i + 1 < bytes.len() && bytes[i + 1] == b'\\' {
                            i += 2;
                            break;
                        }
                        i += 1;
                    }
                    if i < bytes.len() {
                        i += 1;
                    }
                }
                // Other Fe sequences: single extra byte
                _ => {
                    i += 1;
                }
            }
        } else {
            out.push(bytes[i]);
            i += 1;
        }
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// Find the most recently modified `service.log` for a service.
/// Checks both the base path and any `wt-*/` worktree subdirectories, returning
/// the one with the newest mtime. This handles the case where a worktree is active
/// and the bash runner writes to `<log_dir>/wt-<worktree>/service.log` instead
/// of the base path.
fn active_log_path(root: &Path, svc: &str) -> Option<PathBuf> {
    use std::time::SystemTime;

    let svc_dir = root.join(svc);
    let base_log = svc_dir.join("service.log");

    let base_entry = base_log
        .metadata()
        .ok()
        .and_then(|m| m.modified().ok())
        .map(|t| (base_log.clone(), t));

    // Check wt-* subdirectories for a more recent service.log
    let wt_best = std::fs::read_dir(&svc_dir)
        .ok()
        .into_iter()
        .flatten()
        .flatten()
        .filter(|e| {
            e.file_type().map(|t| t.is_dir()).unwrap_or(false)
                && e.file_name().to_str().map(|n| n.starts_with("wt-")).unwrap_or(false)
        })
        .filter_map(|e| {
            let p = e.path().join("service.log");
            let t = p.metadata().ok()?.modified().ok()?;
            Some((p, t))
        })
        .max_by_key(|(_, t)| *t);

    match (base_entry, wt_best) {
        (Some((bp, bt)), Some((wp, wt))) => {
            if wt > bt { Some(wp) } else { Some(bp) }
        }
        (Some((bp, _)), None) => Some(bp),
        (None, Some((wp, _))) => Some(wp),
        (None, None) => None,
    }
}

/// Read only the very last non-empty line of a service's log file.
#[must_use]
pub fn last_line(svc: &str) -> Option<String> {
    let path = active_log_path(&log_root(), svc)?;
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
        let Some(path) = active_log_path(&root, svc) else { continue };
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

    let mut raw = Vec::new();
    if file.read_to_end(&mut raw).is_err() {
        return Vec::new();
    }
    let buf = String::from_utf8_lossy(&raw).into_owned();

    // Normalize carriage returns: \r\n → \n, bare \r → \n
    // This handles tools like webpack that use \r for in-place progress updates.
    let normalized = buf.replace("\r\n", "\n").replace('\r', "\n");

    let lines: Vec<String> = normalized
        .lines()
        .map(strip_ansi)
        .filter(|l| !l.trim().is_empty())
        .collect();
    let skip = lines.len().saturating_sub(n);
    lines[skip..].to_vec()
}
