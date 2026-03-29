use std::io::Write;
use std::path::Path;

use crate::protocol::{BusRequest, BusResponse};

/// Append one audit entry to the log file (JSONL).
pub fn log_entry(log_path: &Path, req: &BusRequest, resp: &BusResponse, duration_ms: u64) {
    let entry = serde_json::json!({
        "ts": now_iso(),
        "id": req.id,
        "source": req.source,
        "action": req.action,
        "args": req.args,
        "status": resp.status,
        "error": resp.error,
        "duration_ms": duration_ms,
    });

    if let Some(parent) = log_path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }

    if let Ok(mut f) = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_path)
    {
        let _ = writeln!(f, "{}", entry);
    }
}

fn now_iso() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    // Simple ISO-ish timestamp without chrono
    let s = secs % 60;
    let m = (secs / 60) % 60;
    let h = (secs / 3600) % 24;
    let days = secs / 86400;
    // Rough date (good enough for logs, not calendar-accurate)
    format!("day{days}T{h:02}:{m:02}:{s:02}Z")
}
