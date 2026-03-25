//! Service runner — orchestrates Docker Compose start/stop/logs/shell/install/test/build/flush.

use anyhow::{bail, Result};
use leech_cli::runner as svc;
use std::process::{Command, Stdio};

/// No-op SIGINT handler: parent ignores the signal without propagating SIG_IGN to children.
/// Unlike SIG_IGN, a custom handler is NOT inherited by exec'd child processes (they get SIG_DFL).
#[cfg(unix)]
extern "C" fn noop_sigint(_: libc::c_int) {}

/// Runner options passed from CLI.
pub struct RunnerOpts<'a> {
    pub env: &'a str,
    pub worktree: Option<&'a str>,
    pub vertical: &'a str,
    pub container: &'a str,
    pub cmd: Option<&'a str>,
    pub tail: u32,
    pub debug: bool,
    /// Start container and return immediately without following logs live.
    pub detach: bool,
}

/// Main entry point — resolve service, dispatch action.
pub fn run(raw_svc: &str, action: &str, opts: &RunnerOpts) -> Result<()> {
    let svc_name = svc::resolve_alias(raw_svc);

    // Validate service directory (reverseproxy has no source dir)
    let src_dir = svc::service_src_dir(svc_name);
    if svc_name != "reverseproxy" && !src_dir.is_dir() {
        bail!(
            "Diretorio do projeto nao encontrado: {}\n\
             Configure {}_DIR em ~/.leech ou crie o diretorio.",
            src_dir.display(),
            svc_name.to_uppercase().replace('-', "_")
        );
    }

    let compose = svc::compose_file(svc_name);
    if !compose.exists() {
        bail!("Compose nao encontrado: {}", compose.display());
    }

    // Resolve worktree
    let wt_path = svc::resolve_worktree(svc_name, opts.worktree);
    let effective_src = wt_path.as_deref().unwrap_or(&src_dir);
    let project = svc::project_name(svc_name, opts.worktree);
    let log_dir = svc::log_dir(svc_name, opts.worktree);
    let env_vars = svc::compose_env_vars(svc_name, opts.env, effective_src, opts.vertical);

    std::fs::create_dir_all(&log_dir)?;

    match action {
        "start" | "start-hotreload" => {
            do_start(svc_name, &compose, &project, &log_dir, &env_vars, opts)
        }
        "stop" => do_stop(svc_name, &compose, &project, &log_dir),
        "restart" => {
            do_stop(svc_name, &compose, &project, &log_dir)?;
            do_start(svc_name, &compose, &project, &log_dir, &env_vars, opts)
        }
        "logs" => do_logs(&compose, &project, &log_dir, opts.tail),
        "shell" => do_shell(
            svc_name,
            &project,
            effective_src,
            &log_dir,
            opts.container,
            opts.cmd,
        ),
        "test" => {
            let cmd = opts.cmd.unwrap_or(if svc_name == "monolito" {
                "make test"
            } else {
                "yarn test"
            });
            do_shell(svc_name, &project, effective_src, &log_dir, "app", Some(cmd))
        }
        "install" => do_install(svc_name, effective_src, &log_dir, opts.env),
        "build" => do_build(&compose, &project, &env_vars),
        "flush" => do_flush(&compose, &project, svc_name, &log_dir, &env_vars),
        other => bail!("Acao desconhecida: {other}"),
    }
}

// ── Compose helper ─────────────────────────────────────────────────────────────

fn compose_cmd(
    compose_file: &std::path::Path,
    project: &str,
    env_vars: &[(String, String)],
) -> Command {
    let mut cmd = Command::new("docker");
    cmd.args([
        "compose",
        "-f",
        &compose_file.to_string_lossy(),
        "-p",
        project,
    ]);
    for (k, v) in env_vars {
        cmd.env(k, v);
    }
    cmd
}

// ── Actions ────────────────────────────────────────────────────────────────────

