//! Tool commands — hooks, Chrome relay, inbox/outbox, man page, usage stats, and token.

use std::process::{Command, Stdio};

use anyhow::{bail, Result};
use leech_cli::paths;

// ── hooks ────────────────────────────────────────────────────────

pub fn hooks(hook: Option<String>, list: bool, env_overrides: Vec<String>) -> Result<()> {
    let dir = paths::hooks_dir().ok_or_else(|| anyhow::anyhow!("hooks dir not found"))?;

    if list {
        println!("Hooks em {}:", dir.display());
        for e in std::fs::read_dir(&dir)?.flatten() {
            let n = e.file_name().to_string_lossy().to_string();
            if n.ends_with(".sh") || n.ends_with(".json") {
                println!("  {}", n.trim_end_matches(".sh").trim_end_matches(".json"));
            }
        }
        return Ok(());
    }

    let hook = hook.ok_or_else(|| anyhow::anyhow!("hook name required"))?;
    let file = ["sh", "json", ""]
        .iter()
        .map(|ext| {
            if ext.is_empty() {
                dir.join(&hook)
            } else {
                dir.join(format!("{hook}.{ext}"))
            }
        })
        .find(|p| p.exists())
        .ok_or_else(|| anyhow::anyhow!("hook '{hook}' not found"))?;

    let mut cmd = Command::new("bash");
    cmd.arg(&file);
    for kv in &env_overrides {
        if let Some((k, v)) = kv.split_once('=') {
            cmd.env(k.to_uppercase(), v);
        }
    }

    if std::io::IsTerminal::is_terminal(&std::io::stdin()) {
        let json = match hook.as_str() {
            "session-start" => r#"{"session_id":"test","prompt":"startup"}"#,
            "user-prompt-submit" => r#"{"prompt":"teste"}"#,
            _ => "{}",
        };
        cmd.stdin(Stdio::piped());
        let mut child = cmd.spawn()?;
        if let Some(mut stdin) = child.stdin.take() {
            use std::io::Write;
            let _ = stdin.write_all(json.as_bytes());
        }
        let s = child.wait()?;
        if !s.success() {
            bail!("hook failed");
        }
    } else {
        let s = cmd.status()?;
        if !s.success() {
            bail!("hook failed");
        }
    }
    Ok(())
}

// ── sentinel ─────────────────────────────────────────────────────

const SENTINEL_PID: &str = "/tmp/leech-sentinel.pid";

/// `leech sentinel` — keep the machine awake via systemd-inhibit.
pub fn sentinel(action: &str) -> Result<()> {
    match action {
        "start" => {
            if let Some(pid) = sentinel_pid() {
                println!("\x1b[32m● sentinel ja ativo\x1b[0m  pid={pid}");
                return Ok(());
            }
            println!("\x1b[36m→ ativando sentinel\x1b[0m  (bloqueia sleep + idle + lid-close)");
            let child = std::process::Command::new("systemd-inhibit")
                .args([
                    "--what=sleep:idle:handle-lid-switch",
                    "--who=Leech Sentinel",
                    "--why=Remote access active",
                    "--mode=block",
                    "sleep", "infinity",
                ])
                .stdout(std::process::Stdio::null())
                .stderr(std::process::Stdio::null())
                .spawn()?;
            let pid = child.id();
            std::fs::write(SENTINEL_PID, pid.to_string())?;
            std::thread::sleep(std::time::Duration::from_millis(500));
            if sentinel_pid().is_some() {
                println!("\x1b[32m● sentinel ativo\x1b[0m  pid={pid}");
                println!("\x1b[2m  pare com:     leech sentinel stop\x1b[0m");
                println!("\x1b[2m  desligue com: leech sentinel poweroff\x1b[0m");
            } else {
                let _ = std::fs::remove_file(SENTINEL_PID);
                anyhow::bail!("sentinel falhou ao iniciar");
            }
        }
        "stop" => match sentinel_pid() {
            None => println!("\x1b[2msentinel nao esta ativo\x1b[0m"),
            Some(pid) => {
                crate::exec::fire("kill", &[&pid.to_string()]);
                let _ = std::fs::remove_file(SENTINEL_PID);
                println!("\x1b[33m○ sentinel desativado\x1b[0m  pid={pid}");
            }
        },
        "status" => match sentinel_pid() {
            Some(pid) => println!("\x1b[32m● sentinel ativo\x1b[0m  pid={pid}"),
            None => println!("\x1b[31m○ sentinel inativo\x1b[0m  (use: leech sentinel start)"),
        },
        "poweroff" => {
            if let Some(pid) = sentinel_pid() {
                crate::exec::fire("kill", &[&pid.to_string()]);
                let _ = std::fs::remove_file(SENTINEL_PID);
            }
            println!("\x1b[1m\x1b[31mdesligando o computador...\x1b[0m");
            std::thread::sleep(std::time::Duration::from_secs(1));
            crate::exec::fire("systemctl", &["poweroff"]);
        }
        _ => anyhow::bail!("sentinel: acao invalida '{action}' (use start|stop|status|poweroff)"),
    }
    Ok(())
}

fn sentinel_pid() -> Option<u32> {
    let pid: u32 = std::fs::read_to_string(SENTINEL_PID).ok()?.trim().parse().ok()?;
    // Verify process is alive
    std::process::Command::new("kill")
        .args(["-0", &pid.to_string()])
        .output()
        .ok()
        .filter(|o| o.status.success())?;
    Some(pid)
}

