//! Application state and navigation logic (TEA pattern).

pub use crate::agents::{AgentInfo, AgentLogEntry};
use crate::status::StatusSnapshot;
pub use crate::worktree::WorktreeInfo;

pub const DK_SERVICES: &[&str] = &["monolito", "monolito-worker", "bo-container", "front-student"];
pub const ENVS: &[&str]        = &["sand", "local", "prod"];

pub const AGENT_MENU_ITEMS: &[(&str, &str)] = &[
    ("Run now",      "run"),
    ("Phone",        "phone"),
    ("Status / log", "status"),
    ("Cancel",       "cancel"),
];

pub const WT_MENU_ITEMS: &[(&str, &str)] = &[
    ("Start",   "start"),
    ("Stop",    "stop"),
    ("Restart", "restart"),
    ("Logs",    "logs"),
    ("Shell",   "shell"),
    ("Install", "install"),
    ("Test",    "test"),
    ("Flush",   "flush"),
    ("Cancel",  "cancel"),
];

// ── svc-env persistence ───────────────────────────────────────────────────────

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

// ── svc-debug persistence ─────────────────────────────────────────────────────

fn svc_debug_path() -> std::path::PathBuf {
    let base = std::env::var("XDG_CONFIG_HOME")
        .map(std::path::PathBuf::from)
        .unwrap_or_else(|_| {
            let home = std::env::var("HOME").unwrap_or_default();
            std::path::PathBuf::from(home).join(".config")
        });
    base.join("leech").join("tui-debug")
}

pub fn load_svc_debug() -> Vec<bool> {
    if let Ok(data) = std::fs::read_to_string(svc_debug_path()) {
        let flags: Vec<bool> = data.lines()
            .filter_map(|l| match l.trim() { "1" => Some(true), "0" => Some(false), _ => None })
            .collect();
        if flags.len() == DK_SERVICES.len() {
            return flags;
        }
    }
    vec![false; DK_SERVICES.len()]
}

pub fn save_svc_debug(flags: &[bool]) {
    let path = svc_debug_path();
    if let Some(parent) = path.parent() {
        let _ = std::fs::create_dir_all(parent);
    }
    let data = flags.iter().map(|b| if *b { "1" } else { "0" }).collect::<Vec<_>>().join("\n");
    let _ = std::fs::write(path, data);
}

// Agent types and loaders are provided by crate::agents — imported at top.

// ── App state ─────────────────────────────────────────────────────────────────

pub const MENU_ITEMS: &[(&str, &str)] = &[
    ("Start",   "start"),
    ("Stop",    "stop"),
    ("Restart", "restart"),
    ("Logs",    "logs"),
    ("Test",    "test"),
    ("Install", "install"),
    ("Shell",   "shell"),
    ("Cancel",  "cancel"),
];

pub enum AppMode {
    Normal,
    Menu,
    Error(String),
    AgentPanel,
    WorktreePanel,
}

pub struct App {
    pub snapshot:          StatusSnapshot,
    pub snapshot_at:       std::time::Instant,
    pub cursor_idx:        usize,
    pub svc_envs:          Vec<usize>,
    pub svc_debug:         Vec<bool>,
    pub last_action:       Option<(usize, String)>,
    pub render_tick:       u64,
    pub log_scroll:        usize,
    pub mode:              AppMode,
    pub menu_cursor:       usize,
    scroll_tick:           u8,
    pub agent_cursor:      usize,
    pub agent_list:        Vec<AgentInfo>,
    /// Whether the per-agent action sub-menu is open.
    pub agent_menu:        bool,
    pub agent_menu_cursor: usize,
    /// Log entries loaded for the currently-selected agent; non-empty = log view active.
    pub agent_log:         Vec<AgentLogEntry>,
    /// Name shown in log view header.
    pub agent_log_name:    String,
    // ── Worktree panel ──
    pub wt_list:           Vec<WorktreeInfo>,
    pub wt_cursor:         usize,
    pub wt_menu:           bool,
    pub wt_menu_cursor:    usize,
}

impl App {
    pub fn new() -> Self {
        Self {
            snapshot:          StatusSnapshot::default(),
            snapshot_at:       std::time::Instant::now(),
            cursor_idx:        0,
            svc_envs:          load_svc_envs(),
            svc_debug:         load_svc_debug(),
            last_action:       None,
            render_tick:       0,
            log_scroll:        0,
            mode:              AppMode::Normal,
            menu_cursor:       0,
            scroll_tick:       0,
            agent_cursor:      0,
            agent_list:        Vec::new(),
            agent_menu:        false,
            agent_menu_cursor: 0,
            agent_log:         Vec::new(),
            agent_log_name:    String::new(),
            wt_list:           Vec::new(),
            wt_cursor:         0,
            wt_menu:           false,
            wt_menu_cursor:    0,
        }
    }

