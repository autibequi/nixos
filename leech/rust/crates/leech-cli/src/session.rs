//! `SessionRunner` builder — constructs and launches docker compose sessions for any engine.

use crate::compose::ComposeCmd;
use crate::config::LeechConfig;
use crate::engine::Engine;
use crate::error::Result;
use crate::model;
use crate::paths;

/// Builder for launching a Leech session (docker compose run with engine).
#[derive(Debug)]
pub struct SessionRunner {
    engine: Engine,
    proj_name: String,
    mount_path: String,
    mount_opts: String,
    model: Option<String>,
    danger: bool,
    resume: Option<String>,
    init_md: Option<String>,
    analysis_mode: bool,
    no_splash: bool,
    instance: Option<String>,
    extra_volumes: Vec<String>,
    /// host mode: monta ~/nixos em /workspace/host:rw, injeta HOST_ATTACHED=1
    host: bool,
    /// ghost mode: sessão isolada em obsidian/ghost, injeta GHOST_IN_THE_SHELL=ON
    ghost: bool,
}

impl SessionRunner {
    pub fn new(engine: Engine) -> Self {
        Self {
            engine,
            proj_name: String::new(),
            mount_path: String::new(),
            mount_opts: "rw".to_string(),
            model: None,
            danger: false,
            resume: None,
            init_md: None,
            analysis_mode: false,
            no_splash: false,
            instance: None,
            extra_volumes: Vec::new(),
            host: false,
            ghost: false,
        }
    }

    #[must_use]
    pub fn mount_path(mut self, path: &str) -> Self {
        self.mount_path = path.to_string();
        self
    }

    #[must_use]
    pub fn mount_opts(mut self, opts: &str) -> Self {
        self.mount_opts = opts.to_string();
        self
    }

    #[must_use]
    pub fn proj_name(mut self, name: &str) -> Self {
        self.proj_name = name.to_string();
        self
    }

    #[must_use]
    pub fn model(mut self, model: Option<String>) -> Self {
        self.model = model;
        self
    }

    #[must_use]
    pub fn danger(mut self, d: bool) -> Self {
        self.danger = d;
        self
    }

    #[must_use]
    pub fn resume(mut self, session_id: Option<String>) -> Self {
        self.resume = session_id;
        self
    }

    #[must_use]
    pub fn init_md(mut self, file: Option<String>) -> Self {
        self.init_md = file;
        self
    }

    #[must_use]
    pub fn analysis_mode(mut self, enabled: bool) -> Self {
        self.analysis_mode = enabled;
        self
    }

    #[must_use]
    pub fn no_splash(mut self, enabled: bool) -> Self {
        self.no_splash = enabled;
        self
    }

    #[must_use]
    pub fn instance(mut self, id: Option<String>) -> Self {
        self.instance = id;
        self
    }

    #[must_use]
    pub fn extra_volumes(mut self, vols: Vec<String>) -> Self {
        self.extra_volumes = vols;
        self
    }

    #[must_use]
    pub fn host(mut self, enabled: bool) -> Self {
        self.host = enabled;
        self
    }

    #[must_use]
    pub fn ghost(mut self, enabled: bool) -> Self {
        self.ghost = enabled;
        self
    }

    /// Resolve all parameters from config + CLI overrides and launch the session.
    pub fn run(self, config: &LeechConfig) -> Result<()> {
        if self.ghost {
            return self.run_ghost(config);
        }
        let model_id = model::resolve_model(self.model.as_deref(), self.engine, config);
        let danger = self.danger || config.danger;

        match self.engine {
            Engine::Claude => self.run_claude(model_id, danger, config),
            Engine::Cursor => self.run_cursor(model_id, danger, config),
            Engine::OpenCode => self.run_opencode(model_id, danger, config),
        }
    }

