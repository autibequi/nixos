//! Tmux commands — shared session host ↔ container.

use anyhow::{bail, Result};
use std::process::Command;

const SOCKET_DIR: &str = "/run/user/1000/zion-tmux";
const SOCKET: &str = "/run/user/1000/zion-tmux/tmux.sock";
const SESSION: &str = "main";

/// Resolve the tmux binary path. On NixOS tmux may not be in $PATH but lives
/// at a well-known nix store symlink under /run/current-system.
fn tmux_bin() -> Option<&'static str> {
    const CANDIDATES: &[&str] = &[
        "/run/current-system/sw/bin/tmux", // NixOS host
        "/root/.nix-profile/bin/tmux",     // nix-env install (container root)
        "/home/claude/.nix-profile/bin/tmux",
        "/usr/bin/tmux",
        "/usr/local/bin/tmux",
    ];
    for p in CANDIDATES {
        if std::path::Path::new(p).exists() {
            return Some(p);
        }
    }
    // last resort: check $PATH via `which`
    if Command::new("which").arg("tmux").output().map(|o| o.status.success()).unwrap_or(false) {
        return Some("tmux");
    }
    None
}

fn require_tmux() -> Result<&'static str> {
    tmux_bin().ok_or_else(|| anyhow::anyhow!(
        "tmux não encontrado.\n\
         Instale com:  leech os switch   (adiciona tmux ao NixOS)\n\
         Ou temporário: nix-shell -p tmux"
    ))
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

/// `leech tmux serve` — start server + session, attach interactively, kill server on exit.
///
/// Lifetime of the server = lifetime of this command. When user closes all
/// windows or detaches, the session ends and the server is killed.
pub fn serve() -> Result<()> {
    let bin = require_tmux()?;

    // Ensure socket directory exists with open permissions (container runs as root)
    use std::os::unix::fs::PermissionsExt;
    std::fs::create_dir_all(SOCKET_DIR)?;
    let _ = std::fs::set_permissions(SOCKET_DIR, std::fs::Permissions::from_mode(0o777));

    // Kill any stale server from a previous crashed session
    if server_running() {
        let _ = Command::new(bin).args(["-S", SOCKET, "kill-server"]).output();
    }

    // Start session detached — single window, single pane
    Command::new(bin)
        .args(["-S", SOCKET, "new-session", "-d", "-s", SESSION, "-x", "220", "-y", "50"])
        .output()?;

    // Security: kill any new window or session created via the socket
    // Prevents hidden workspaces being used as a backdoor
    Command::new(bin).args(["-S", SOCKET, "set-hook", "-g",
        "after-new-window", "kill-window"]).output()?;
    Command::new(bin).args(["-S", SOCKET, "set-hook", "-g",
        "after-new-session", "kill-session"]).output()?;

    // Make socket world-accessible so container (root) can reach it
    let _ = std::fs::set_permissions(SOCKET, std::fs::Permissions::from_mode(0o666));

    // Attach interactively — blocks until user exits or closes all windows
    Command::new(bin)
        .args(["-S", SOCKET, "attach", "-t", SESSION])
        .status()?;

    // Session ended — kill server
    let _ = Command::new(bin).args(["-S", SOCKET, "kill-server"]).output();

    Ok(())
}

/// `leech tmux open` — attach to existing shared session (exec, replaces process).
/// Used from inside the container to attach to a host-side serve session.
pub fn open() -> Result<()> {
    let bin = require_tmux()?;

    if !server_running() {
        bail!("zion-tmux server not running — start with: leech tmux serve (on the host)");
    }

    // Create session if it doesn't exist yet
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

    // exec — replaces leech process with interactive tmux
    use std::os::unix::process::CommandExt;
    let err = Command::new(bin)
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

/// `leech tmux install` — install tmux into the nix profile (container or host).
pub fn install() -> Result<()> {
    if tmux_bin().is_some() {
        println!("tmux já instalado em: {}", tmux_bin().unwrap());
        return Ok(());
    }
    println!("Instalando tmux via nix-env...");
    let status = Command::new("nix-env")
        .args(["-iA", "nixpkgs.tmux"])
        .status()?;
    if !status.success() {
        bail!("nix-env falhou — tente: nix-shell -p tmux");
    }
    println!("✓ tmux instalado em ~/.nix-profile/bin/tmux");
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
