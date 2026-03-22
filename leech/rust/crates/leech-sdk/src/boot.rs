//! Boot flags — reads the injected BOOT state from environment variables.
//! When running on the host (no session active), flags will be empty strings.

/// Snapshot of the boot flags injected by `session-start.sh`.
#[derive(Debug, Clone, Default)]
pub struct BootInfo {
    pub datetime: String,
    pub personality: String,
    pub autocommit: String,
    pub in_docker: String,
    pub leech_edit: String,
    pub headless: String,
    pub analysis_mode: String,
    pub agent_mode: String,
    pub leech_debug: String,
    pub workspace: String,
    /// True if any session flag was found (running inside a session).
    pub has_session: bool,
}

/// Read boot flags from the current environment.
#[must_use]
pub fn collect() -> BootInfo {
    let env = |k: &str| std::env::var(k).unwrap_or_default();
    let datetime      = env("datetime");
    let personality   = env("personality");
    let autocommit    = env("autocommit");
    let in_docker     = env("in_docker");
    let leech_edit     = env("leech_edit");
    let headless      = env("headless");
    let analysis_mode = env("analysis_mode");
    let agent_mode    = env("agent_mode");
    let leech_debug    = env("leech_debug");
    let workspace     = env("workspace");

    let has_session = !datetime.is_empty() || !personality.is_empty() || !in_docker.is_empty();

    BootInfo {
        datetime,
        personality,
        autocommit,
        in_docker,
        leech_edit,
        headless,
        analysis_mode,
        agent_mode,
        leech_debug,
        workspace,
        has_session,
    }
}
