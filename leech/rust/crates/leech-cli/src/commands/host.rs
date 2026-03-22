//! Host commands — stow, NixOS builds, config init, and CLI installation.

use std::io::Write;
use std::process::Command;

use anyhow::{bail, Result};
use leech_sdk::paths;

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

/// `leech update` — regenerate bash CLI, install symlinks, and build the Rust binary.
pub fn update() -> Result<()> {
    let nixos = paths::nixos_dir();
    let cli = paths::cli_dir();
    let clirust = paths::rust_dir();
    let bin = paths::bin_dir();

    println!("\x1b[1mAtualizando leech...\x1b[0m");

    step(1, 4, "Gerando bash CLI", || {
        // Try bashly directly; fallback to nix-shell if not in PATH.
        let direct = Command::new("bashly")
            .arg("generate")
            .current_dir(&cli)
            .env("LANG", "en_US.UTF-8")
            .env("RUBYOPT", "-E utf-8")
            .output();

        let s = match direct {
            Ok(out) => out,
            Err(_) => Command::new("nix-shell")
                .args(["-p", "bashly", "--run", "bashly generate"])
                .current_dir(&cli)
                .env("LANG", "en_US.UTF-8")
                .env("RUBYOPT", "-E utf-8")
                .output()?,
        };
        if !s.status.success() {
            bail!(
                "bashly generate failed:\n{}",
                String::from_utf8_lossy(&s.stderr)
            );
        }
        Ok(())
    })?;

    step(2, 4, "Instalando bash CLI", || {
        std::fs::create_dir_all(&bin)?;
        let old = nixos.join("stow/.local/bin/leech");
        if old.is_symlink() {
            let _ = std::fs::remove_file(&old);
        }
        let dest = bin.join("leech-bash");
        let _ = std::fs::remove_file(&dest);
        std::os::unix::fs::symlink(cli.join("leech"), &dest)?;
        Ok(())
    })?;

    step(3, 4, "Atualizando bootstrap", || {
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

    step(4, 4, "Building leech (rust)", || {
        if !clirust.exists() {
            return Ok(());
        }
        let ok = Command::new("nix-shell")
            .args(["-p", "rustc", "cargo", "--run", "cargo build --release"])
            .current_dir(&clirust)
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);
        if !ok {
            let s = Command::new("cargo")
                .args(["build", "--release"])
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
