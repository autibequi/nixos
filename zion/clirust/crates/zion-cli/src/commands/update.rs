use std::io::Write;
use std::process::Command;

use anyhow::{bail, Result};
use zion_sdk::paths;

const SPINNER: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

/// Build and install both bash CLI (bashly) and Rust CLI.
pub fn execute() -> Result<()> {
    let nixos_dir = paths::nixos_dir();
    let cli_dir = nixos_dir.join("zion/cli");
    let clirust_dir = nixos_dir.join("zion/clirust");
    let home = paths::home();
    let bin_dir = home.join(".local/bin");

    println!("\x1b[1mAtualizando zion...\x1b[0m");

    // 1. bashly generate
    run_step(1, 4, "Gerando bash CLI", || {
        let s = Command::new("bashly")
            .arg("generate")
            .current_dir(&cli_dir)
            .env("LANG", "en_US.UTF-8")
            .env("RUBYOPT", "-E utf-8")
            .output()?;
        if !s.status.success() {
            bail!(
                "bashly generate failed:\n{}",
                String::from_utf8_lossy(&s.stderr)
            );
        }
        Ok(())
    })?;

    // 2. symlink bash CLI
    run_step(2, 4, "Instalando symlink bash", || {
        std::fs::create_dir_all(&bin_dir)?;
        let dest = bin_dir.join("zion");
        // Remove old stow-based symlink if present
        let old = nixos_dir.join("stow/.local/bin/zion");
        if old.is_symlink() {
            let _ = std::fs::remove_file(&old);
        }
        // Force-create symlink
        let _ = std::fs::remove_file(&dest);
        std::os::unix::fs::symlink(cli_dir.join("zion"), &dest)?;
        Ok(())
    })?;

    // 3. bootstrap dashboard
    run_step(3, 4, "Atualizando bootstrap", || {
        let src = nixos_dir.join("zion/scripts/bootstrap-dashboard.sh");
        let dst = nixos_dir.join("scripts/bootstrap.sh");
        if src.exists() {
            std::fs::copy(&src, &dst)?;
            // chmod 755
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                std::fs::set_permissions(&dst, std::fs::Permissions::from_mode(0o755))?;
            }
        }
        Ok(())
    })?;

    // 4. build + install Rust CLI
    run_step(4, 4, "Building zionrust", || {
        if !clirust_dir.exists() {
            return Ok(()); // skip if clirust doesn't exist yet
        }

        // Try nix-shell first, fallback to cargo
        let build_ok = Command::new("nix-shell")
            .args(["-p", "rustc", "cargo", "--run", "cargo build --release"])
            .current_dir(&clirust_dir)
            .output()
            .map(|o| o.status.success())
            .unwrap_or(false);

        if !build_ok {
            let s = Command::new("cargo")
                .args(["build", "--release"])
                .current_dir(&clirust_dir)
                .output()?;
            if !s.status.success() {
                bail!(
                    "cargo build failed:\n{}",
                    String::from_utf8_lossy(&s.stderr)
                );
            }
        }

        let src = clirust_dir.join("target/release/zionrust");
        let dst = bin_dir.join("zionrust");
        let _ = std::fs::remove_file(&dst);
        std::fs::copy(&src, &dst)?;
        Ok(())
    })?;

    println!("  \x1b[32m\x1b[1mFeito!\x1b[0m");
    Ok(())
}

/// Run a step with a spinner, showing ✓ or ✗.
fn run_step<F>(n: u32, total: u32, label: &str, f: F) -> Result<()>
where
    F: FnOnce() -> Result<()>,
{
    // Show spinner start
    print!(
        "\r  \x1b[2m[{}/{}]\x1b[0m {} \x1b[33m{}\x1b[0m",
        n, total, label, SPINNER[0]
    );
    let _ = std::io::stdout().flush();

    match f() {
        Ok(()) => {
            println!(
                "\r  \x1b[2m[{}/{}]\x1b[0m {} \x1b[32m✓\x1b[0m",
                n, total, label
            );
            Ok(())
        }
        Err(e) => {
            println!(
                "\r  \x1b[2m[{}/{}]\x1b[0m {} \x1b[31m✗\x1b[0m",
                n, total, label
            );
            Err(e)
        }
    }
}
