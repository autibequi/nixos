pub mod contractors;
pub mod docker;
pub mod git;
pub mod host;
pub mod session;
pub mod tools;

use clap::Args;

/// Shared flags for all session-creating commands.
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
        if self.ro { "ro" } else { "rw" }
    }

    /// Resolve init_md: only return if file exists in mount dir.
    pub fn resolve_init_md(&self, mount: &std::path::Path) -> Option<String> {
        self.init_md.as_ref().and_then(|f| {
            mount.join(f).exists().then(|| f.clone())
        })
    }
}