    // ── Service menu ──────────────────────────────────────────────────────────

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

    // ── Scroll ────────────────────────────────────────────────────────────────

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

    // ── Main cursor ───────────────────────────────────────────────────────────

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
        } else { "" }
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

    pub fn toggle_debug(&mut self) {
        if self.cursor_idx >= DK_SERVICES.len() { return; }
        let idx = self.cursor_idx;
        self.svc_debug[idx] = !self.svc_debug[idx];
        save_svc_debug(&self.svc_debug);
    }

    pub fn is_debug(&self) -> bool {
        self.cursor_idx < DK_SERVICES.len() && self.svc_debug[self.cursor_idx]
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

    // ── Agent panel ───────────────────────────────────────────────────────────

    pub fn open_agents(&mut self, agents: Vec<AgentInfo>) {
        self.agent_cursor      = 0;
        self.agent_menu        = false;
        self.agent_menu_cursor = 0;
        self.agent_list        = agents;
        self.mode              = AppMode::AgentPanel;
    }
    pub fn close_agents(&mut self) {
        self.agent_menu = false;
        self.mode       = AppMode::Normal;
    }

    pub fn agents_move_up(&mut self) {
        let n = self.agent_list.len();
        if n == 0 { return; }
        if self.agent_cursor == 0 { self.agent_cursor = n - 1; }
        else { self.agent_cursor -= 1; }
    }
    pub fn agents_move_down(&mut self) {
        let n = self.agent_list.len();
        if n == 0 { return; }
        self.agent_cursor = (self.agent_cursor + 1) % n;
    }

    pub fn selected_agent_name(&self) -> Option<&str> {
        self.agent_list.get(self.agent_cursor).map(|a| a.name.as_str())
    }

    // ── Agent sub-menu ────────────────────────────────────────────────────────

    pub fn open_agent_menu(&mut self) {
        self.agent_menu        = true;
        self.agent_menu_cursor = 0;
    }
    pub fn close_agent_menu(&mut self) { self.agent_menu = false; }

    pub fn open_agent_log(&mut self, name: &str, entries: Vec<AgentLogEntry>) {
        self.agent_log_name = name.to_string();
        self.agent_log      = entries;
        self.agent_menu     = false;
    }
    pub fn close_agent_log(&mut self) {
        self.agent_log.clear();
        self.agent_log_name.clear();
    }

    pub fn agent_menu_prev(&mut self) {
        if self.agent_menu_cursor == 0 {
            self.agent_menu_cursor = AGENT_MENU_ITEMS.len() - 1;
        } else {
            self.agent_menu_cursor -= 1;
        }
    }
    pub fn agent_menu_next(&mut self) {
        self.agent_menu_cursor = (self.agent_menu_cursor + 1) % AGENT_MENU_ITEMS.len();
    }
    pub fn agent_menu_action(&self) -> &'static str {
        AGENT_MENU_ITEMS[self.agent_menu_cursor].1
    }

    // ── Worktree panel ───────────────────────────────────────────────────────

    pub fn open_worktrees(&mut self, worktrees: Vec<WorktreeInfo>) {
        self.wt_cursor      = 0;
        self.wt_menu        = false;
        self.wt_menu_cursor = 0;
        self.wt_list        = worktrees;
        self.mode            = AppMode::WorktreePanel;
    }
    pub fn close_worktrees(&mut self) {
        self.wt_menu = false;
        self.mode    = AppMode::Normal;
    }

    pub fn wt_move_up(&mut self) {
        let n = self.wt_list.len();
        if n == 0 { return; }
        if self.wt_cursor == 0 { self.wt_cursor = n - 1; }
        else { self.wt_cursor -= 1; }
    }
    pub fn wt_move_down(&mut self) {
        let n = self.wt_list.len();
        if n == 0 { return; }
        self.wt_cursor = (self.wt_cursor + 1) % n;
    }

    pub fn selected_wt(&self) -> Option<&WorktreeInfo> {
        self.wt_list.get(self.wt_cursor)
    }

    pub fn open_wt_menu(&mut self) {
        self.wt_menu        = true;
        self.wt_menu_cursor = 0;
    }
    pub fn close_wt_menu(&mut self) { self.wt_menu = false; }

    pub fn wt_menu_prev(&mut self) {
        if self.wt_menu_cursor == 0 { self.wt_menu_cursor = WT_MENU_ITEMS.len() - 1; }
        else { self.wt_menu_cursor -= 1; }
    }
    pub fn wt_menu_next(&mut self) {
        self.wt_menu_cursor = (self.wt_menu_cursor + 1) % WT_MENU_ITEMS.len();
    }
    pub fn wt_menu_action(&self) -> &'static str {
        WT_MENU_ITEMS[self.wt_menu_cursor].1
    }
}
