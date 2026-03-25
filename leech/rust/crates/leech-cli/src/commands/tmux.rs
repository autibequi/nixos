//! Tmux commands — shared session host ↔ container.

use anyhow::{bail, Result};
use std::process::Command;

const SOCKET: &str = "/run/user/1000/zion-tmux.sock";
const SESSION: &str = "main";

fn tmux_cmd(args: &[&str]) -> Result<std::process::Output> {
    Ok(Command::new("tmux")
        .args(["-S", SOCKET])
        .args(args)
        .output()?)
}

fn server_running() -> bool {
    Command::new("tmux")
        .args(["-S", SOCKET, "info"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

/// `leech tmux serve` — start server + session, attach interactively, kill server on exit.
///
/// Lifetime of the server = lifetime of this command. When user closes all
/// windows or detaches, the session ends and the server is killed.
pub fn serve() -> Result<()> {
    // Kill any stale server from a previous crashed session
    if server_running() {
        let _ = Command::new("tmux")
            .args(["-S", SOCKET, "kill-server"])
            .output();
    }

    // new-session without -d → foreground, attaches current terminal
    // When user exits/closes all windows, this returns.
    Command::new("tmux")
        .args(["-S", SOCKET, "new-session", "-s", SESSION, "-x", "220", "-y", "50"])
        .status()?;

    // Session ended — kill server (no-op if already gone)
    let _ = Command::new("tmux")
        .args(["-S", SOCKET, "kill-server"])
        .output();

    Ok(())
}

/// `leech tmux open` — attach to existing shared session (exec, replaces process).
/// Used from inside the container to attach to a host-side serve session.
pub fn open() -> Result<()> {
    if !server_running() {
        bail!("zion-tmux server not running — start with: leech tmux serve (on the host)");
    }

    // Create session if it doesn't exist yet
    let has = Command::new("tmux")
        .args(["-S", SOCKET, "has-session", "-t", SESSION])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false);

    if !has {
        Command::new("tmux")
            .args(["-S", SOCKET, "new-session", "-d", "-s", SESSION, "-x", "220", "-y", "50"])
            .output()?;
    }

    // exec — replaces leech process with interactive tmux
    use std::os::unix::process::CommandExt;
    let err = Command::new("tmux")
        .args(["-S", SOCKET, "attach", "-t", SESSION])
        .exec();
    bail!("exec tmux: {err}");
}

/// `leech tmux run <cmd>` — send command to shared session and capture output.
pub fn run(cmd: &[String]) -> Result<()> {
    if cmd.is_empty() {
        bail!("usage: leech tmux run <command>");
    }
    if !server_running() {
        bail!("zion-tmux server not running — start with: leech tmux serve (on the host)");
    }
    let full = cmd.join(" ");
    let out = tmux_cmd(&["send-keys", "-t", SESSION, &full, "Enter"])?;
    if !out.status.success() {
        bail!("send-keys: {}", String::from_utf8_lossy(&out.stderr));
    }
    // Wait for command to start then capture
    std::thread::sleep(std::time::Duration::from_millis(500));
    capture()
}

/// `leech tmux capture` — capture current pane output.
pub fn capture() -> Result<()> {
    if !server_running() {
        bail!("zion-tmux server not running");
    }
    let out = tmux_cmd(&["capture-pane", "-t", SESSION, "-p", "-e"])?;
    if !out.status.success() {
        bail!("capture-pane: {}", String::from_utf8_lossy(&out.stderr));
    }
    print!("{}", String::from_utf8_lossy(&out.stdout));
    Ok(())
}

/// `leech tmux status` — show server and session state.
pub fn status() -> Result<()> {
    if server_running() {
        println!("✓  zion-tmux server  \x1b[32mrunning\x1b[0m");
        println!("   socket: {SOCKET}");
        let sess = tmux_cmd(&["list-sessions"])?;
        let s = String::from_utf8_lossy(&sess.stdout);
        for line in s.lines() {
            println!("   {line}");
        }
    } else {
        println!("✗  zion-tmux server  \x1b[31mnot running\x1b[0m");
        println!("   start: leech tmux serve");
    }
    Ok(())
}
