use std::collections::BTreeMap;

use crate::compose::{ComposeFile, Network, Service};
use crate::config::{self, VennonConfig};

/// Build the docker-compose structure for an IDE container (claude/opencode/cursor).
/// Reads YAA_* env vars set by yaa for target dir, host mount, model, etc.
pub fn compose(engine: &str, config: &VennonConfig) -> ComposeFile {
    let home = config::home().to_string_lossy().to_string();
    let (uid, gid) = config::user_ids();
    let git = config::git_env();

    // Stable paths — these NEVER change between sessions (compose stays stable)
    let self_path = config.self_path().to_string_lossy().to_string();
    let obsidian = config.obsidian_path().to_string_lossy().to_string();
    let host_dir = config.host_path().to_string_lossy().to_string();
    let projects = config.projects_path().to_string_lossy().to_string();

    let vennon_path = config.vennon_path().to_string_lossy().to_string();
    let container_hooks = format!("{vennon_path}/containers/{engine}/hooks");
    let image = format!("vennon-{engine}:latest");
    let container_name = format!("vennon-{engine}");

    // ── Environment ─────────────────────────────────────────
    let mut env = BTreeMap::new();
    env.insert(
        "PATH".into(),
        "/home/claude/.local/bin:/home/claude/.nix-profile/bin:/root/.nix-profile/bin:/usr/bin:/bin".into(),
    );
    env.insert("CLAUDE_ENV".into(), "container".into());
    env.insert("XDG_CACHE_HOME".into(), "/workspace/.ephemeral/cache".into());
    env.insert("DOCKER_HOST".into(), "tcp://localhost:2375".into());
    env.insert("VENNON_UID".into(), uid.to_string());
    env.insert("VENNON_GID".into(), gid.to_string());

    for (k, v) in &git {
        env.insert(k.clone(), v.clone());
    }

    // Pass target dir so entrypoint can create /workspace/target symlink
    if let Ok(target) = std::env::var("YAA_TARGET_DIR") {
        env.insert("YAA_TARGET_DIR".into(), target);
    }

    // ENGINE var for hooks (pre-tool-use.sh uses it to decide response format)
    env.insert("ENGINE".into(), engine.to_uppercase());

    // ── Volumes ─────────────────────────────────────────────
    // NOTE: target dir is NOT mounted here — it's handled at exec time via `cd`.
    // This keeps the compose stable so multiple sessions can share one container.
    let mut volumes = vec![
        // Core workspace — always mounted
        format!("{self_path}:/workspace/self"),
        format!("{obsidian}:/workspace/obsidian"),
        // Mount projects + home for access to any target dir
        format!("{projects}:/workspace/projects:rw"),
        format!("{home}:/workspace/home:rw"),
        // Claude Code config
        format!("{self_path}/claude.bypass.json:/home/claude/.claude/settings.json:rw"),
        format!("{self_path}/skills:/home/claude/.claude/skills"),
        format!("{self_path}/commands:/home/claude/.claude/commands"),
        format!("{self_path}/ego:/home/claude/.claude/agents"),
        format!("{container_hooks}:/home/claude/.claude/hooks:ro"),
        format!("{self_path}/scripts:/home/claude/.claude/scripts"),
        format!("{home}/.claude.json:/home/claude/.claude.json"),
        format!("{home}/.claude/projects:/home/claude/.claude/projects"),
        // Universal agent standard — works for Cursor, OpenCode, Codex, etc.
        format!("{self_path}/skills:/home/claude/.agents/skills"),
        format!("{self_path}/commands:/home/claude/.agents/commands"),
        format!("{self_path}/ego:/home/claude/.agents/agents"),
        // Communication channel
        format!("{home}/.leech:/home/claude/.leech:rw"),
        // Host observability (ro)
        "/proc/meminfo:/host/proc/meminfo:ro".into(),
        "/proc/loadavg:/host/proc/loadavg:ro".into(),
        "/proc/uptime:/host/proc/uptime:ro".into(),
        "/proc/cpuinfo:/host/proc/cpuinfo:ro".into(),
        "/proc/version:/host/proc/version:ro".into(),
        // Logs (ro)
        "/var/log/journal:/workspace/logs/host/journal:ro".into(),
        "/var/log:/workspace/logs/host/var-log:ro".into(),
    ];

    // Host dir always mounted (stable compose — no recreation between sessions)
    volumes.push(format!("{host_dir}:/workspace/host:rw"));

    // Engine-specific mounts
    match engine {
        "cursor" => {
            // Cursor auth
            volumes.push(format!("{home}/.config/cursor:/home/claude/.config/cursor"));
            volumes.push(format!("{home}/.cursor/cli-config.json:/home/claude/.cursor/cli-config.json"));
            volumes.push(format!("{home}/.cursor/managed:/home/claude/.cursor/managed:ro"));
            // Cursor skills/rules/agents
            volumes.push(format!("{self_path}/skills:/home/claude/.cursor/skills"));
            volumes.push(format!("{self_path}/commands:/home/claude/.cursor/rules"));
            volumes.push(format!("{self_path}/ego:/home/claude/.cursor/agents"));
        }
        "opencode" => {
            // OpenCode config (stow symlinks resolve via entrypoint compat links)
            volumes.push(format!("{home}/.config/opencode:/home/claude/.config/opencode"));
        }
        _ => {} // claude — no extra mounts needed
    }

    // ── Services ────────────────────────────────────────────
    let mut services = BTreeMap::new();

    // Docker socket proxy
    let filter_path = config
        .vennon_path()
        .join("containers/leech/docker-socket-filter.conf")
        .to_string_lossy()
        .to_string();

    services.insert(
        "docker-proxy".into(),
        Service {
            image: Some("docker.io/library/nginx:alpine".into()),
            container_name: Some("vennon-docker-proxy".into()),
            restart: Some("unless-stopped".into()),
            ports: Some(vec!["127.0.0.1:2375:2375".into()]),
            volumes: vec![
                "/var/run/docker.sock:/var/run/docker.sock".into(),
                format!("{filter_path}:/etc/nginx/conf.d/default.conf:ro"),
            ],
            ..default_service()
        },
    );

    // IDE container
    services.insert(
        engine.into(),
        Service {
            image: Some(image),
            container_name: Some(container_name),
            mem_limit: Some(config.settings.memory_limit.clone()),
            memswap_limit: Some(config.settings.memory_limit.clone()),
            network_mode: Some("host".into()),
            stdin_open: Some(true),
            tty: Some(true),
            working_dir: Some("/workspace/home".into()),
            entrypoint: Some(vec!["/entrypoint.sh".into()]),
            command: Some(vec![
                "/bin/bash".into(),
                "-c".into(),
                "sleep infinity".into(),
            ]),
            environment: Some(env),
            volumes,
            tmpfs: Some(vec!["/tmp:size=512m,mode=1777".into()]),
            cap_drop: Some(vec![
                "NET_RAW".into(),
                "SYS_PTRACE".into(),
                "SYS_RAWIO".into(),
                "MKNOD".into(),
                "AUDIT_WRITE".into(),
                "NET_BIND_SERVICE".into(),
            ]),
            extra_hosts: Some(vec!["host.docker.internal:host-gateway".into()]),
            ..default_service()
        },
    );

    // ── Networks ────────────────────────────────────────────
    let mut networks = BTreeMap::new();
    networks.insert(
        "default".into(),
        Network {
            external: Some(true),
            name: Some("nixos_default".into()),
        },
    );

    ComposeFile {
        services,
        volumes: None,
        networks: Some(networks),
    }
}

fn default_service() -> Service {
    Service {
        image: None,
        container_name: None,
        build: None,
        mem_limit: None,
        memswap_limit: None,
        network_mode: None,
        stdin_open: None,
        tty: None,
        working_dir: None,
        entrypoint: None,
        command: None,
        restart: None,
        ports: None,
        volumes: vec![],
        environment: None,
        tmpfs: None,
        cap_drop: None,
        extra_hosts: None,
    }
}
