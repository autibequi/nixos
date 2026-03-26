//! Docker commands — build, stop, and clean container infrastructure.

use anyhow::Result;
use leech_sdk::{compose::ComposeCmd, paths};

/// Print verbose command log if LEECH_VERBOSE is set.
fn verbose_cmd(program: &str, args: &[&str]) {
    if std::env::var("LEECH_VERBOSE").as_deref() == Ok("1") {
        eprintln!("\x1b[2m[VERBOSE]\x1b[0m $ {} {}", program, args.join(" "));
    }
}

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
    let compose_path = leech.join("containers/leech/docker-compose.leech.yml");
    let compose_str = compose_path.to_string_lossy().into_owned();
    let args = vec!["compose", "-f", &compose_str, "down"];
    verbose_cmd("docker", &args);
    crate::exec::fire("docker", &args);
    println!("Done.");
    Ok(())
}

/// `leech shutdown` — stop compose + kill strays.
pub fn shutdown() -> Result<()> {
    down()?;
    println!("Killing stray containers...");
    let args_ps = vec!["ps", "-a", "--format", "{{.Names}}"];
    verbose_cmd("docker", &args_ps);
    let names = crate::exec::capture_lines("docker", &args_ps)?;
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
            let args_rm = vec!["rm", "-f", s];
            verbose_cmd("docker", &args_rm);
            crate::exec::fire("docker", &args_rm);
        }
        println!("Removed: {}", strays.join(", "));
    }
    Ok(())
}

/// `leech clean` — remove stopped containers.
pub fn clean(force: bool) -> Result<()> {
    println!("=== Stopped Leech containers ===");
    let args = vec![
        "ps",
        "-a",
        "--filter",
        "name=leech-",
        "--filter",
        "status=exited",
        "--format",
        "{{.Names}}",
    ];
    verbose_cmd("docker", &args);
    let stopped = crate::exec::capture_lines("docker", &args)?;
    if stopped.is_empty() {
        println!("  None.");
    } else {
        for s in &stopped {
            println!("{s}");
        }
        if force {
            for s in &stopped {
                let args_rm = vec!["rm", s];
                verbose_cmd("docker", &args_rm);
                crate::exec::fire("docker", &args_rm);
            }
            println!("  Removed.");
        } else {
            println!("  Use --force to remove.");
        }
    }
    Ok(())
}