// ── relay ────────────────────────────────────────────────────────

const RELAY_PORT: u16 = 9222;

/// `leech relay` — start, stop, or query the Chrome DevTools Protocol relay.
pub fn relay(action: &str) -> Result<()> {
    let running = || {
        crate::exec::capture(
            "curl",
            &[
                "-sf",
                &format!("http://localhost:{RELAY_PORT}/json/version"),
            ],
        )
        .is_ok_and(|s| !s.is_empty())
    };
    let pid = || {
        crate::exec::capture(
            "pgrep",
            &["-f", &format!("remote-debugging-port={RELAY_PORT}")],
        )
        .ok()
        .filter(|s| !s.is_empty())
    };

    match action {
        "start" => {
            if running() {
                println!(
                    "\x1b[32m● relay running\x1b[0m  pid={}  port={RELAY_PORT}",
                    pid().unwrap_or_default()
                );
                return Ok(());
            }
            let browser = ["google-chrome-stable", "google-chrome", "chromium"]
                .iter()
                .find(|b| crate::exec::capture("which", &[b]).is_ok_and(|s| !s.is_empty()))
                .ok_or_else(|| anyhow::anyhow!("no Chrome/Chromium in PATH"))?;
            println!("\x1b[36m→ Starting relay\x1b[0m  browser={browser}  port={RELAY_PORT}");
            Command::new(browser)
                .args([
                    &format!("--remote-debugging-port={RELAY_PORT}"),
                    "--user-data-dir=/tmp/leech-relay",
                    "--no-first-run",
                    "--no-default-browser-check",
                    "about:blank",
                ])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn()?;
            for _ in 0..10 {
                std::thread::sleep(std::time::Duration::from_millis(500));
                if running() {
                    println!("\x1b[32m● relay ready\x1b[0m");
                    return Ok(());
                }
            }
            bail!("CDP did not respond in 5s")
        }
        "stop" => {
            match pid() {
                Some(p) => {
                    crate::exec::fire("kill", &[&p]);
                    println!("\x1b[33m○ relay stopped\x1b[0m");
                }
                None => println!("\x1b[2mrelay not running\x1b[0m"),
            }
            Ok(())
        }
        "status" => {
            if running() {
                println!("\x1b[32m● relay active\x1b[0m  port={RELAY_PORT}");
            } else {
                println!("\x1b[31m○ relay inactive\x1b[0m");
            }
            Ok(())
        }
        _ => bail!("relay: unknown action '{action}'"),
    }
}

// ── inbox ────────────────────────────────────────────────────────

/// `leech inbox` — print the inbox, or append a message to it.
#[allow(dead_code)]
pub fn inbox(message: Option<String>) -> Result<()> {
    let file = paths::inbox_file().ok_or_else(|| anyhow::anyhow!("inbox not found"))?;
    match message {
        None => print!("{}", std::fs::read_to_string(&file)?),
        Some(msg) => {
            use std::io::Write;
            let mut f = std::fs::OpenOptions::new().append(true).open(&file)?;
            writeln!(f, "\n### [user] {} — nota\n\n{msg}", paths::date_iso())?;
            println!("Adicionado ao inbox.");
        }
    }
    Ok(())
}

// ── outbox ───────────────────────────────────────────────────────

/// `leech outbox` — list files waiting in the outbox directory.
pub fn outbox() -> Result<()> {
    let dir = paths::outbox_dir().ok_or_else(|| anyhow::anyhow!("outbox not found"))?;
    let entries: Vec<String> = std::fs::read_dir(&dir)?
        .flatten()
        .map(|e| e.file_name().to_string_lossy().to_string())
        .collect();
    if entries.is_empty() {
        println!("Outbox vazio.");
    } else {
        println!("Outbox:");
        for e in &entries {
            println!("  {e}");
        }
    }
    Ok(())
}

// ── man / help ───────────────────────────────────────────────────

/// `leech man` — GNU-style man page.
pub fn man() -> Result<()> {
    crate::help::man_page();
    Ok(())
}

/// `leech banner` — display the Leech ASCII banner.
pub fn help_banner() -> Result<()> {
    println!("{}", crate::help::BANNER);
    Ok(())
}

// ── claude usage / token ─────────────────────────────────────────

/// `leech usage` — run the Claude usage stats script, optionally for Waybar output.
pub fn usage(waybar: bool, no_cache: bool) -> Result<()> {
    let script = paths::usage_script().ok_or_else(|| anyhow::anyhow!("usage script not found"))?;
    let mut args = vec![script.to_string_lossy().to_string()];
    if waybar {
        args.push("--waybar".into());
    }
    if no_cache {
        args.push("--refresh".into());
    }
    crate::exec::run("bash", &args.iter().map(|s| s.as_str()).collect::<Vec<_>>())
}

/// `leech token` — print the Claude OAuth access token from local credentials.
pub fn token() -> Result<()> {
    let creds = paths::home().join(".claude/.credentials.json");
    if !creds.exists() {
        bail!("credentials not found: {}", creds.display());
    }
    let content = std::fs::read_to_string(&creds)?;
    let tok = content
        .split("\"accessToken\"")
        .nth(1)
        .and_then(|r| {
            let r = r.trim_start().trim_start_matches(':').trim_start();
            let inner = r.strip_prefix('"')?;
            inner.find('"').map(|end| inner[..end].to_string())
        })
        .ok_or_else(|| anyhow::anyhow!("token not found"))?;
    println!("{tok}");
    Ok(())
}
