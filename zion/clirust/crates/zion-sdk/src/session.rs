use crate::compose::ComposeCmd;
use crate::config::ZionConfig;
use crate::engine::Engine;
use crate::error::Result;
use crate::model;
use crate::paths;

/// Builder for launching a Zion session (docker compose run with engine).
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
    instance: Option<String>,
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
            instance: None,
        }
    }

    pub fn mount_path(mut self, path: &str) -> Self {
        self.mount_path = path.to_string();
        self
    }

    pub fn mount_opts(mut self, opts: &str) -> Self {
        self.mount_opts = opts.to_string();
        self
    }

    pub fn proj_name(mut self, name: &str) -> Self {
        self.proj_name = name.to_string();
        self
    }

    pub fn model(mut self, model: Option<String>) -> Self {
        self.model = model;
        self
    }

    pub fn danger(mut self, d: bool) -> Self {
        self.danger = d;
        self
    }

    pub fn resume(mut self, session_id: Option<String>) -> Self {
        self.resume = session_id;
        self
    }

    pub fn init_md(mut self, file: Option<String>) -> Self {
        self.init_md = file;
        self
    }

    pub fn analysis_mode(mut self, enabled: bool) -> Self {
        self.analysis_mode = enabled;
        self
    }

    pub fn instance(mut self, id: Option<String>) -> Self {
        self.instance = id;
        self
    }

    /// Resolve all parameters from config + CLI overrides and launch the session.
    pub fn run(self, config: &ZionConfig) -> Result<()> {
        let model_id = model::resolve_model(self.model.as_deref(), self.engine, config);
        let danger = self.danger || config.danger;

        match self.engine {
            Engine::Claude => self.run_claude(model_id, danger, config),
            Engine::Cursor => self.run_cursor(model_id, danger, config),
            Engine::OpenCode => self.run_opencode(model_id, danger, config),
        }
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

    fn compose(&self, config: &ZionConfig) -> ComposeCmd {
        let mut cmd = ComposeCmd::new()
            .project(&self.proj_name)
            .env("CLAUDIO_MOUNT", &self.mount_path)
            .env("CLAUDIO_MOUNT_OPTS", &self.mount_opts)
            .env("OBSIDIAN_PATH", &paths::obsidian_ensured())
            .env("HOME", &paths::home().to_string_lossy())
            .env("DOCKER_GID", &config.docker_gid.to_string())
            .env("JOURNAL_GID", &config.journal_gid.to_string())
            .env("ZION_ROOT", &paths::zion_root().to_string_lossy())
            .env("ZION_NIXOS_DIR", &paths::nixos_dir().to_string_lossy())
            .env("XDG_DATA_HOME", &paths::xdg_data_home())
            .env("XDG_RUNTIME_DIR", &paths::xdg_runtime_dir());

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
        config: &ZionConfig,
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
        let bash_cmd = format!(
            ". /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude {claude_args_str}"
        );

        let mut args: Vec<&str> = vec!["run", "--rm", "-it"];

        // Analysis mode env
        if self.analysis_mode {
            args.extend(["-e", "ZION_ANALYSIS_MODE=1"]);
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
        config: &ZionConfig,
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
        let agent_check = r#"agent --version >/dev/null 2>&1 || { echo "zion: cursor-agent nao funciona (versao expirada ou imagem desatualizada). Rode: zion build" >&2; exit 1; }; "#;

        let cursor_cmd = if let Some(ref resume) = self.resume {
            format!(
                ". /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt; {agent_check}exec agent {agent_flags_str} --resume={resume}"
            )
        } else if let Some(ref init_file) = self.init_md {
            format!(
                ". /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt; {agent_check}\
                if [ -f \"/workspace/mnt/{init_file}\" ]; then \
                p=$(sed -e 's/\\\\\\\\/\\\\\\\\\\\\\\\\/g' -e 's/\"/\\\\\"/g' \"/workspace/mnt/{init_file}\"); \
                exec agent {agent_flags_str} \"$p\"; \
                else exec agent {agent_flags_str}; fi"
            )
        } else {
            format!(
                ". /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt; {agent_check}exec agent {agent_flags_str}"
            )
        };

        let mut args: Vec<&str> = vec!["run", "--rm", "-it"];

        if self.analysis_mode {
            args.extend(["-e", "ZION_ANALYSIS_MODE=1"]);
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
        config: &ZionConfig,
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

        if is_resume {
            // Ephemeral for resume
            let mut args: Vec<String> = vec!["run".into(), "--rm".into(), "-it".into()];
            if self.analysis_mode {
                args.extend(["-e".into(), "ZION_ANALYSIS_MODE=1".into()]);
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
            let args_ref: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
            self.compose(config).execute(&args_ref)
        } else {
            // Persistent: up -d + exec
            self.compose(config).execute(&["up", "-d", "leech"])?;

            let mut args: Vec<String> =
                vec!["exec".into(), "-it".into(), "-u".into(), "claude".into()];
            if self.analysis_mode {
                args.extend(["-e".into(), "ZION_ANALYSIS_MODE=1".into()]);
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
            let args_ref: Vec<&str> = args.iter().map(|s| s.as_str()).collect();
            self.compose(config).execute(&args_ref)
        }
    }
}
