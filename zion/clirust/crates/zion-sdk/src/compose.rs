use std::process::Command;

use crate::error::{Result, ZionError};
use crate::paths;

/// Builder for `docker compose` commands.
#[derive(Debug)]
pub struct ComposeCmd {
    compose_file: String,
    env_file: Option<String>,
    project: Option<String>,
    env_vars: Vec<(String, String)>,
}

impl Default for ComposeCmd {
    fn default() -> Self {
        Self::new()
    }
}

impl ComposeCmd {
    pub fn new() -> Self {
        Self {
            compose_file: paths::compose_file().to_string_lossy().to_string(),
            env_file: {
                let ef = paths::env_file();
                ef.exists().then(|| ef.to_string_lossy().to_string())
            },
            project: None,
            env_vars: Vec::new(),
        }
    }

    pub fn project(mut self, name: &str) -> Self {
        self.project = Some(name.to_string());
        self
    }

    pub fn env(mut self, key: &str, val: &str) -> Self {
        self.env_vars.push((key.to_string(), val.to_string()));
        self
    }

    /// Build the base Command with compose file, env file, and project.
    fn base_command(&self) -> Command {
        let mut cmd = Command::new("docker");
        cmd.arg("compose");
        cmd.arg("-f").arg(&self.compose_file);
        if let Some(ef) = &self.env_file {
            cmd.arg("--env-file").arg(ef);
        }
        if let Some(p) = &self.project {
            cmd.arg("-p").arg(p);
        }
        for (k, v) in &self.env_vars {
            cmd.env(k, v);
        }
        cmd
    }

    /// Execute compose with additional args, inheriting stdin/stdout/stderr.
    pub fn execute(&self, args: &[&str]) -> Result<()> {
        let mut cmd = self.base_command();
        for arg in args {
            cmd.arg(arg);
        }
        let status = cmd
            .stdin(std::process::Stdio::inherit())
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .status()
            .map_err(|e| ZionError::Compose(format!("failed to run docker compose: {e}")))?;

        if !status.success() {
            return Err(ZionError::Compose(format!(
                "docker compose exited with code {}",
                status.code().unwrap_or(-1)
            )));
        }
        Ok(())
    }

    /// Execute and capture output.
    pub fn output(&self, args: &[&str]) -> Result<std::process::Output> {
        let mut cmd = self.base_command();
        for arg in args {
            cmd.arg(arg);
        }
        cmd.output()
            .map_err(|e| ZionError::Compose(format!("failed to run docker compose: {e}")))
    }
}
