//! Application state and navigation logic (TEA pattern).

use leech_sdk::status::StatusSnapshot;

pub const DK_SERVICES: &[&str] = &["monolito", "bo-container", "front-student"];
pub const ENVS: &[&str]        = &["sand", "local", "prod"];

pub const AGENT_MENU_ITEMS: &[(&str, &str)] = &[
    ("Run now",      "run"),
    ("Phone",        "phone"),
    ("Status / log", "status"),
    ("Cancel",       "cancel"),
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

// ── Agent log entry ───────────────────────────────────────────────────────────

#[derive(Debug, Clone)]
pub struct AgentLogEntry {
    /// Short timestamp like "03-24 00:20"
    pub ts_short: String,
    /// "ok" / "fail" / "timeout"
    pub status: String,
    /// "0m41s"
    pub duration: String,
    /// Card name stripped of date prefix
    pub card: String,
}

/// Read the last `limit` entries for `agent_name` from the activity log,
/// returned newest-first.
pub fn load_agent_log(agent_name: &str) -> Vec<AgentLogEntry> {
    let candidates = [
        leech_sdk::paths::obsidian_path().join("vault/logs/agents.md"),
        std::path::PathBuf::from("/workspace/obsidian/vault/logs/agents.md"),
    ];
    let Some(log_path) = candidates.iter().find(|p| p.is_file()) else {
        return Vec::new();
    };
    let Ok(content) = std::fs::read_to_string(log_path) else {
        return Vec::new();
    };

    let mut entries: Vec<AgentLogEntry> = content.lines()
        .filter(|l| l.starts_with('|') && !l.contains("Timestamp") && !l.contains("---"))
        .filter_map(|line| {
            let cols: Vec<&str> = line.split('|').map(str::trim).collect();
            // cols[0] = "", [1]=ts, [2]=agent, [3]=status, [4]=dur, [5]=tokens, [6]=card
            if cols.len() < 7 { return None; }
            let agent = cols[2];
            if agent != agent_name { return None; }
            let ts_raw  = cols[1];
            let status  = cols[3].to_string();
            let dur     = cols[4].to_string();
            let card_raw = cols[6];
            // strip date prefix YYYYMMDD_HH_MM_ or YYYYMMDD_HHMM_
            let card = {
                let stem = card_raw.trim_end_matches(".md");
                // find first non-date segment
                let parts: Vec<&str> = stem.splitn(5, '_').collect();
                if parts.len() >= 3 && parts[0].len() == 8 {
                    // YYYYMMDD_HHMM_name or YYYYMMDD_HH_MM_name
                    if parts[1].len() == 4 && parts[1].chars().all(|c| c.is_ascii_digit()) {
                        parts[2..].join("_")
                    } else if parts.len() >= 4 {
                        parts[3..].join("_")
                    } else {
                        stem.to_string()
                    }
                } else {
                    stem.to_string()
                }
            };
            // Parse timestamp: 2026-03-24T00:20:27Z → "03-24 00:20"
            let ts_short = if ts_raw.len() >= 16 {
                format!("{} {}", &ts_raw[5..10], &ts_raw[11..16])
            } else {
                ts_raw.to_string()
            };
            Some(AgentLogEntry { ts_short, status, duration: dur, card })
        })
        .collect();

    entries.reverse(); // newest first
    entries.truncate(30);
    entries
}

// ── Agent info ────────────────────────────────────────────────────────────────

/// Static information about one configured agent, enriched with schedule data.
#[derive(Debug, Clone)]
pub struct AgentInfo {
    pub name: String,
    /// Short model identifier (haiku / sonnet / opus).
    pub model: String,
    /// Clock interval in minutes; None = on-demand only.
    pub clock_mins: Option<u32>,
    /// Epoch timestamp of the soonest queued task; None = nothing queued.
    pub next_task_ts: Option<u64>,
    /// Number of task files currently queued for this agent.
    pub task_count: usize,
}

impl AgentInfo {
    /// Sort key: tasks-pending agents first (by ts), then by clock interval.
    pub fn sort_key(&self) -> (u8, u64, u32) {
        (
            if self.next_task_ts.is_some() { 0 } else { 1 },
            self.next_task_ts.unwrap_or(u64::MAX),
            self.clock_mins.unwrap_or(u32::MAX),
        )
    }
}

fn parse_clock(s: &str) -> Option<u32> {
    s.trim().strip_prefix("every").and_then(|n| n.parse().ok())
}

/// Parse a task filename stem like `20260323_0056_hermes` or
/// `20260324_03_00_doings-auto` → (epoch_secs, agent_name).
fn parse_task_stem(stem: &str) -> Option<(u64, String)> {
    let parts: Vec<&str> = stem.splitn(4, '_').collect();
    if parts.len() < 3 { return None; }
    let date_str = parts[0];
    if date_str.len() != 8 { return None; }
    let year:  u64 = date_str[..4].parse().ok()?;
    let month: u64 = date_str[4..6].parse().ok()?;
    let day:   u64 = date_str[6..8].parse().ok()?;

    // YYYYMMDD_HHMM_agent  OR  YYYYMMDD_HH_MM_agent
    let (hour, min, agent_name) =
        if parts[1].len() == 4 && parts[1].chars().all(|c| c.is_ascii_digit()) {
            let h: u64 = parts[1][..2].parse().ok()?;
            let m: u64 = parts[1][2..].parse().ok()?;
            (h, m, parts[2..].join("_"))
        } else if parts.len() >= 4 {
            let h: u64 = parts[1].parse().ok()?;
            let m: u64 = parts[2].parse().ok()?;
            (h, m, parts[3..].join("_"))
        } else {
            return None;
        };

    let epoch = date_to_epoch(year, month, day) + hour * 3600 + min * 60;
    Some((epoch, agent_name))
}

fn date_to_epoch(y: u64, m: u64, d: u64) -> u64 {
    let (m_adj, y_adj) = if m > 2 { (m - 3, y - 1970) } else { (m + 9, y - 1971) };
    let days = 365 * y_adj + y_adj / 4 - y_adj / 100 + y_adj / 400
        + (153 * m_adj + 2) / 5 + d - 1;
    days * 86400
}

fn frontmatter_field(content: &str, key: &str) -> Option<String> {
    let mut in_fm = false;
    for line in content.lines() {
        if line == "---" {
            if in_fm { break; }
            in_fm = true;
            continue;
        }
        if in_fm {
            if let Some(rest) = line.strip_prefix(&format!("{key}:")) {
                return Some(rest.trim().to_string());
            }
        }
    }
    None
}

/// Load all configured agents from `self/agents/*/agent.md`,
/// enriched with pending task counts and next-run timestamps.
pub fn load_all_agents() -> Vec<AgentInfo> {
    let candidates = [
        leech_sdk::paths::leech_root().parent()
            .map(|p| p.join("agents"))
            .unwrap_or_default(),
        std::path::PathBuf::from("/workspace/self/agents"),
        leech_sdk::paths::home().join("nixos/leech/self/agents"),
    ];
    let Some(agents_base) = candidates.into_iter().find(|p| p.is_dir()) else {
        return Vec::new();
    };

    // Build map: agent_name → (earliest_task_ts, count)
    let mut task_map: std::collections::HashMap<String, (u64, usize)> =
        std::collections::HashMap::new();
    if let Some(tasks_dir) = leech_sdk::paths::tasks_dir() {
        let queue = tasks_dir.join("AGENTS");
        if queue.is_dir() {
            for entry in std::fs::read_dir(&queue).into_iter().flatten().flatten() {
                let path = entry.path();
                if path.is_dir() { continue; }
                if path.extension().and_then(|e| e.to_str()) != Some("md") { continue; }
                let stem = path.file_stem()
                    .map(|s| s.to_string_lossy().into_owned())
                    .unwrap_or_default();
                if let Some((ts, name)) = parse_task_stem(&stem) {
                    let e = task_map.entry(name).or_insert((u64::MAX, 0));
                    if ts < e.0 { e.0 = ts; }
                    e.1 += 1;
                }
            }
        }
    }

    let mut infos: Vec<AgentInfo> = std::fs::read_dir(&agents_base)
        .into_iter().flatten().flatten()
        .filter_map(|e| {
            let dir = e.path();
            if !dir.is_dir() { return None; }
            let name = dir.file_name()?.to_string_lossy().into_owned();
            if name.starts_with('_') { return None; }
            let card = dir.join("agent.md");
            let content = std::fs::read_to_string(&card).ok()?;
            let model      = frontmatter_field(&content, "model").unwrap_or_else(|| "?".into());
            let clock_mins = frontmatter_field(&content, "clock")
                .as_deref().and_then(parse_clock);
            let (next_task_ts, task_count) = task_map.get(&name)
                .map(|(ts, c)| (if *ts == u64::MAX { None } else { Some(*ts) }, *c))
                .unwrap_or((None, 0));
            Some(AgentInfo { name, model, clock_mins, next_task_ts, task_count })
        })
        .collect();

    infos.sort_by_key(|a| a.sort_key());
    infos
}

// ── App state ─────────────────────────────────────────────────────────────────

pub const MENU_ITEMS: &[(&str, &str)] = &[
    ("Start",    "start"),
    ("Stop",     "stop"),
    ("Restart",  "restart"),
    ("Logs",     "logs"),
    ("Test",     "test"),
    ("Install",  "install"),
    ("Shell",    "shell"),
    ("Cancel",   "cancel"),
];

pub enum AppMode {
    Normal,
    Menu,
    Error(String),
    AgentPanel,
}

pub struct App {
    pub snapshot:          StatusSnapshot,
    pub cursor_idx:        usize,
    pub svc_envs:          Vec<usize>,
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
}

impl App {
    pub fn new() -> Self {
        Self {
            snapshot:          StatusSnapshot::default(),
            cursor_idx:        0,
            svc_envs:          load_svc_envs(),
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

    pub fn open_agents(&mut self) {
        self.agent_cursor      = 0;
        self.agent_menu        = false;
        self.agent_menu_cursor = 0;
        self.agent_list        = load_all_agents();
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

    pub fn open_agent_log(&mut self, name: &str) {
        self.agent_log_name = name.to_string();
        self.agent_log      = load_agent_log(name);
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
}