    /// Ghost mode: `docker run` direto com volumes mínimos — só /workspace/ghost visível.
    fn run_ghost(&self, config: &LeechConfig) -> Result<()> {
        let model_id = model::resolve_model(self.model.as_deref(), self.engine, config);
        let ghost_path = &self.mount_path;
        let leech_root = paths::leech_root().to_string_lossy().into_owned();
        let home = paths::home().to_string_lossy().into_owned();

        let mut claude_args: Vec<String> = Vec::new();
        if let Some(ref id) = model_id {
            claude_args.push("--model".to_string());
            claude_args.push(id.clone());
        }
        claude_args.push("--name".to_string());
        claude_args.push("ghost".to_string());
        let claude_args_str = claude_args.join(" ");

        let bash_cmd = format!(
            "cd /workspace/ghost && exec /home/claude/.nix-profile/bin/claude {claude_args_str}"
        );

        let mut args: Vec<String> = vec![
            "run".into(), "--rm".into(), "-it".into(),
            "--network".into(), "host".into(),
            "--workdir".into(), "/workspace/ghost".into(),
            "--entrypoint".into(), "/entrypoint.sh".into(),
            // Volumes mínimos — só o necessário para Claude Code funcionar
            // /workspace/self NÃO é montado — ghost não tem acesso ao source do Leech
            "-v".into(), format!("{ghost_path}:/workspace/ghost:rw"),
            "-v".into(), format!("{home}/.claude:/home/claude/.claude"),
            "-v".into(), format!("{leech_root}/claude.bypass.json:/home/claude/.claude/settings.json:ro"),
            "-v".into(), format!("{leech_root}/skills:/home/claude/.claude/skills"),
            "-v".into(), format!("{leech_root}/commands:/home/claude/.claude/commands"),
            "-v".into(), format!("{leech_root}/agents:/home/claude/.claude/agents"),
            "-v".into(), format!("{leech_root}/hooks/claude-code:/home/claude/.claude/hooks:ro"),
            "-v".into(), format!("{leech_root}/scripts:/home/claude/.claude/scripts"),
            "-v".into(), format!("{home}/.claude.json:/home/claude/.claude.json"),
            "-v".into(), format!("{home}/.leech:/home/claude/.leech:rw"),
            // Env vars essenciais
            "-e".into(), "CLAUDE_ENV=container".into(),
            "-e".into(), "GHOST_IN_THE_SHELL=ON".into(),
            "-e".into(), format!("CLAUDIO_MOUNT={ghost_path}"),
            "-e".into(), "BOOTSTRAP_SKIP_CLEAR=1".into(),
            "-e".into(), "XDG_CACHE_HOME=/workspace/.ephemeral/cache".into(),
            "-e".into(), "DOCKER_HOST=tcp://localhost:2375".into(),
        ];

        // Tokens opcionais
        if let Some(ref t) = config.anthropic_api_key {
            args.extend(["-e".into(), format!("ANTHROPIC_API_KEY={t}")]);
        }
        if let Some(ref t) = config.gh_token {
            args.extend(["-e".into(), format!("GH_TOKEN={t}")]);
        }

        args.extend(["leech".into(), "/bin/bash".into(), "-c".into(), bash_cmd]);

        let args_ref: Vec<&str> = args.iter().map(String::as_str).collect();
        crate::docker::exec_replace_docker(&args_ref)
    }

    /// Convenience: resolve dir/slug/proj_name from a directory path.
    pub fn from_dir(engine: Engine, dir: Option<&str>, instance: Option<&str>) -> Result<Self> {
        let mount_path = paths::resolve_dir(dir)?;
        let slug = paths::proj_slug(&mount_path);
        let proj_name = paths::proj_name(&slug, instance);

        Ok(Self::new(engine)
            .mount_path(&mount_path.to_string_lossy())
            .proj_name(&proj_name)
            .instance(instance.map(|s| s.to_string())))
    }

    /// Build `-v vol` pairs from extra_volumes for compose run args.
    fn volume_args(&self) -> Vec<String> {
        self.extra_volumes
            .iter()
            .flat_map(|v| vec!["-v".to_string(), v.clone()])
            .collect()
    }

    fn compose(&self, config: &LeechConfig) -> ComposeCmd {
        let base = if self.ghost {
            ComposeCmd::new().file(&paths::ghost_compose_file())
        } else {
            ComposeCmd::new()
        };
        let mut cmd = base.project(&self.proj_name)
            .env("CLAUDIO_MOUNT", &self.mount_path)
            .env("CLAUDIO_MOUNT_OPTS", &self.mount_opts)
            .env("OBSIDIAN_PATH", &paths::obsidian_ensured())
            .env("HOME", &paths::home().to_string_lossy())
            .env("DOCKER_GID", &config.docker_gid.to_string())
            .env("JOURNAL_GID", &config.journal_gid.to_string())
            .env("LEECH_ROOT", &paths::leech_root().to_string_lossy())
            .env("LEECH_NIXOS_DIR", &paths::nixos_dir().to_string_lossy())
            .env("XDG_DATA_HOME", &paths::xdg_data_home())
            .env("XDG_RUNTIME_DIR", &paths::xdg_runtime_dir());

        // Host mode: monta ~/nixos em /workspace/host:rw
        if self.host {
            cmd = cmd.env("CLAUDIO_HOST_OPTS", "rw");
        }

        // Forward tokens from config
        let tokens = [
            ("GH_TOKEN", &config.gh_token),
            ("ANTHROPIC_API_KEY", &config.anthropic_api_key),
            ("CURSOR_API_KEY", &config.cursor_api_key),
            ("GRAFANA_URL", &config.grafana_url),
            ("GRAFANA_TOKEN", &config.grafana_token),
        ];
        for (key, val) in tokens {
            if let Some(v) = val {
                cmd = cmd.env(key, v);
            }
        }

        cmd
    }

