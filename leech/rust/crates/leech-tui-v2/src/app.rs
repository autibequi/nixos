//! Application state and navigation logic (TEA pattern).

use leech_sdk::status::StatusSnapshot;

pub const DK_SERVICES: &[&str] = &["monolito", "bo-container", "front-student"];
pub const ENVS: &[&str]        = &["sand", "local", "prod"];

fn svc_envs_path() -> std::path::PathBuf {
    let base = std::env::var("XDG_CONFIG_HOME")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| {
            let home = std::env::var("HOME").unwrap_or_default();
            std::path::PathBuf::from(home).join(".config")
        });
    base.join("leech").join("tui-envs")
}

pub fn load_svc_envs() -> Vec<usize> {
    if let Ok(data) = std::fs::read_to_string(svc_envs_path()) {
        let envs: Vec<usize> = data.lines()
            .filter_map(|l| l.trim().parse().ok())
            .collect();
        if envs.len() == DK_SERVICES.len() {
            return envs;
        }
    }
    vec![0; DK_SERVICES.len()]
}

pub fn save_svc_envs(envs: &[usize]) {
    let path = svc_envs_path();
    if let Some(parent) = path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    let data = envs.iter().map(|n| n.to_string()).collect::<Vec<_>>().join("\n");
    let _ = std::fs::write(path, data);
}

pub const MENU_ITEMS: &[(&str, &str)] = &[
    ("Start",         "start"),
    ("Stop",          "stop"),
    ("Restart",       "restart"),
    ("Logs",          "logs"),
    ("Test",          "test"),
    ("Install",       "install"),
    ("Shell",         "shell"),
    ("Cancel",        "cancel"),
];

pub enum AppMode {
    Normal,
    Menu,
    Error(String),
}

pub struct App {
    pub snapshot:    StatusSnapshot,
    pub cursor_idx:  usize,
    pub svc_envs:    Vec<usize>,
    pub last_action: Option<(usize, String)>,
    pub render_tick: u64,
    pub log_scroll:  usize,
    pub mode:        AppMode,
    pub menu_cursor: usize,
    /// Throttle mouse scroll: only act on every 2nd event.
    scroll_tick:     u8,
}

impl App {
    pub fn new() -> Self {
        Self {
            snapshot:    StatusSnapshot::default(),
            cursor_idx:  0,
            svc_envs:    load_svc_envs(),
            last_action: None,
            render_tick: 0,
            log_scroll:  0,
            mode:        AppMode::Normal,
            menu_cursor: 0,
            scroll_tick: 0,
        }
    }

    pub fn open_menu(&mut self) {
        self.menu_cursor = 0;
        self.mode = AppMode::Menu;
    }

    pub fn close_menu(&mut self) { self.mode = AppMode::Normal; }

    pub fn menu_prev(&mut self) {
        if self.menu_cursor == 0 { self.menu_cursor = MENU_ITEMS.len() - 1; }
        else { self.menu_cursor -= 1; }
    }

    pub fn menu_next(&mut self) {
        self.menu_cursor = (self.menu_cursor + 1) % MENU_ITEMS.len();
    }

    pub fn menu_action(&self) -> &'static str { MENU_ITEMS[self.menu_cursor].1 }

    pub fn set_error(&mut self, msg: String)  { self.mode = AppMode::Error(msg); }
    pub fn clear_error(&mut self)             { self.mode = AppMode::Normal; }

    pub fn clear_action_for(&mut self, idx: usize) {
        if matches!(&self.last_action, Some((i, _)) if *i == idx) {
            self.last_action = None;
        }
    }

    /// Returns true every 2nd call — used to throttle mouse scroll events.
    pub fn allow_mouse_scroll(&mut self) -> bool {
        self.scroll_tick = self.scroll_tick.wrapping_add(1);
        self.scroll_tick % 2 == 0
    }

    pub fn log_scroll_up(&mut self, n: usize) {
        self.log_scroll = self.log_scroll.saturating_add(n);
    }

    pub fn log_scroll_down(&mut self, n: usize) {
        self.log_scroll = self.log_scroll.saturating_sub(n);
    }

    pub fn total_items(&self) -> usize { DK_SERVICES.len() + self.snapshot.utils.len() }

    pub fn is_utils_selected(&self) -> bool { self.cursor_idx >= DK_SERVICES.len() }

    pub fn current_service(&self) -> &str {
        if self.cursor_idx < DK_SERVICES.len() {
            DK_SERVICES[self.cursor_idx]
        } else {
            let ui = self.cursor_idx - DK_SERVICES.len();
            let name = &self.snapshot.utils[ui].name;
            name.strip_prefix("leech-").unwrap_or(name)
        }
    }

    pub fn current_env(&self) -> &str {
        if self.cursor_idx < DK_SERVICES.len() {
            ENVS[self.svc_envs[self.cursor_idx]]
        } else {
            ""
        }
    }

    pub fn move_up(&mut self) {
        let total = self.total_items();
        if total == 0 { return; }
        if self.cursor_idx == 0 { self.cursor_idx = total - 1; }
        else { self.cursor_idx -= 1; }
        self.log_scroll = 0;
    }

    pub fn move_down(&mut self) {
        let total = self.total_items();
        if total == 0 { return; }
        self.cursor_idx = (self.cursor_idx + 1) % total;
        self.log_scroll = 0;
    }

    pub fn cycle_env(&mut self) {
        if self.cursor_idx >= DK_SERVICES.len() { return; }
        let idx = self.cursor_idx;
        let svc = DK_SERVICES[idx];
        let app_container = format!("leech-dk-{svc}-app");
        let is_running = self.snapshot.dk_services.iter()
            .any(|d| d.name == app_container && d.is_up);
        if !is_running {
            self.svc_envs[idx] = (self.svc_envs[idx] + 1) % ENVS.len();
            save_svc_envs(&self.svc_envs);
        }
    }
}
