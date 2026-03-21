//! Docker commands — build, stop, and clean container infrastructure.

use anyhow::Result;
use zion_sdk::{compose::ComposeCmd, paths};

/// `zion build` — build Docker image.
pub fn build(no_cache: bool) -> Result<()> {
    println!("Building claude-nix-sandbox image...");
    let mut args = vec!["build"];
    if no_cache {
        args.push("--no-cache");
    }
    args.push("leech");
    Ok(ComposeCmd::new().execute(&args)?)
}

/// `zion down` — stop compose containers.
pub fn down() -> Result<()> {
    let zion = paths::zion_root();
    println!("Stopping zion containers...");
    crate::exec::fire(
        "docker",
        &[
            "compose",
            "-f",
            &zion.join("container/docker-compose.zion.yml").to_string_lossy(),
            "down",
        ],
    );
    let puppy = zion.join("container/docker-compose.puppy.yml");
    if puppy.exists() {
        crate::exec::fire(
            "docker",
            &["compose", "-f", &puppy.to_string_lossy(), "down"],
        );
    }
    println!("Done.");
    Ok(())
}

/// `zion shutdown` — stop compose + kill strays.
pub fn shutdown() -> Result<()> {
    down()?;
    println!("Killing stray containers...");
    let names = crate::exec::capture_lines("docker", &["ps", "-a", "--format", "{{.Names}}"])?;
    let strays: Vec<&str> = names
        .iter()
        .map(|s| s.as_str())
        .filter(|n| {
            let l = n.to_lowercase();
            l.contains("zion") || l.contains("claude") || l.contains("leech") || l.contains("puppy")
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

/// `zion clean` — remove stopped containers.
pub fn clean(force: bool) -> Result<()> {
    println!("=== Stopped Zion containers ===");
    let stopped = crate::exec::capture_lines(
        "docker",
        &[
            "ps",
            "-a",
            "--filter",
            "name=zion-",
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
