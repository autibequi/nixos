//! Host commands — stow, NixOS builds, config init, and CLI installation.

use std::io::Write;
use std::process::Command;

use anyhow::{bail, Result};
use leech_cli::paths;

// ── stow ─────────────────────────────────────────────────────────

/// `leech stow` — deploy dotfiles via GNU stow (restow/delete/status).
pub fn stow(action: &str, reload: bool) -> Result<()> {
    crate::exec::require_host()?;
    let nixos = paths::nixos_dir();
    let home = paths::home().to_string_lossy().to_string();

    match action {
        "status" | "st" => {
            println!("=== Stow status ===");
            crate::exec::run_in(
                &nixos,
                "stow",
                &["-d", "stow", "-t", &home, "-n", "-R", "."],
            )
        }
        a @ ("restow" | "re" | "" | "delete" | "un" | "unstow") => {
            let flag = if a.starts_with('d') || a.starts_with('u') {
                "-D"
            } else {
                "-R"
            };
            println!("=== Stow {a} ===");
            crate::exec::run_in(&nixos, "stow", &["-d", "stow", "-t", &home, flag, "."])?;
            if reload {
                println!("=== Reloading Hyprland + Waybar ===");
                crate::exec::fire("hyprctl", &["reload"]);
                crate::exec::fire("pkill", &["-SIGUSR2", "waybar"]);
            }
            Ok(())
        }
        _ => bail!("unknown stow action: {action} (use restow|delete|status)"),
    }
}

// ── os ───────────────────────────────────────────────────────────

/// `leech os` — run a NixOS operation (switch/test/boot/build) via `nh`.
pub fn os(action: &str) -> Result<()> {
    crate::exec::require_host()?;
    crate::exec::run("nh", &["os", action, &paths::nixos_dir().to_string_lossy()])
}

// ── init ─────────────────────────────────────────────────────────

/// `leech init` — create the `~/.leech` config file from a template.
#[allow(dead_code)]
pub fn init(force: bool) -> Result<()> {
    let dest = paths::home().join(".leech");
    if dest.exists() && !force {
        println!(
            "{} already exists. Use --force to overwrite.",
            dest.display()
        );
        return Ok(());
    }
    let example = paths::cli_dir().join("config.example");
    if example.exists() {
        std::fs::copy(&example, &dest)?;
    } else {
        std::fs::write(&dest, "# Leech config\nengine=claude\n# model=sonnet\n")?;
    }
    println!("Created {}", dest.display());
    Ok(())
}

// ── set ──────────────────────────────────────────────────────────

/// `leech set` — update the `engine=` line in `~/.leech`.
pub fn set_engine(engine: &str) -> Result<()> {
    match engine {
        "claude" | "opencode" | "cursor" => {}
        _ => bail!("invalid engine '{}' (use: claude|opencode|cursor)", engine),
    }
    let path = std::env::var("LEECH_CONFIG")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| paths::home().join(".leech"));
    if !path.exists() {
        bail!("{} not found — run 'leech init' first", path.display());
    }

    let content = std::fs::read_to_string(&path)?;
    let mut found = false;
    let new: Vec<String> = content
        .lines()
        .map(|l| {
            if l.starts_with("engine=") {
                found = true;
                format!("engine={engine}")
            } else {
                l.to_string()
            }
        })
        .collect();
    let out = if found {
        new.join("\n") + "\n"
    } else {
        format!("{}\nengine={engine}\n", new.join("\n"))
    };
    std::fs::write(&path, out)?;
    println!("[leech set] engine={engine} -> {}", path.display());
    Ok(())
}

// ── update ───────────────────────────────────────────────────────

const SPINNER: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

/// `leech update` — build the Rust binary and install it.
pub fn update() -> Result<()> {
    let nixos = paths::nixos_dir();
    let clirust = paths::rust_dir();
    let bin = paths::bin_dir();

    println!("\x1b[1mAtualizando leech...\x1b[0m");

    step(1, 2, "Atualizando bootstrap", || {
        let src = nixos.join("leech/scripts/bootstrap-dashboard.sh");
        let dst = nixos.join("scripts/bootstrap.sh");
        if src.exists() {
            std::fs::copy(&src, &dst)?;
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                std::fs::set_permissions(&dst, std::fs::Permissions::from_mode(0o755))?;
            }
        }
        Ok(())
    })?;

    step(2, 2, "Building leech (rust)", || {
        if !clirust.exists() {
            return Ok(());
        }
        // Tenta: 1) cargo direto (rustup ou nix package), 2) nix-shell como fallback
        let cargo_ok = Command::new("cargo")
            .args(["build", "--release", "-p", "leech-cli"])
            .current_dir(&clirust)
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);
        if !cargo_ok {
            let s = Command::new("nix-shell")
                .args(["-p", "rustc", "-p", "cargo", "--run",
                       "cargo build --release -p leech-cli"])
                .current_dir(&clirust)
                .output()?;
            if !s.status.success() {
                bail!(
                    "cargo build failed:\n{}",
                    String::from_utf8_lossy(&s.stderr)
                );
            }
        }
        let src = clirust.join("target/release/leech");
        let dst = bin.join("leech");
        let _ = std::fs::remove_file(&dst);
        std::fs::copy(&src, &dst)?;
        Ok(())
    })?;

    println!("  \x1b[32m\x1b[1mFeito!\x1b[0m");
    Ok(())
}

fn step<F: FnOnce() -> Result<()>>(n: u32, total: u32, label: &str, f: F) -> Result<()> {
    print!(
        "\r  \x1b[2m[{n}/{total}]\x1b[0m {label} \x1b[33m{}\x1b[0m",
        SPINNER[0]
    );
    let _ = std::io::stdout().flush();
    match f() {
        Ok(()) => {
            println!("\r  \x1b[2m[{n}/{total}]\x1b[0m {label} \x1b[32m✓\x1b[0m");
            Ok(())
        }
        Err(e) => {
            println!("\r  \x1b[2m[{n}/{total}]\x1b[0m {label} \x1b[31m✗\x1b[0m");
            Err(e)
        }
    }
}