    fn run_claude(
        &self,
        model_id: Option<String>,
        danger: bool,
        config: &LeechConfig,
    ) -> Result<()> {
        let mut claude_args = Vec::new();

        if let Some(ref id) = model_id {
            claude_args.push("--model".to_string());
            claude_args.push(id.clone());
        }

        if danger {
            claude_args.push("--permission-mode".to_string());
            claude_args.push("bypassPermissions".to_string());
        }

        if let Some(ref resume) = self.resume {
            if resume == "1" || resume.is_empty() {
                claude_args.push("--resume".to_string());
            } else if resume.contains(' ') {
                // Single-quote para preservar espaços ao expandir em bash -c
                let escaped = resume.replace('\'', r"'\''");
                claude_args.push(format!("'--resume={escaped}'"));
            } else {
                claude_args.push(format!("--resume={resume}"));
            }
        }

        if let Some(ref init_file) = self.init_md {
            claude_args.push("--append-system-prompt-file".to_string());
            claude_args.push(init_file.clone());
        }

        // Session name from mount dir basename
        if !self.mount_path.is_empty() {
            if let Some(name) = std::path::Path::new(&self.mount_path).file_name() {
                claude_args.push("--name".to_string());
                claude_args.push(name.to_string_lossy().to_string());
            }
        }

        let claude_args_str = claude_args.join(" ");
        // --ghost: sessão isolada em /workspace/ghost — sem bootstrap (self não montado)
        // --no-splash: pula o script de loading, faz bootstrap inline e abre claude direto
        let bash_cmd = if self.ghost {
            format!("cd /workspace/ghost && exec /home/claude/.nix-profile/bin/claude {claude_args_str}")
        } else if self.no_splash {
            format!(". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude {claude_args_str}")
        } else {
            format!("bash /workspace/self/scripts/leech-agent-launch.sh {claude_args_str}")
        };

        let vol_args = self.volume_args();

        // Shared container reuse: only when no extra volumes (those need isolated containers).
        if vol_args.is_empty() && !self.analysis_mode {
            let leech_name = format!(
                "leech-{}",
                self.proj_name.strip_prefix("leech-").unwrap_or(&self.proj_name)
            );

            // Find or create the persistent shared container.
            let cid = match crate::docker::find_running_container(&leech_name) {
                Some(cid) => cid,
                None => {
                    self.compose(config).execute(&["up", "-d", "leech"])?;
                    if let Some(auto_name) =
                        crate::docker::find_compose_container(&self.proj_name, "leech")
                    {
                        crate::docker::rename_container(&auto_name, &leech_name);
                    }
                    match crate::docker::find_running_container(&leech_name) {
                        Some(cid) => cid,
                        None => {
                            // Persistent approach failed — fall back to ephemeral run.
                            let mut args: Vec<&str> =
                                vec!["run", "--rm", "-it", "--entrypoint", "/entrypoint.sh"];
                            let mount_env = format!("CLAUDIO_MOUNT={}", self.mount_path);
                            args.extend(["-e", &mount_env, "-e", "BOOTSTRAP_SKIP_CLEAR=1"]);
                            args.extend(["leech", "/bin/bash", "-c", &bash_cmd]);
                            return self.compose(config).execute(&args);
                        }
                    }
                }
            };

            // Exec into the shared container (replaces current process — preserves TTY).
            let mut env_pairs: Vec<(&str, &str)> = vec![("CLAUDIO_MOUNT", &self.mount_path)];
            if self.resume.is_none() {
                env_pairs.push(("BOOTSTRAP_SKIP_CLEAR", "1"));
            }
            if self.host {
                env_pairs.push(("HOST_ATTACHED", "1"));
            }
            let exec_cmd = if self.no_splash || self.resume.is_some() {
                format!(
                    "cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude {claude_args_str}"
                )
            } else {
                bash_cmd
            };
            return crate::docker::exec_replace(&cid, &env_pairs, &exec_cmd);
        }

        // Fallback: ephemeral run (extra volumes or analysis mode require isolated container).
        let mut args: Vec<&str> = vec!["run", "--rm", "-it"];
        for a in &vol_args {
            args.push(a);
        }
        if self.analysis_mode {
            args.extend(["-e", "LEECH_ANALYSIS_MODE=1"]);
        }
        if self.host {
            args.extend(["-e", "HOST_ATTACHED=1"]);
        }
        if self.ghost {
            args.extend(["-e", "GHOST_IN_THE_SHELL=ON"]);
        }
        args.extend(["--entrypoint", "/entrypoint.sh"]);
        let mount_env = format!("CLAUDIO_MOUNT={}", self.mount_path);
        args.extend(["-e", &mount_env, "-e", "BOOTSTRAP_SKIP_CLEAR=1"]);
        args.extend(["leech", "/bin/bash", "-c", &bash_cmd]);

        self.compose(config).execute(&args)
    }

