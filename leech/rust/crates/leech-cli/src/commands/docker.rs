//! Docker commands — build, stop, and clean container infrastructure.

use anyhow::Result;
use leech_cli::{compose::ComposeCmd, paths};

/// `leech build` — build Docker image.
pub fn build(no_cache: bool) -> Result<()> {
    println!("Building claude-nix-sandbox image...");
    let mut args = vec!["build"];
    if no_cache {
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
