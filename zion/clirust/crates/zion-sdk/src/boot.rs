//! Boot flags — reads the injected BOOT state from environment variables.

/// Snapshot of the boot flags injected by `session-start.sh`.
#[derive(Debug, Clone, Default)]
pub struct BootInfo {
    pub datetime: String,
    pub personality: String,
    pub autocommit: String,
    pub in_docker: String,
    pub zion_edit: String,
    pub headless: String,
    pub analysis_mode: String,
    pub agent_mode: String,
    pub zion_debug: String,
    pub workspace: String,
}

/// Read boot flags from the current environment.
#[must_use]
pub fn collect() -> BootInfo {
    let env = |k: &str| std::env::var(k).unwrap_or_default();
    BootInfo {
        datetime: env("datetime"),
        personality: env("personality"),
        autocommit: env("autocommit"),
        in_docker: env("in_docker"),
        zion_edit: env("zion_edit"),
        headless: env("headless"),
        analysis_mode: env("analysis_mode"),
        agent_mode: env("agent_mode"),
        zion_debug: env("zion_debug"),
        workspace: env("workspace"),
    }
}
