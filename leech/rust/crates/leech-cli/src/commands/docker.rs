//! Docker commands — build, stop, and clean container infrastructure.

use anyhow::Result;
use leech_cli::{compose::ComposeCmd, paths};

/// `leech build` — build Docker image.
/// With `--danger`: rebuild leech-base:latest first (refreshes cursor-agent, nix packages).
pub fn build(danger: bool) -> Result<()> {
    let base_ctx = paths::container_dir();

    if danger {
        println!("leech-base:latest — rebuild forçado (--danger)...");
        let status = std::process::Command::new("docker")
            .args([
                "build",
                "--no-cache",
                "-f",
                &base_ctx.join("Dockerfile.claude.base").to_string_lossy(),
                "-t",
                "leech-base:latest",
                &base_ctx.to_string_lossy(),
            ])
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .map_err(|e| anyhow::anyhow!("docker build leech-base failed: {e}"))?;
        if !status.success() {
            anyhow::bail!("Error: failed to build leech-base:latest");
        }
    }

    println!("Building leech image...");
    let mut args = vec!["build"];
    if danger {
        args.push("--no-cache");
    }
    args.push("leech");
    Ok(ComposeCmd::new().execute(&args)?)
}

/// `leech stop` — stop compose containers.
pub fn down() -> Result<()> {
    let leech = paths::leech_root();
    println!("Stopping leech containers...");
    crate::exec::fire(
        "docker",
        &[
            "compose",
            "-f",
            &leech.join("containers/leech/docker-compose.leech.yml").to_string_lossy(),
            "down",
        ],
    );
    println!("Done.");
    Ok(())
}

/// `leech shutdown` — stop compose + kill strays.
pub fn shutdown() -> Result<()> {
    down()?;
    println!("Killing stray containers...");
    let names = crate::exec::capture_lines("docker", &["ps", "-a", "--format", "{{.Names}}"])?;
    let strays: Vec<&str> = names
        .iter()
        .map(|s| s.as_str())
        .filter(|n| {
            let l = n.to_lowercase();
            l.contains("leech") || l.contains("claude")
        })
        .collect();
    if strays.is_empty() {
        println!("  (none)");
    } else {
        for s in &strays {
            crate::exec::fire("docker", &["rm", "-f", s]);
        }
        println!("Removed: {}", strays.join(", "));
    }
    Ok(())
}

/// `leech destroy` — remove containers, volumes, and leech image (full reset).
pub fn destroy() -> Result<()> {
    let leech = paths::leech_root();
    let compose = leech.join("containers/leech/docker-compose.leech.yml");
    let compose_s = compose.to_string_lossy();

    println!("Destroying leech session containers + volumes...");
    crate::exec::fire(
        "docker",
        &["compose", "-f", &compose_s, "down", "--volumes", "--remove-orphans"],
    );

    println!("Removing leech image...");
    let s = std::process::Command::new("docker")
        .args(["image", "rm", "leech"])
        .output()?;
    if !s.status.success() {
        println!("  (image not found or in use)");
    }

    println!("Done.");
    Ok(())
}

/// `leech clean` — remove stopped containers.
pub fn clean(force: bool) -> Result<()> {
    println!("=== Stopped Leech containers ===");
    let stopped = crate::exec::capture_lines(
        "docker",
        &[
            "ps",
            "-a",
            "--filter",
            "name=leech-",
            "--filter",
            "status=exited",
            "--format",
            "{{.Names}}",
        ],
    )?;
    if stopped.is_empty() {
        println!("  None.");
    } else {
        for s in &stopped {
            println!("{s}");
        }
        if force {
            for s in &stopped {
                crate::exec::fire("docker", &["rm", s]);
            }
            println!("  Removed.");
        } else {
            println!("  Use --force to remove.");
        }
    }
    Ok(())
}
