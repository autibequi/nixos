use anyhow::{bail, Result};

use crate::compose;
use crate::config::{self, VennonConfig};
use crate::containers;
use crate::exec;

/// Dispatch a container action.
pub fn dispatch(name: &str, action: &str, config: &VennonConfig) -> Result<()> {
    // Generate/update compose file
    let compose_data = containers::get_compose(name, config)?;
    let compose_path = config::containers_dir()
        .join(name)
        .join("docker-compose.yml");
    compose::write_compose(&compose_data, &compose_path)?;

    match action {
        "start" => start(name, &compose_path, config),
        "build" => build(name, config),
        "stop" => stop(name, &compose_path),
        "flush" => flush(name, &compose_path),
        "shell" => shell(name, &compose_path, config),
        _ => bail!("unknown action: {action}\nValid: start, build, stop, flush, shell"),
    }
}

/// Check if a podman image exists locally.
fn image_exists(name: &str) -> bool {
    std::process::Command::new("podman")
        .args(["image", "exists", name])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

/// Ensure the image is built, auto-build if missing.
fn ensure_image(name: &str, config: &VennonConfig) -> Result<()> {
    let image = format!("vennon-{name}");
    if !image_exists(&image) {
        println!("Image {image} not found, building...");
        build(name, config)?;
    }
    Ok(())
}

/// Start container and exec into it (launches claude code).
fn start(name: &str, compose_path: &std::path::Path, config: &VennonConfig) -> Result<()> {
    ensure_image(name, config)?;

    let compose_str = compose_path.to_string_lossy();
    let project = format!("vennon-{name}");

    // Always run up -d (idempotent — recreates if compose changed, noop if same)
    exec::run(
        "podman-compose",
        &["-f", &compose_str, "-p", &project, "up", "-d"],
    )?;

    let cid = find_container(name)?;

    exec::clear_screen();

    let cmd = containers::start_cmd(name);
    exec::exec_replace(
        "podman",
        &["exec", "-it", &cid, "/bin/bash", "-c", &cmd],
    );
}

/// Open a bash shell inside the container.
fn shell(name: &str, compose_path: &std::path::Path, config: &VennonConfig) -> Result<()> {
    ensure_image(name, config)?;

    let compose_str = compose_path.to_string_lossy();
    let project = format!("vennon-{name}");
    exec::run(
        "podman-compose",
        &["-f", &compose_str, "-p", &project, "up", "-d"],
    )?;

    let cid = find_container(name)?;

    exec::exec_replace(
        "podman",
        &[
            "exec",
            "-it",
            &cid,
            "/bin/bash",
            "-c",
            containers::shell_cmd(),
        ],
    );
}

/// Stop the container.
fn stop(name: &str, compose_path: &std::path::Path) -> Result<()> {
    let compose_str = compose_path.to_string_lossy();
    let project = format!("vennon-{name}");
    println!("Stopping vennon-{name}...");
    exec::run(
        "podman-compose",
        &["-f", &compose_str, "-p", &project, "down"],
    )?;
    println!("Stopped.");
    Ok(())
}

/// Destroy container + volumes + local images.
fn flush(name: &str, compose_path: &std::path::Path) -> Result<()> {
    let compose_str = compose_path.to_string_lossy();
    let project = format!("vennon-{name}");
    println!("Flushing vennon-{name} (container + volumes)...");
    exec::run(
        "podman-compose",
        &[
            "-f",
            &compose_str,
            "-p",
            &project,
            "down",
            "-v",
            "--rmi",
            "local",
        ],
    )?;
    println!("Flushed.");
    Ok(())
}

/// Build the container image(s). Always rebuilds base + child.
fn build(name: &str, config: &VennonConfig) -> Result<()> {
    let vennon_dir = config.vennon_path();

    // Always rebuild base (podman layer cache handles skipping unchanged layers)
    println!("Building vennon-leech (base)...");
    let leech_ctx = vennon_dir.join("containers/leech");
    let leech_dockerfile = leech_ctx.join("Dockerfile");
    exec::run(
        "podman",
        &[
            "build",
            "-t",
            "vennon-leech",
            "-f",
            &leech_dockerfile.to_string_lossy(),
            &leech_ctx.to_string_lossy(),
        ],
    )?;

    // Build specific image
    let image_name = format!("vennon-{name}");
    println!("Building {image_name}...");
    let ctx = vennon_dir.join(format!("containers/{name}"));
    let dockerfile = ctx.join("Dockerfile");
    exec::run(
        "podman",
        &[
            "build",
            "-t",
            &image_name,
            "-f",
            &dockerfile.to_string_lossy(),
            &ctx.to_string_lossy(),
        ],
    )?;

    println!("Build complete: {image_name}");
    Ok(())
}

// ── Helpers ─────────────────────────────────────────────────────

fn find_container(name: &str) -> Result<String> {
    let container_name = format!("vennon-{name}");
    let cid = exec::capture(
        "podman",
        &[
            "ps",
            "-q",
            "--filter",
            &format!("name={container_name}"),
        ],
    )?;
    if cid.is_empty() {
        bail!("Container {container_name} not found. Is it running?");
    }
    Ok(cid.lines().next().unwrap_or(&cid).to_string())
}
