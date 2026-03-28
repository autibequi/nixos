//! Tmux shared session — host ↔ container.

use anyhow::{bail, Result};
use std::process::Command;

const SOCKET_DIR: &str = "/run/user/1000/yaa-tmux";
const SOCKET: &str = "/run/user/1000/yaa-tmux/tmux.sock";
const SESSION: &str = "main";

fn tmux_bin() -> Option<&'static str> {
    const CANDIDATES: &[&str] = &[
        "/run/current-system/sw/bin/tmux",
        "/root/.nix-profile/bin/tmux",
        "/home/claude/.nix-profile/bin/tmux",
        "/usr/bin/tmux",
        "/usr/local/bin/tmux",
    ];
    for p in CANDIDATES {
        if std::path::Path::new(p).exists() {
            return Some(p);
        }
    }
    if Command::new("which")
        .arg("tmux")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
    {
        return Some("tmux");
    }
    None
}

fn require_tmux() -> Result<&'static str> {
    tmux_bin().ok_or_else(|| {
        anyhow::anyhow!("tmux not found.\nInstall: nix-shell -p tmux")
    })
}

fn tmux_cmd(args: &[&str]) -> Result<std::process::Output> {
    Ok(Command::new(require_tmux()?)
        .args(["-S", SOCKET])
        .args(args)
        .output()?)
}

fn server_running() -> bool {
    let Some(bin) = tmux_bin() else { return false };
    Command::new(bin)
        .args(["-S", SOCKET, "info"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

/// `yaa tmux serve` — start server + session, attach interactively.
pub fn serve() -> Result<()> {
    let bin = require_tmux()?;

    use std::os::unix::fs::PermissionsExt;
    std::fs::create_dir_all(SOCKET_DIR)?;
    let _ = std::fs::set_permissions(SOCKET_DIR, std::fs::Permissions::from_mode(0o777));

    if server_running() {
        let _ = Command::new(bin).args(["-S", SOCKET, "kill-server"]).output();
    }

    Command::new(bin)
        .args(["-S", SOCKET, "new-session", "-d", "-s", SESSION, "-x", "220", "-y", "50"])
        .output()?;

    // Security: block extra windows/sessions
    Command::new(bin)
        .args(["-S", SOCKET, "set-hook", "-g", "after-new-window", "kill-window"])
        .output()?;
    Command::new(bin)
        .args(["-S", SOCKET, "set-hook", "-g", "after-new-session", "kill-session"])
        .output()?;

    let _ = std::fs::set_permissions(SOCKET, std::fs::Permissions::from_mode(0o666));

    Command::new(bin)
        .args(["-S", SOCKET, "attach", "-t", SESSION])
        .status()?;

    let _ = Command::new(bin).args(["-S", SOCKET, "kill-server"]).output();
    Ok(())
}

/// `yaa tmux open` — attach to existing shared session (from container).
pub fn open() -> Result<()> {
    let bin = require_tmux()?;

    if !server_running() {
        bail!("tmux server not running — start with: yaa tmux serve (on the host)");
    }

    let has = Command::new(bin)
        .args(["-S", SOCKET, "has-session", "-t", SESSION])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);

    if !has {
        Command::new(bin)
            .args(["-S", SOCKET, "new-session", "-d", "-s", SESSION, "-x", "220", "-y", "50"])
            .output()?;
    }

    use std::os::unix::process::CommandExt;
    let err = Command::new(bin)
        .args(["-S", SOCKET, "attach", "-t", SESSION])
        .exec();
    bail!("exec tmux: {err}");
}

/// `yaa tmux run <cmd>` — send command and capture output.
pub fn run(cmd: &[String]) -> Result<()> {
    if cmd.is_empty() {
        bail!("usage: yaa tmux run <command>");
    }
    if !server_running() {
        bail!("tmux server not running — start with: yaa tmux serve");
    }
    let full = cmd.join(" ");
    let out = tmux_cmd(&["send-keys", "-t", SESSION, &full, "Enter"])?;
    if !out.status.success() {
        bail!("send-keys: {}", String::from_utf8_lossy(&out.stderr));
    }
    std::thread::sleep(std::time::Duration::from_millis(500));
    capture()
}

/// `yaa tmux capture` — capture current pane output.
pub fn capture() -> Result<()> {
    if !server_running() {
        bail!("tmux server not running");
    }
    let out = tmux_cmd(&["capture-pane", "-t", SESSION, "-p", "-e"])?;
    if !out.status.success() {
        bail!("capture-pane: {}", String::from_utf8_lossy(&out.stderr));
    }
    print!("{}", String::from_utf8_lossy(&out.stdout));
    Ok(())
}

/// `yaa tmux status` — show server state.
pub fn status() -> Result<()> {
    if server_running() {
        println!("tmux server: \x1b[32mrunning\x1b[0m");
        println!("socket: {SOCKET}");
        let sess = tmux_cmd(&["list-sessions"])?;
        for line in String::from_utf8_lossy(&sess.stdout).lines() {
            println!("  {line}");
        }
    } else {
        println!("tmux server: \x1b[31mnot running\x1b[0m");
        println!("start: yaa tmux serve");
    }
    Ok(())
}

/// Dispatch tmux action.
pub fn dispatch(action: &str, args: &[String]) -> Result<()> {
    match action {
        "serve" => serve(),
        "open" => open(),
        "run" => run(args),
        "capture" => capture(),
        "status" => status(),
        _ => bail!("unknown tmux action: {action}\nValid: serve, open, run, capture, status"),
    }
}
