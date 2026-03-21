//! Application state and navigation logic (TEA pattern).

use zion_sdk::status::StatusSnapshot;

/// Service list for navigation.
pub const DK_SERVICES: &[&str] = &["monolito", "bo-container", "front-student"];

/// Available environments.
pub const ENVS: &[&str] = &["sand", "local", "prod"];

/// Application state holding the current snapshot and cursor position.
pub struct App {
    /// Latest status snapshot from the SDK collector.
    pub snapshot: StatusSnapshot,
    /// Index of the currently selected service in [`DK_SERVICES`].
    pub cursor_idx: usize,
    /// Per-service selected environment index into [`ENVS`].
    pub svc_envs: Vec<usize>,
    /// Most recent action label for display: `(service_idx, description)`.
    pub last_action: Option<(usize, String)>,
}

impl App {
    /// Create a new [`App`] with default state.
    pub fn new() -> Self {
        Self {
            snapshot: StatusSnapshot::default(),
            cursor_idx: 0,
            svc_envs: vec![0; DK_SERVICES.len()],
            last_action: None,
        }
    }

    /// Return the name of the currently selected service.
    pub fn current_service(&self) -> &str {
        DK_SERVICES[self.cursor_idx]
    }

    /// Return the currently selected environment string for the active service.
    pub fn current_env(&self) -> &str {
        ENVS[self.svc_envs[self.cursor_idx]]
    }

    /// Move the cursor up, wrapping to the last service.
    pub fn move_up(&mut self) {
        if self.cursor_idx == 0 {
            self.cursor_idx = DK_SERVICES.len() - 1;
        } else {
            self.cursor_idx -= 1;
        }
    }

    /// Move the cursor down, wrapping to the first service.
    pub fn move_down(&mut self) {
        self.cursor_idx = (self.cursor_idx + 1) % DK_SERVICES.len();
    }

    /// Cycle the selected environment for the current service.
    pub fn cycle_env(&mut self) {
        let idx = self.cursor_idx;
        self.svc_envs[idx] = (self.svc_envs[idx] + 1) % ENVS.len();
    }
}
