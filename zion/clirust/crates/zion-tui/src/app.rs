use zion_sdk::status::StatusSnapshot;

/// Service list for navigation.
pub const DK_SERVICES: &[&str] = &["monolito", "bo-container", "front-student"];

/// Available environments.
pub const ENVS: &[&str] = &["sand", "local", "prod"];

/// Application state (TEA pattern).
pub struct App {
    pub snapshot: StatusSnapshot,
    pub cursor_idx: usize,
    pub svc_envs: Vec<usize>,                 // index into ENVS per service
    pub last_action: Option<(usize, String)>, // (service_idx, action label)
}

impl App {
    pub fn new(_tick: u64) -> Self {
        Self {
            snapshot: StatusSnapshot::default(),
            cursor_idx: 0,
            svc_envs: vec![0; DK_SERVICES.len()],
            last_action: None,
        }
    }

    pub fn current_service(&self) -> &str {
        DK_SERVICES[self.cursor_idx]
    }

    pub fn current_env(&self) -> &str {
        ENVS[self.svc_envs[self.cursor_idx]]
    }

    pub fn move_up(&mut self) {
        if self.cursor_idx == 0 {
            self.cursor_idx = DK_SERVICES.len() - 1;
        } else {
            self.cursor_idx -= 1;
        }
    }

    pub fn move_down(&mut self) {
        self.cursor_idx = (self.cursor_idx + 1) % DK_SERVICES.len();
    }

    pub fn cycle_env(&mut self) {
        let idx = self.cursor_idx;
        self.svc_envs[idx] = (self.svc_envs[idx] + 1) % ENVS.len();
    }
}
