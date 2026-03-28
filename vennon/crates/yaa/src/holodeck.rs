use anyhow::{bail, Result};
use std::process::{Command, Stdio};

use crate::exec;

const RELAY_PORT: u16 = 9222;
const RELAY_DIR: &str = "/tmp/yaa-holodeck";

/// Start Chrome with CDP remote debugging.
pub fn start() -> Result<()> {
    // Check if already running
    if is_running() {
        println!("Holodeck already running on port {RELAY_PORT}");
        return Ok(());
    }

    // Find Chrome/Chromium
    let browser = find_browser()?;
    println!("Starting holodeck ({browser})...");

    // Launch Chrome with CDP flags + fullscreen
    Command::new(&browser)
        .args([
            &format!("--remote-debugging-port={RELAY_PORT}"),
            &format!("--user-data-dir={RELAY_DIR}"),
            "--no-first-run",
            "--no-default-browser-check",
            "about:blank",
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()?;

    // Wait for CDP to be ready (up to 5s)
    for _ in 0..10 {
        std::thread::sleep(std::time::Duration::from_millis(500));
        if is_running() {
            println!("Holodeck ready on port {RELAY_PORT}");
            return Ok(());
        }
    }

    bail!("Holodeck failed to start (CDP not responding on port {RELAY_PORT})")
}

/// Stop Chrome relay.
pub fn stop() -> Result<()> {
    let pids = exec::capture(
        "pgrep",
        &["-f", &format!("remote-debugging-port={RELAY_PORT}")],
    )
    .unwrap_or_default();

    if pids.is_empty() {
        println!("Holodeck not running.");
        return Ok(());
    }

    for pid in pids.lines() {
        let pid = pid.trim();
        if !pid.is_empty() {
            let _ = Command::new("kill").arg(pid).status();
        }
    }

    println!("Holodeck stopped.");
    Ok(())
}

/// Show holodeck status.
pub fn status() -> Result<()> {
    if is_running() {
        println!("Holodeck: running on port {RELAY_PORT}");
        // Count tabs
        if let Ok(tabs) = exec::capture("curl", &["-s", &format!("http://localhost:{RELAY_PORT}/json")]) {
            let count = tabs.matches("\"type\":\"page\"").count();
            println!("Tabs: {count}");
        }
    } else {
        println!("Holodeck: not running");
    }
    Ok(())
}

/// Dispatch holodeck action.
pub fn dispatch(action: &str) -> Result<()> {
    match action {
        "start" | "" => start(),
        "stop" => stop(),
        "status" => status(),
        _ => bail!("unknown holodeck action: {action}\nValid: start, stop, status"),
    }
}

// ── Helpers ─────────────────────────────────────────────────────

fn is_running() -> bool {
    Command::new("curl")
        .args(["-s", "-o", "/dev/null", "-w", "%{http_code}", &format!("http://localhost:{RELAY_PORT}/json/version")])
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim() == "200")
        .unwrap_or(false)
}

fn find_browser() -> Result<String> {
    for name in &["google-chrome-stable", "google-chrome", "chromium"] {
        if Command::new("which")
            .arg(name)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
        {
            return Ok(name.to_string());
        }
    }
    bail!("no Chrome/Chromium found in PATH")
}
