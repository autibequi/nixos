//! Application state and navigation logic (TEA pattern).

use zion_sdk::status::StatusSnapshot;

/// Service list for navigation.
pub const DK_SERVICES: &[&str] = &["monolito", "bo-container", "front-student"];

/// Available environments.
pub const ENVS: &[&str] = &["sand", "local", "prod"];

/// Menu items: (display label, action key).
pub const MENU_ITEMS: &[(&str, &str)] = &[
    ("Start",   "start"),
    ("Stop",    "stop"),
    ("Restart", "restart"),
    ("Logs",    "logs"),
    ("Test",    "test"),
    ("Shell",   "shell"),
    ("Cancel",  "cancel"),
];

/// UI mode.
pub enum AppMode {
    Normal,
    Menu,
    Error(String),
}

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
    /// Current UI mode (normal, menu popup, error popup).
    pub mode: AppMode,
    /// Selected index in the action menu.
    pub menu_cursor: usize,
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
            mode: AppMode::Normal,
            menu_cursor: 0,
        }
    }

    pub fn open_menu(&mut self) {
        self.menu_cursor = 0;
        self.mode = AppMode::Menu;
    }

    pub fn close_menu(&mut self) {
        self.mode = AppMode::Normal;
    }

    pub fn menu_prev(&mut self) {
        if self.menu_cursor == 0 {
            self.menu_cursor = MENU_ITEMS.len() - 1;
        } else {
            self.menu_cursor -= 1;
        }
    }

    pub fn menu_next(&mut self) {
        self.menu_cursor = (self.menu_cursor + 1) % MENU_ITEMS.len();
    }

    pub fn menu_action(&self) -> &'static str {
        MENU_ITEMS[self.menu_cursor].1
    }

    pub fn set_error(&mut self, msg: String) {
        self.mode = AppMode::Error(msg);
    }

    pub fn clear_error(&mut self) {
        self.mode = AppMode::Normal;
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