    fn run_cursor(
        &self,
        model_id: Option<String>,
        danger: bool,
        config: &LeechConfig,
    ) -> Result<()> {
        let mut agent_flags = Vec::new();

        if danger {
            agent_flags.push("--force".to_string());
        }
        if let Some(ref id) = model_id {
            agent_flags.push("--model".to_string());
            agent_flags.push(id.clone());
        }
        if !self.mount_path.is_empty() {
            if let Some(name) = std::path::Path::new(&self.mount_path).file_name() {
                agent_flags.push("--name".to_string());
                agent_flags.push(name.to_string_lossy().to_string());
            }
        }

        let agent_flags_str = agent_flags.join(" ");
        let agent_check = r#"agent --version >/dev/null 2>&1 || { echo "leech: cursor-agent nao funciona (versao expirada ou imagem desatualizada). Rode: leech build" >&2; exit 1; }; "#;

        let cursor_cmd = if let Some(ref resume) = self.resume {
            format!(
                ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt; {agent_check}exec agent {agent_flags_str} --resume={resume}"
            )
        } else if let Some(ref init_file) = self.init_md {
            format!(
                ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt; {agent_check}\
                if [ -f \"/workspace/mnt/{init_file}\" ]; then \
                p=$(sed -e 's/\\\\\\\\/\\\\\\\\\\\\\\\\/g' -e 's/\"/\\\\\"/g' \"/workspace/mnt/{init_file}\"); \
                exec agent {agent_flags_str} \"$p\"; \
                else exec agent {agent_flags_str}; fi"
            )
        } else {
            format!(
                ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt; {agent_check}exec agent {agent_flags_str}"
            )
        };

        let vol_args = self.volume_args();

        // Shared container reuse: same pattern as run_claude.
        if vol_args.is_empty() && !self.analysis_mode {
            let leech_name = format!(
                "leech-{}",
                self.proj_name.strip_prefix("leech-").unwrap_or(&self.proj_name)
            );

            let cid = match crate::docker::find_running_container(&leech_name) {
                Some(cid) => cid,
                None => {
                    self.compose(config).execute(&["up", "-d", "leech"])?;
                    if let Some(auto_name) =
                        crate::docker::find_compose_container(&self.proj_name, "leech")
                    {
                        crate::docker::rename_container(&auto_name, &leech_name);
                    }
                    match crate::docker::find_running_container(&leech_name) {
                        Some(cid) => cid,
                        None => {
                            let mut args: Vec<&str> =
                                vec!["run", "--rm", "-it", "--entrypoint", "/entrypoint.sh"];
                            let mount_env = format!("CLAUDIO_MOUNT={}", self.mount_path);
                            args.extend(["-e", &mount_env, "-e", "BOOTSTRAP_SKIP_CLEAR=1"]);
                            args.extend(["leech", "/bin/bash", "-c", &cursor_cmd]);
                            return self.compose(config).execute(&args);
                        }
                    }
                }
            };

            let mut env_pairs: Vec<(&str, &str)> = vec![("CLAUDIO_MOUNT", &self.mount_path)];
            if self.resume.is_none() {
                env_pairs.push(("BOOTSTRAP_SKIP_CLEAR", "1"));
            }
            if self.host {
                env_pairs.push(("HOST_ATTACHED", "1"));
            }
            let exec_cmd = cursor_cmd.clone();
            return crate::docker::exec_replace(&cid, &env_pairs, &exec_cmd);
        }

        // Fallback: ephemeral run (extra volumes or analysis mode require isolated container).
        let mut args: Vec<&str> = vec!["run", "--rm", "-it"];
        for a in &vol_args {
            args.push(a);
        }
        if self.analysis_mode {
            args.extend(["-e", "LEECH_ANALYSIS_MODE=1"]);
        }
        if self.host {
            args.extend(["-e", "HOST_ATTACHED=1"]);
        }
        if self.ghost {
            args.extend(["-e", "GHOST_IN_THE_SHELL=ON"]);
        }
        args.extend(["--entrypoint", "/entrypoint.sh"]);
        let mount_env = format!("CLAUDIO_MOUNT={}", self.mount_path);
        args.extend(["-e", &mount_env, "-e", "BOOTSTRAP_SKIP_CLEAR=1"]);
        args.extend(["leech", "/bin/bash", "-c", &cursor_cmd]);

        self.compose(config).execute(&args)
    }

    fn run_opencode(
        &self,
        model_id: Option<String>,
        danger: bool,
        config: &LeechConfig,
    ) -> Result<()> {
        let mut oc_envs: Vec<String> = vec![
            format!("CLAUDIO_MOUNT={}", self.mount_path),
            "BOOTSTRAP_SKIP_CLEAR=1".to_string(),
        ];

        if let Some(ref id) = model_id {
            oc_envs.push(format!("OPENCODE_MODEL={id}"));
        }
        if danger {
            oc_envs.push("OPENCODE_PERMISSION_BYPASS=1".to_string());
        }
        if let Some(ref init_file) = self.init_md {
            oc_envs.push(format!("CLAUDE_INITIAL_MD=/workspace/mnt/{init_file}"));
        }
        if let Some(ref resume) = self.resume {
            oc_envs.push(format!("CLAUDIO_RESUME_SESSION={resume}"));
        }

        let is_resume = self.resume.is_some();
        let vol_args = self.volume_args();

        if is_resume {
            // Ephemeral for resume
            let mut args: Vec<String> = vec!["run".into(), "--rm".into(), "-it".into()];
            for a in &vol_args {
                args.push(a.clone());
            }
            if self.analysis_mode {
                args.extend(["-e".into(), "LEECH_ANALYSIS_MODE=1".into()]);
            }
            args.extend(["--entrypoint".into(), "/entrypoint.sh".into()]);
            for env in &oc_envs {
                args.push("-e".into());
                args.push(env.clone());
            }
            args.extend([
                "leech".into(),
                "/bin/bash".into(),
                "-c".into(),
                "cd /workspace/mnt && opencode".into(),
            ]);
            let args_ref: Vec<&str> = args.iter().map(String::as_str).collect();
            self.compose(config).execute(&args_ref)
        } else {
            // Persistent: up -d + exec
            self.compose(config).execute(&["up", "-d", "leech"])?;

            let mut args: Vec<String> =
                vec!["exec".into(), "-it".into(), "-u".into(), "claude".into()];
            if self.analysis_mode {
                args.extend(["-e".into(), "LEECH_ANALYSIS_MODE=1".into()]);
            }
            for env in &oc_envs {
                args.push("-e".into());
                args.push(env.clone());
            }
            args.extend([
                "leech".into(),
                "bash".into(),
                "-c".into(),
                "cd /workspace/mnt && exec opencode".into(),
            ]);
            let args_ref: Vec<&str> = args.iter().map(String::as_str).collect();
            self.compose(config).execute(&args_ref)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::Engine;

    #[test]
    fn volume_args_empty() {
        let runner = SessionRunner::new(Engine::Claude);
        assert!(runner.volume_args().is_empty());
    }

    #[test]
    fn volume_args_generates_pairs() {
        let runner = SessionRunner::new(Engine::Claude).extra_volumes(vec![
            "/var/log/journal:/workspace/logs/host/journal:ro".into(),
        ]);
        let args = runner.volume_args();
        assert_eq!(args, vec!["-v", "/var/log/journal:/workspace/logs/host/journal:ro"]);
    }

    #[test]
    fn volume_args_multiple() {
        let runner = SessionRunner::new(Engine::Claude).extra_volumes(vec![
            "/a:/b:ro".into(),
            "/c:/d:rw".into(),
        ]);
        let args = runner.volume_args();
        assert_eq!(args, vec!["-v", "/a:/b:ro", "-v", "/c:/d:rw"]);
    }
}
