//! Command handlers — one sub-module per command group.

pub mod agents;
pub mod docker;
pub mod git;
pub mod host;
pub mod session;
pub mod tools;

use clap::Args;

#[allow(clippy::struct_excessive_bools)]
#[derive(Args, Debug, Clone, Default)]
pub struct SessionFlags {
    /// Project directory
    pub dir: Option<String>,
    /// Engine: claude | cursor | opencode
    #[arg(long)]
    pub engine: Option<String>,
    /// Model: haiku | sonnet | opus (or full ID)
    #[arg(long)]
    pub model: Option<String>,
    /// Instance suffix (e.g. 2)
    #[arg(long)]
    pub instance: Option<String>,
    /// Mount read-write
    #[arg(long)]
    pub rw: bool,
    /// Mount read-only
    #[arg(long)]
    pub ro: bool,
    /// Bypass engine permissions
    #[arg(long)]
    pub danger: bool,
    /// Resume session (UUID or empty for last)
    #[arg(long, num_args = 0..=1, default_missing_value = "1")]
    pub resume: Option<String>,
    /// Initial markdown file
    #[arg(long, default_value = "contexto.md")]
    pub init_md: Option<String>,
    /// Analysis mode
    #[arg(long, short = 'A')]
    pub analysis_mode: bool,
}

impl SessionFlags {
    pub fn mount_opts(&self) -> &str {
        if self.ro {
            "ro"
        } else {
            "rw"
        }
    }

    /// Resolve init_md: only return if file exists in mount dir.
    pub fn resolve_init_md(&self, mount: &std::path::Path) -> Option<String> {
        self.init_md
            .as_ref()
            .and_then(|f| mount.join(f).exists().then(|| f.clone()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mount_opts_default_rw() {
        let f = SessionFlags::default();
        assert_eq!(f.mount_opts(), "rw");
    }

    #[test]
    fn mount_opts_ro() {
        let f = SessionFlags { ro: true, ..Default::default() };
        assert_eq!(f.mount_opts(), "ro");
    }

    #[test]
    fn mount_opts_rw_explicit() {
        let f = SessionFlags { rw: true, ..Default::default() };
        assert_eq!(f.mount_opts(), "rw");
    }

    #[test]
    fn resolve_init_md_missing_file() {
        let f = SessionFlags {
            init_md: Some("nonexistent.md".into()),
            ..Default::default()
        };
        // /tmp exists but nonexistent.md doesn't
        assert_eq!(f.resolve_init_md(std::path::Path::new("/tmp")), None);
    }

    #[test]
    fn resolve_init_md_none() {
        let f = SessionFlags { init_md: None, ..Default::default() };
        assert_eq!(f.resolve_init_md(std::path::Path::new("/tmp")), None);
    }
}
