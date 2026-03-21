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
    /// Lines scrolled up from the bottom in the log panel (0 = bottom).
    pub log_scroll: usize,
}

impl App {
    /// Create a new [`App`] with default state.
    pub fn new() -> Self {
        Self {
            snapshot: StatusSnapshot::default(),
            cursor_idx: 0,
            svc_envs: vec![0; DK_SERVICES.len()],
            last_action: None,
            log_scroll: 0,
        }
    }

    /// Scroll log panel up (towards older entries).
    pub fn log_scroll_up(&mut self, n: usize) {
        self.log_scroll = self.log_scroll.saturating_add(n);
    }

    /// Scroll log panel down (towards newer entries).
    pub fn log_scroll_down(&mut self, n: usize) {
        self.log_scroll = self.log_scroll.saturating_sub(n);
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
        self.log_scroll = 0;
    }

    /// Move the cursor down, wrapping to the first service.
    pub fn move_down(&mut self) {
        self.cursor_idx = (self.cursor_idx + 1) % DK_SERVICES.len();
        self.log_scroll = 0;
    }

    /// Cycle the selected environment for the current service.
    pub fn cycle_env(&mut self) {
        let idx = self.cursor_idx;
        self.svc_envs[idx] = (self.svc_envs[idx] + 1) % ENVS.len();
    }
}
