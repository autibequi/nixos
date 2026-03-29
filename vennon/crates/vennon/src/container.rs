use anyhow::{bail, Result};
use std::process::{Command, Stdio};

use crate::config::VennonConfig;
use crate::containers;
use crate::exec;

/// Dispatch a container action.
pub fn dispatch(name: &str, action: &str, config: &VennonConfig) -> Result<()> {
    // Set env vars for compose interpolation (${VAR} in docker-compose.yml)
    containers::ide::set_compose_env(config);

    // Use compose from repo — never generated, never overwritten
    let compose_path = config
        .vennon_path()
        .join(format!("containers/{name}/docker-compose.yml"));

    if !compose_path.exists() {
        bail!(
            "compose not found: {}\nExpected at containers/{name}/docker-compose.yml",
            compose_path.display()
        );
    }

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
    Command::new("podman")
        .args(["image", "exists", name])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
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

/// Container/project name for this session: vennon-{name}-{VENNON_INSTANCE}.
/// VENNON_INSTANCE is set by ide::set_compose_env() from the target path slug.
fn instance_name(base: &str) -> String {
    let inst = std::env::var("VENNON_INSTANCE").unwrap_or_default();
    if inst.is_empty() {
        format!("vennon-{base}")
    } else {
        format!("vennon-{base}-{inst}")
    }
}

/// Start container and exec into the IDE.
/// Uses exec_replace into a bash wrapper with an EXIT trap so that compose down
/// runs reliably whether the user types /exit, closes the terminal, or is killed.
fn start(name: &str, compose_path: &std::path::Path, config: &VennonConfig) -> Result<()> {
    ensure_image(name, config)?;

    let compose_str = compose_path.to_string_lossy();
    let project = instance_name(name);
    let cid = ensure_container_running(name, &compose_str, &project)?;

    exec::clear_screen();

    let cmd = containers::start_cmd(name);
    let bash_cmd = build_exec_with_cleanup(&cid, &cmd, &compose_str, &project);
    exec::exec_replace("bash", &["-c", &bash_cmd]);
}

/// Open a bash shell inside the container with the same cleanup semantics.
fn shell(name: &str, compose_path: &std::path::Path, config: &VennonConfig) -> Result<()> {
    ensure_image(name, config)?;

    let compose_str = compose_path.to_string_lossy();
    let project = instance_name(name);
    let cid = ensure_container_running(name, &compose_str, &project)?;

    let cmd = containers::shell_cmd();
    let bash_cmd = build_exec_with_cleanup(&cid, &cmd, &compose_str, &project);
    exec::exec_replace("bash", &["-c", &bash_cmd]);
}

/// Stop the container for the current path instance.
fn stop(name: &str, compose_path: &std::path::Path) -> Result<()> {
    let compose_str = compose_path.to_string_lossy();
    let project = instance_name(name);
    println!("Stopping {project}...");
    exec::run(
        "podman-compose",
        &["-f", &compose_str, "-p", &project, "down"],
    )?;
    println!("Stopped.");
    Ok(())
}

/// Destroy container + volumes + local images for the current path instance.
fn flush(name: &str, compose_path: &std::path::Path) -> Result<()> {
    let compose_str = compose_path.to_string_lossy();
    let project = instance_name(name);
    println!("Flushing {project} (container + volumes)...");
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

    println!("Building vennon-vennon (base)...");
    let vennon_ctx = vennon_dir.join("containers/vennon");
    let vennon_dockerfile = vennon_ctx.join("vennon.container");
    exec::run(
        "podman",
        &[
            "build",
            "-t",
            "vennon-vennon",
            "-f",
            &vennon_dockerfile.to_string_lossy(),
            &vennon_ctx.to_string_lossy(),
        ],
    )?;

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

/// Returns the CID if the instance container is already running; starts it otherwise.
fn ensure_container_running(name: &str, compose_str: &str, project: &str) -> Result<String> {
    if let Some(cid) = running_container(name) {
        return Ok(cid);
    }
    exec::run(
        "podman-compose",
        &["-f", compose_str, "-p", project, "up", "-d", name],
    )?;
    find_container(name)
}

/// Returns the container ID if the instance is already running, None otherwise.
fn running_container(name: &str) -> Option<String> {
    let container_name = instance_name(name);
    exec::capture(
        "podman",
        &["ps", "-q", "--filter", &format!("name=^{container_name}$")],
    )
    .ok()
    .filter(|s| !s.is_empty())
    .map(|s| s.lines().next().map(str::to_string).unwrap_or(s))
}

fn find_container(name: &str) -> Result<String> {
    let container_name = instance_name(name);
    let cid = exec::capture(
        "podman",
        &["ps", "-q", "--filter", &format!("name=^{container_name}$")],
    )?;
    if cid.is_empty() {
        bail!("Container {container_name} not found. Is it running?");
    }
    Ok(cid.lines().next().unwrap_or(&cid).to_string())
}

/// Build a bash one-liner that:
/// 1. Runs `podman exec -it <cid> <cmd>` in the foreground.
/// 2. On EXIT (normal, SIGHUP, SIGTERM), calls compose down — but only if no
///    other exec sessions are still active (i.e. another terminal on same path).
///
/// Using exec_replace into bash gives reliable SIGHUP handling: bash forwards
/// the signal to its child (podman exec → container process dies) and then
/// executes the EXIT trap before it exits.
fn build_exec_with_cleanup(cid: &str, cmd: &str, compose_str: &str, project: &str) -> String {
    let cmd_q = shell_single_quote(cmd);
    let compose_q = shell_single_quote(compose_str);
    let proj_q = shell_single_quote(project);

    // {{len .ExecIDs}} — Go template; in Rust format strings {{ → { and }} → }
    format!(
        "cleanup() {{ \
            ct=$(podman inspect {cid} --format '{{{{len .ExecIDs}}}}' 2>/dev/null || echo 0); \
            [ \"$ct\" = \"0\" ] && podman-compose -f {compose_q} -p {proj_q} down >/dev/null 2>&1; \
        }}; \
        trap cleanup EXIT; \
        podman exec -it {cid} /bin/bash -c {cmd_q}",
        cid = cid,
        compose_q = compose_q,
        proj_q = proj_q,
        cmd_q = cmd_q,
    )
}

/// Wrap a string in single quotes, escaping any embedded single quotes.
fn shell_single_quote(s: &str) -> String {
    format!("'{}'", s.replace('\'', r"'\''"))
}
