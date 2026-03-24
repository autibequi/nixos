//! Git commands — repository utilities invoked from the Leech CLI.

use anyhow::Result;
use std::process::Command;

/// `leech git append` — stage all + commit with timestamp.
#[allow(dead_code)]
pub fn append(_branch: &str) -> Result<()> {
    git_commit("chore", "append")
}

/// `leech git sandbox` — stage all + commit with timestamp (sandbox shortcut).
pub fn sandbox() -> Result<()> {
    git_commit("chore", "sandbox")
}

fn git_commit(prefix: &str, label: &str) -> Result<()> {
    let stamp = chrono_stamp();
    let msg = format!("{prefix}: {label} {stamp}");
    Command::new("git").args(["add", "-A"]).status()?;
    Command::new("git").args(["commit", "-m", &msg]).status()?;
    Ok(())
}

fn chrono_stamp() -> String {
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let days = now / 86400;
    let time = now % 86400;
    let h = time / 3600;
    let m = (time % 3600) / 60;

    // Simplified civil date
    let z = days + 719468;
    let era = z / 146097;
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let mo = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if mo <= 2 { y + 1 } else { y };

    format!("{y:04}{mo:02}{d:02}_{h:02}{m:02}")
}