fn do_start(
    svc: &str,
    compose: &std::path::Path,
    project: &str,
    log_dir: &std::path::Path,
    env_vars: &[(String, String)],
    opts: &RunnerOpts,
) -> Result<()> {
    // 1. Stop previous + free ports
    eprintln!("\x1b[2m[1/4] Parando instancia anterior...\x1b[0m");
    let _ = compose_cmd(compose, project, env_vars)
        .args(["down"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
    for &port in svc::service_host_ports(svc) {
        free_port(port);
    }

    // 2. Ensure network + reverse proxy
    eprintln!("\x1b[2m[2/4] Rede + reverse proxy...\x1b[0m");
    ensure_network();
    ensure_reverseproxy();

    // 3. Handle deps
    let deps_compose = svc::deps_compose_file(svc);
    let deps_project = format!("{project}-deps");
    if deps_compose.exists() {
        eprintln!("\x1b[2m[2b/4] Subindo dependencias...\x1b[0m");
        let _ = compose_cmd(&deps_compose, &deps_project, env_vars)
            .args(["up", "-d", "--remove-orphans"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
        wait_postgres();
    }

    // 4. Build
    eprintln!("\x1b[2m[3/4] Building image...\x1b[0m");
    let debug_compose = svc::debug_compose_file(svc);
    let debug_flag    = debug_compose.to_string_lossy().into_owned();
    let use_debug     = opts.debug && debug_compose.exists();
    let startup_log   = log_dir.join("startup.log");
    let log_file = std::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(true)
        .open(&startup_log)?;
    let mut build_cmd = if use_debug {
        let mut c = Command::new("docker");
        c.args([
            "compose",
            "-f", &compose.to_string_lossy(),
            "-f", &debug_flag,
            "-p", project,
        ]);
        for (k, v) in env_vars { c.env(k, v); }
        c
    } else {
        compose_cmd(compose, project, env_vars)
    };
    let status = build_cmd
        .args(["build"])
        .env("DOCKER_BUILDKIT", "1")
        .stdout(log_file.try_clone()?)
        .stderr(log_file)
        .status()?;
    if !status.success() {
        bail!(
            "docker compose build falhou — verifique: {}",
            startup_log.display()
        );
    }

    // 5. Up
    eprintln!("\x1b[2m[4/4] Subindo container...\x1b[0m");
    let log_file = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&startup_log)?;
    let compose_args = vec!["up", "-d", "--force-recreate", "--remove-orphans"];
    let mut up_cmd = if use_debug {
        eprintln!("\x1b[35m[debug] overlay: {}\x1b[0m", debug_compose.display());
        let mut c = Command::new("docker");
        c.args([
            "compose",
            "-f", &compose.to_string_lossy(),
            "-f", &debug_flag,
            "-p", project,
        ]);
        for (k, v) in env_vars { c.env(k, v); }
        c
    } else {
        compose_cmd(compose, project, env_vars)
    };
    let status = up_cmd
        .args(&compose_args)
        .stdout(log_file.try_clone()?)
        .stderr(log_file)
        .status()?;
    if !status.success() {
        bail!(
            "docker compose up falhou — verifique: {}",
            startup_log.display()
        );
    }

    // Start background log follower
    let svc_log = log_dir.join("service.log");
    let pid_file = log_dir.join("logger.pid");
    kill_logger(&pid_file);
    let logger_out = std::fs::File::create(&svc_log)?;
    let child = compose_cmd(compose, project, env_vars)
        .args(["logs", "-f", "--no-log-prefix"])
        .stdout(logger_out)
        .stderr(Stdio::null())
        .spawn()?;
    let _ = std::fs::write(&pid_file, child.id().to_string());

    eprintln!(
        "\x1b[32m✓ {} pronto\x1b[0m  [env={}]{}",
        svc, opts.env, if use_debug { "  \x1b[35m[DEBUG]\x1b[0m" } else { "" }
    );
    if use_debug {
        eprintln!("  \x1b[33m[DEBUG]\x1b[0m Delve aguardando attach em localhost:2345");
        eprintln!("  \x1b[33m[DEBUG]\x1b[0m VS Code: use a config 'Attach to monolito'");
    }
    eprintln!(
        "  \x1b[2mLogs: leech runner {} logs\x1b[0m",
        svc
    );
    eprintln!(
        "  \x1b[2mArquivo: {}/service.log\x1b[0m",
        log_dir.display()
    );

    if opts.detach {
        return Ok(());
    }

    // Follow logs live (Ctrl+C exits but container keeps running)
    eprintln!("\n  \x1b[2m[Ctrl+C para sair — container continua]\x1b[0m\n");

    #[cfg(unix)]
    let _prev = unsafe { libc::signal(libc::SIGINT, noop_sigint as libc::sighandler_t) };

    let _ = compose_cmd(compose, project, env_vars)
        .args(["logs", "-f", "--no-log-prefix", "--tail", "50"])
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status();

    #[cfg(unix)]
    unsafe {
        libc::signal(libc::SIGINT, libc::SIG_DFL);
    }

    Ok(())
}

fn do_stop(
    svc: &str,
    compose: &std::path::Path,
    project: &str,
    log_dir: &std::path::Path,
) -> Result<()> {
    let pid_file = log_dir.join("logger.pid");
    kill_logger(&pid_file);

    eprintln!("  \x1b[2mParando {svc}...\x1b[0m");
    let _ = Command::new("docker")
        .args([
            "compose",
            "-f",
            &compose.to_string_lossy(),
            "-p",
            project,
            "down",
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    // Stop deps if present
    let deps_compose = svc::deps_compose_file(svc);
    if deps_compose.exists() {
        let deps_project = format!("{project}-deps");
        let _ = Command::new("docker")
            .args([
                "compose",
                "-f",
                &deps_compose.to_string_lossy(),
                "-p",
                &deps_project,
                "down",
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }

    eprintln!("  \x1b[32m✓ {svc} parado\x1b[0m");
    Ok(())
}

fn do_logs(
    compose: &std::path::Path,
    project: &str,
    log_dir: &std::path::Path,
    tail: u32,
) -> Result<()> {
    let tail_str = tail.to_string();

    // Check if container is running
    let running = Command::new("docker")
        .args([
            "compose",
            "-f",
            &compose.to_string_lossy(),
            "-p",
            project,
            "ps",
            "--status",
            "running",
            "-q",
        ])
        .output()
        .map(|o| !o.stdout.is_empty())
        .unwrap_or(false);

    if running {
        eprintln!("  \x1b[2m[Ctrl+C para sair — container continua]\x1b[0m\n");

        #[cfg(unix)]
        let _prev = unsafe { libc::signal(libc::SIGINT, noop_sigint as libc::sighandler_t) };

        let _ = Command::new("docker")
            .args([
                "compose",
                "-f",
                &compose.to_string_lossy(),
                "-p",
                project,
                "logs",
                "--no-log-prefix",
                "--tail",
                &tail_str,
                "-f",
            ])
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .status();

        #[cfg(unix)]
        unsafe {
            libc::signal(libc::SIGINT, libc::SIG_DFL);
        }
    } else {
        let svc_log = log_dir.join("service.log");
        let startup_log = log_dir.join("startup.log");

        // Pick the most recently modified log so build failures are visible
        let svc_t = svc_log.metadata().ok().and_then(|m| m.modified().ok());
        let startup_t = startup_log.metadata().ok().and_then(|m| m.modified().ok());
        let log_to_show: Option<(std::path::PathBuf, &str)> = match (svc_t, startup_t) {
            (Some(sv), Some(st)) => {
                if st > sv {
                    Some((startup_log, "startup/build"))
                } else {
                    Some((svc_log, "runtime"))
                }
            }
            (Some(_), None) => Some((svc_log, "runtime")),
            (None, Some(_)) => Some((startup_log, "startup/build")),
            (None, None) => None,
        };

        if let Some((log_path, label)) = log_to_show {
            eprintln!("=== Container parado. Mostrando log gravado [{}] ===", label);

            #[cfg(unix)]
            let _prev = unsafe { libc::signal(libc::SIGINT, noop_sigint as libc::sighandler_t) };

            let _ = Command::new("tail")
                .args(["-f", "-n", &tail_str])
                .arg(&log_path)
                .stdin(Stdio::inherit())
                .stdout(Stdio::inherit())
                .stderr(Stdio::inherit())
                .status();

            #[cfg(unix)]
            unsafe {
                libc::signal(libc::SIGINT, libc::SIG_DFL);
            }
        } else {
            eprintln!("Nenhum container rodando e nenhum log encontrado.");
            eprintln!("Use: leech runner <service> start");
        }
    }
    Ok(())
}

fn do_shell(
    svc: &str,
    project: &str,
    src_dir: &std::path::Path,
    log_dir: &std::path::Path,
    container: &str,
    cmd: Option<&str>,
) -> Result<()> {
    if svc::is_node_service(svc) {
        let container_name = format!("{project}-{container}");
        let status = if let Some(c) = cmd {
            eprintln!("=== [{svc}] exec: {c} ===");
            Command::new("docker")
                .args(["exec", "-it", &container_name, "sh", "-l", "-c", c])
                .stdin(Stdio::inherit())
                .stdout(Stdio::inherit())
                .stderr(Stdio::inherit())
                .status()?
        } else {
            Command::new("docker")
                .args(["exec", "-it", &container_name, "sh", "-l"])
                .stdin(Stdio::inherit())
                .stdout(Stdio::inherit())
                .stderr(Stdio::inherit())
                .status()?
        };
        if !status.success() {
            bail!("docker exec falhou (exit {})", status.code().unwrap_or(-1));
        }
        return Ok(());
    }

    // Monolito: one-off golang:alpine container
    let uid = get_uid();
    let gid = get_gid();
    let src = src_dir.to_string_lossy();

    let mut docker = Command::new("docker");
    docker
        .args(["run", "--init", "--rm"])
        .args(["-v", &format!("{src}:/go/app")])
        .args(["-v", "/var/run/docker.sock:/var/run/docker.sock"])
        .args(["-v", "leech-go-mod-cache:/go/pkg/mod"])
        .args(["-v", "leech-go-build-cache:/root/.cache/go-build"])
        .args(["-e", "GOPATH=/go"])
        .args(["-e", "GOPRIVATE=github.com/estrategiahq"])
        .args(["-e", "TERM=xterm-256color"])
        .args(["-e", "COLORTERM=truecolor"])
        .args([
            "-e",
            "DOCKER_HOST=unix:///var/run/docker.sock",
        ])
        .args([
            "-e",
            "TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock",
        ])
        .args(["-e", &format!("HOST_UID={uid}")])
        .args(["-e", &format!("HOST_GID={gid}")])
        .args(["--network", "host"])
        .args(["-w", "/go/app"]);

    if let Some(c) = cmd {
        let test_log = log_dir.join("test.log");
        eprintln!("=== [{svc}] exec: {c} ===");
        eprintln!("  logs: {}", test_log.display());
        docker
            .args([
                "-v",
                &format!("{}:/workspace/logs", log_dir.to_string_lossy()),
            ])
            .arg("-i")
            .arg("golang:1.24.4-alpine")
            .args([
                "sh",
                "-c",
                &format!(
                    "apk add --no-cache make gcc musl-dev librdkafka-dev \
                     ca-certificates docker-cli > /dev/null 2>&1 && \
                     {c} && chown -R \"{uid}:{gid}\" /go/app 2>/dev/null || true"
                ),
            ])
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit());
    } else {
        docker
            .arg("-it")
            .arg("golang:1.24.4-alpine")
            .args([
                "sh",
                "-c",
                "apk add --no-cache make gcc musl-dev librdkafka-dev \
                 ca-certificates docker-cli bash > /dev/null 2>&1 && exec sh",
            ])
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit());
    }

    docker.status()?;
    Ok(())
}

fn do_install(
    svc: &str,
    src_dir: &std::path::Path,
    log_dir: &std::path::Path,
    _env: &str,
) -> Result<()> {
    let src = src_dir.to_string_lossy();
    let uid = get_uid();
    let gid = get_gid();
    let home = leech_cli::paths::home();

    if svc::is_node_service(svc) {
        let node_ver = detect_node_version(src_dir).unwrap_or(20);
        let image = format!("node:{node_ver}-alpine");
        let ssh_dir = std::env::var("HOST_SSH_DIR")
            .unwrap_or_else(|_| home.join(".ssh").to_string_lossy().into_owned());
        let npmrc = std::env::var("HOST_NPMRC")
            .unwrap_or_else(|_| home.join(".npmrc").to_string_lossy().into_owned());

        eprintln!(
            "\x1b[1m\x1b[35m  docker install  {svc} (Node)\x1b[0m"
        );
        eprintln!(
            "  \x1b[2mimage: {image}  •  logs: {}/install.log\x1b[0m\n",
            log_dir.display()
        );

        let npm_token = std::env::var("NPM_TOKEN").unwrap_or_default();
        let status = Command::new("docker")
            .args(["run", "--init", "--rm", "-it"])
            .args(["-v", &format!("{ssh_dir}:/ssh-host:ro")])
            .args(["-v", &format!("{npmrc}:/npmrc-host:ro")])
            .args(["-v", &format!("{src}:/app")])
            .args(["-e", &format!("NPM_TOKEN={npm_token}")])
            .args(["-e", "TERM=xterm-256color"])
            .args(["-e", "CI=true"])
            .args(["-e", &format!("HOST_UID={uid}")])
            .args(["-e", &format!("HOST_GID={gid}")])
            .args(["-w", "/app"])
            .arg(&image)
            .args(["sh", "-c", "\
                set -e; \
                apk add --no-cache git openssh-client ca-certificates python3 make g++ autoconf automake libtool nasm pkgconfig; \
                mkdir -p /root/.ssh; cp /ssh-host/* /root/.ssh/ 2>/dev/null || true; \
                chmod 700 /root/.ssh; chmod 600 /root/.ssh/* 2>/dev/null || true; \
                ssh-keyscan github.com >> /root/.ssh/known_hosts 2>/dev/null; \
                [ -f /npmrc-host ] && cp /npmrc-host /root/.npmrc || true; \
                echo '@estrategiahq:registry=https://npm.pkg.github.com/estrategiahq' >> /root/.npmrc; \
                echo '[1/2] Instalando dependencias (npm install)...'; \
                npm install --no-progress; \
                chown -R \"$HOST_UID:$HOST_GID\" /app/node_modules 2>/dev/null || true; \
                echo ''; echo 'Dependencias instaladas!'"])
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .status()?;
        if !status.success() {
            bail!("Instalacao falhou. Verifique: {}/install.log", log_dir.display());
        }
    } else {
        // Go install
        let ssh_dir = std::env::var("HOST_SSH_DIR")
            .unwrap_or_else(|_| home.join(".ssh").to_string_lossy().into_owned());

        eprintln!(
            "\x1b[1m\x1b[35m  docker install  {svc} (Go)\x1b[0m"
        );
        eprintln!(
            "  \x1b[2mlogs: {}/install.log\x1b[0m\n",
            log_dir.display()
        );

        let status = Command::new("docker")
            .args(["run", "--init", "--rm", "-it"])
            .args(["-v", &format!("{ssh_dir}:/ssh-host:ro")])
            .args(["-v", &format!("{src}:/go/app")])
            .args(["-v", "leech-go-mod-cache:/go/pkg/mod"])
            .args(["-v", "leech-go-build-cache:/root/.cache/go-build"])
            .args(["-e", "GOPATH=/go"])
            .args(["-e", "GOPRIVATE=github.com/estrategiahq"])
            .args(["-e", "TERM=xterm-256color"])
            .args(["-e", &format!("HOST_UID={uid}")])
            .args(["-e", &format!("HOST_GID={gid}")])
            .args(["-w", "/go/app"])
            .arg("golang:1.24.4-alpine")
            .args(["sh", "-c", "\
                set -e; \
                mkdir -p /root/.ssh; cp /ssh-host/* /root/.ssh/ 2>/dev/null || true; \
                chmod 700 /root/.ssh; chmod 600 /root/.ssh/* 2>/dev/null || true; \
                apk add --no-cache git gcc musl-dev librdkafka-dev ca-certificates openssh-client; \
                git config --global url.'git@github.com:estrategiahq'.insteadOf \
                  'https://github.com/estrategiahq'; \
                ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts 2>/dev/null; \
                echo '[1/3] Download modulos Go...'; go mod download; \
                echo '[2/3] go mod tidy...'; go mod tidy; \
                echo '[3/3] go work vendor...'; go work vendor; \
                chown -R \"$HOST_UID:$HOST_GID\" /go/app/vendor 2>/dev/null || true; \
                echo ''; echo 'Dependencias instaladas!'"])
            .stdin(Stdio::inherit())
            .stdout(Stdio::inherit())
            .stderr(Stdio::inherit())
            .status()?;
        if !status.success() {
            bail!("Instalacao falhou. Verifique: {}/install.log", log_dir.display());
        }
    }

    eprintln!(
        "\n  \x1b[32m\x1b[1mFeito!\x1b[0m  Rode: leech runner {svc} start"
    );
    Ok(())
}

fn do_build(
    compose: &std::path::Path,
    project: &str,
    env_vars: &[(String, String)],
) -> Result<()> {
    let status = compose_cmd(compose, project, env_vars)
        .args(["build"])
        .env("DOCKER_BUILDKIT", "1")
        .stdin(Stdio::inherit())
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .status()?;
    if !status.success() {
        bail!("docker compose build falhou");
    }
    Ok(())
}

fn do_flush(
    compose: &std::path::Path,
    project: &str,
    svc: &str,
    log_dir: &std::path::Path,
    env_vars: &[(String, String)],
) -> Result<()> {
    kill_logger(&log_dir.join("logger.pid"));

    eprintln!("  Parando containers...");
    let _ = compose_cmd(compose, project, env_vars)
        .args(["down", "-v", "--remove-orphans"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    let deps_project = format!("{project}-deps");
    let _ = Command::new("docker")
        .args([
            "compose",
            "-p",
            &deps_project,
            "down",
            "-v",
            "--remove-orphans",
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    eprintln!("  Removendo imagens...");
    let _ = Command::new("sh")
        .args([
            "-c",
            &format!(
                "docker images --filter 'label=com.docker.compose.project={project}' -q \
                 | xargs docker rmi -f 2>/dev/null; \
                 docker rmi -f leech-dk-{svc}-app leech-dk-{svc}-worker 2>/dev/null; true"
            ),
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    eprintln!("  Removendo volumes...");
    let _ = Command::new("sh")
        .args([
            "-c",
            &format!(
                "docker volume ls --filter 'label=com.docker.compose.project={project}' -q \
                 | xargs docker volume rm 2>/dev/null; true"
            ),
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();

    eprintln!("  Limpando logs...");
    let _ = std::fs::remove_dir_all(log_dir);

    eprintln!("\x1b[32m✓ flush completo\x1b[0m");
    eprintln!("  Rode 'leech runner {svc} install' para reinstalar.");
    Ok(())
}

// ── Helpers ────────────────────────────────────────────────────────────────────

fn kill_logger(pid_file: &std::path::Path) {
    if let Ok(pid_str) = std::fs::read_to_string(pid_file) {
        if let Ok(pid) = pid_str.trim().parse::<i32>() {
            #[cfg(unix)]
            unsafe {
                libc::kill(pid, libc::SIGTERM);
            }
        }
        let _ = std::fs::remove_file(pid_file);
    }
}

fn free_port(port: u16) {
    if let Ok(out) = Command::new("docker")
        .args(["ps", "-q", "--filter", &format!("publish={port}")])
        .output()
    {
        for id in String::from_utf8_lossy(&out.stdout).split_whitespace() {
            let _ = Command::new("docker")
                .args(["stop", id])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
        }
    }
}

fn ensure_network() {
    let exists = Command::new("docker")
        .args(["network", "inspect", "nixos_default"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false);
    if !exists {
        let _ = Command::new("docker")
            .args(["network", "create", "nixos_default"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    }
}

fn ensure_reverseproxy() {
    let running = Command::new("docker")
        .args([
            "ps",
            "--format",
            "{{.Names}}",
            "--filter",
            "name=leech-reverseproxy",
        ])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).contains("leech-reverseproxy"))
        .unwrap_or(false);
    if running {
        return;
    }

    let rp_dir = leech_cli::paths::nixos_dir().join("leech/docker/reverseproxy");
    if !rp_dir.exists() {
        return;
    }

    // Generate certs if missing
    let cert = rp_dir.join("certs/fullchain.pem");
    if !cert.exists() {
        let gen = rp_dir.join("gen-cert.sh");
        if gen.exists() {
            let _ = Command::new("bash")
                .arg(&gen)
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
        }
    }

    let _ = Command::new("docker")
        .args([
            "compose",
            "-f",
            &rp_dir.join("docker-compose.yml").to_string_lossy(),
            "-p",
            "leech-dk-reverseproxy",
            "up",
            "-d",
            "--remove-orphans",
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

fn wait_postgres() {
    for _ in 0..30 {
        let ok = Command::new("docker")
            .args([
                "exec",
                "leech-dk-monolito-postgres",
                "pg_isready",
                "-U",
                "estrategia",
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false);
        if ok {
            return;
        }
        std::thread::sleep(std::time::Duration::from_secs(1));
    }
}

fn get_uid() -> u32 {
    #[cfg(unix)]
    unsafe {
        libc::getuid()
    }
    #[cfg(not(unix))]
    0
}

fn get_gid() -> u32 {
    #[cfg(unix)]
    unsafe {
        libc::getgid()
    }
    #[cfg(not(unix))]
    0
}

fn detect_node_version(src_dir: &std::path::Path) -> Option<u32> {
    let pkg = std::fs::read_to_string(src_dir.join("package.json")).ok()?;
    let v: serde_json::Value = serde_json::from_str(&pkg).ok()?;
    let engines = v.get("engines")?.get("node")?.as_str()?;
    // Extract first number from version range like ">=18" or "20.x"
    engines
        .chars()
        .skip_while(|c| !c.is_ascii_digit())
        .take_while(|c| c.is_ascii_digit())
        .collect::<String>()
        .parse()
        .ok()
}
