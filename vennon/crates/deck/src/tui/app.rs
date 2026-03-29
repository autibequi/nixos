use crate::process::{output_with_timeout, CMD_TIMEOUT};
use anyhow::Result;
use chrono::{DateTime, Utc};
use std::collections::HashMap;
use std::io;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::mpsc::{self, Receiver, TryRecvError};
use std::time::Duration;

/// Slugs de IDE usados em nomes `vennon-{ide}` (referência para filtros/TUI).
#[allow(dead_code)]
pub const IDE_NAMES: &[&str] = &["claude", "opencode", "cursor"];

/// Linha do `podman ps`: status, up?, cpu, mem.
type RunningPodRow = (String, bool, String, String);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ContainerKind {
    Ide,
    Service,
    /// Postgres/Redis/Localstack do stack monolito — só logs no painel, sem menu vennon.
    Sidecar,
    /// Systemd user services (buzz, yaa-tick) — shown as dots in header, not in table.
    SystemdService,
}

/// One enum group from vennon.yaml (e.g. env, vertical).
#[derive(Debug, Clone)]
pub struct EnumGroup {
    pub name: String,
    pub values: Vec<String>,
    pub default: String,
}

#[derive(Debug, Clone)]
pub struct ContainerInfo {
    pub name: String,
    pub display_name: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
    /// Raw APP_ENV value from running container (e.g. "sand", "local", "prod").
    pub env: String,
    /// "on" / "off" / "" — from DEBUG env var.
    pub debug: String,
    /// Raw VERTICAL value from running container (e.g. "medicina", "oab").
    pub vertical: String,
    /// Build/status hint from last log line (e.g. "building 33m"). Empty = use podman status.
    pub last_log: String,
    /// All enums from vennon.yaml (env, vertical, and any future ones).
    pub enums: Vec<EnumGroup>,
    /// Whether the serve command has a --debug bool arg.
    pub has_debug: bool,
    pub commands: Vec<String>,
    pub kind: ContainerKind,
}

impl ContainerInfo {
    /// Get current display value for a given enum name (from podman inspect or default).
    pub fn current_for_enum(&self, enum_name: &str) -> &str {
        match enum_name {
            "env" => &self.env,
            "vertical" => &self.vertical,
            _ => "",
        }
    }
}

#[derive(Clone, Copy, PartialEq)]
pub enum Tab {
    Services,
    Agents,
}

#[derive(Clone, Copy, PartialEq, Eq)]
pub enum AppMode {
    Normal,
    Menu,
    Help,
}

pub struct App {
    pub mode: AppMode,
    pub tab: Tab,
    pub all_containers: Vec<ContainerInfo>,
    pub cursor: usize,
    pub menu_cursor: usize,
    pub logs: Vec<String>,
    pub log_scroll: usize,
    /// When true, scroll snaps to the bottom on every refresh.
    pub log_follow: bool,
    /// True while a background `RefreshSnapshot::collect` is in flight.
    pub refresh_inflight: bool,
    /// Spinner frame counter — increments every poll cycle while refresh_inflight.
    pub spin_tick: u8,
    /// True if the last completed refresh hit a subprocess timeout (podman/vennon).
    pub subprocess_degraded: bool,
    /// Instant when the last snapshot finished applying (UTC internally; UI shows local time).
    pub last_refresh: Option<DateTime<Utc>>,
    /// Mode to restore when closing the help overlay.
    pub help_return: AppMode,
    pending_refresh: Option<Receiver<RefreshSnapshot>>,
}

/// Result of one full data fetch (containers + logs for current selection).
pub struct RefreshSnapshot {
    pub containers: Vec<ContainerInfo>,
    pub logs: Vec<String>,
    pub log_scroll: usize,
    pub had_subprocess_timeout: bool,
}

impl App {
    pub fn new() -> Self {
        Self {
            mode: AppMode::Normal,
            tab: Tab::Services,
            all_containers: vec![],
            cursor: 0,
            menu_cursor: 0,
            logs: vec![],
            log_scroll: 0,
            log_follow: true,
            refresh_inflight: false,
            spin_tick: 0,
            subprocess_degraded: false,
            last_refresh: None,
            help_return: AppMode::Normal,
            pending_refresh: None,
        }
    }

    pub fn open_help(&mut self) {
        if matches!(self.mode, AppMode::Help) {
            return;
        }
        self.help_return = match self.mode {
            AppMode::Menu => AppMode::Menu,
            AppMode::Normal | AppMode::Help => AppMode::Normal,
        };
        self.mode = AppMode::Help;
    }

    pub fn close_help(&mut self) {
        if matches!(self.mode, AppMode::Help) {
            self.mode = self.help_return;
        }
    }

    pub fn visible_containers(&self) -> Vec<&ContainerInfo> {
        Self::visible_containers_slice(&self.all_containers, self.tab)
    }

    fn visible_containers_slice(all: &[ContainerInfo], tab: Tab) -> Vec<&ContainerInfo> {
        all.iter()
            .filter(|c| match tab {
                Tab::Agents => c.kind == ContainerKind::Ide,
                Tab::Services => {
                    c.kind != ContainerKind::Ide && c.kind != ContainerKind::SystemdService
                }
            })
            .collect()
    }

    /// Systemd service rows (buzz, tick) — shown as dots in the header.
    pub fn systemd_containers(&self) -> Vec<&ContainerInfo> {
        self.all_containers
            .iter()
            .filter(|c| c.kind == ContainerKind::SystemdService)
            .collect()
    }

    pub fn refresh(&mut self) -> Result<()> {
        let snap = RefreshSnapshot::collect(self.tab, self.cursor);
        self.apply_snapshot(snap);
        Ok(())
    }

    fn apply_snapshot(&mut self, snap: RefreshSnapshot) {
        self.all_containers = snap.containers;
        self.logs = snap.logs;
        if self.log_follow {
            self.log_scroll = snap.log_scroll;
        }
        self.subprocess_degraded = snap.had_subprocess_timeout;
        self.refresh_inflight = false;
        self.pending_refresh = None;
        self.last_refresh = Some(Utc::now());
        let vis = self.visible_containers();
        if self.cursor >= vis.len() && !vis.is_empty() {
            self.cursor = vis.len() - 1;
        }
    }

    /// Spawn background refresh (no blocking on podman/vennon beyond OS scheduling).
    pub fn kick_background_refresh(&mut self) {
        if self.refresh_inflight {
            return;
        }
        let (tx, rx) = mpsc::channel();
        self.pending_refresh = Some(rx);
        self.refresh_inflight = true;
        let tab = self.tab;
        let cursor = self.cursor;
        std::thread::spawn(move || {
            let snap = RefreshSnapshot::collect(tab, cursor);
            let _ = tx.send(snap);
        });
    }

    pub fn poll_refresh_done(&mut self) {
        if self.refresh_inflight {
            self.spin_tick = self.spin_tick.wrapping_add(1);
        }
        let Some(rx) = self.pending_refresh.take() else {
            return;
        };
        match rx.try_recv() {
            Ok(snap) => {
                self.apply_snapshot(snap);
            }
            Err(TryRecvError::Empty) => {
                self.pending_refresh = Some(rx);
            }
            Err(TryRecvError::Disconnected) => {
                self.refresh_inflight = false;
            }
        }
    }

    fn refresh_logs(&mut self) {
        let (logs, timed_out, scroll) =
            logs_for_selection_with_timeout(&self.all_containers, self.tab, self.cursor);
        self.logs = logs;
        if self.log_follow {
            self.log_scroll = scroll;
        }
        if timed_out {
            self.subprocess_degraded = true;
        }
    }

    pub fn next(&mut self) {
        let len = self.visible_containers().len();
        if len > 0 {
            self.cursor = (self.cursor + 1) % len;
            self.refresh_logs();
        }
    }

    pub fn prev(&mut self) {
        let len = self.visible_containers().len();
        if len > 0 {
            self.cursor = self.cursor.checked_sub(1).unwrap_or(len - 1);
            self.refresh_logs();
        }
    }

    pub fn switch_tab(&mut self) {
        self.tab = match self.tab {
            Tab::Services => Tab::Agents,
            Tab::Agents => Tab::Services,
        };
        self.cursor = 0;
        self.refresh_logs();
    }

    pub fn open_menu(&mut self) {
        if self.menu_actions().is_empty() {
            return;
        }
        if !self.visible_containers().is_empty() {
            self.mode = AppMode::Menu;
            self.menu_cursor = 0;
        }
    }

    pub fn close_menu(&mut self) {
        self.mode = AppMode::Normal;
    }

    pub fn menu_next(&mut self) {
        let actions = self.menu_actions();
        if actions.is_empty() {
            return;
        }
        let mut next = (self.menu_cursor + 1) % actions.len();
        // Skip headers and separators
        for _ in 0..3 {
            if is_menu_separator(actions.get(next).map(|a| a.as_str()).unwrap_or("")) {
                next = (next + 1) % actions.len();
            } else {
                break;
            }
        }
        self.menu_cursor = next;
    }

    pub fn menu_prev(&mut self) {
        let actions = self.menu_actions();
        if actions.is_empty() {
            return;
        }
        let mut prev = self.menu_cursor.checked_sub(1).unwrap_or(actions.len() - 1);
        // Skip headers and separators
        for _ in 0..3 {
            if is_menu_separator(actions.get(prev).map(|a| a.as_str()).unwrap_or("")) {
                prev = prev.checked_sub(1).unwrap_or(actions.len() - 1);
            } else {
                break;
            }
        }
        self.menu_cursor = prev;
    }

    /// Get menu actions for the selected container.
    pub fn menu_actions(&self) -> Vec<String> {
        if let Some(c) = self.selected_container() {
            match c.kind {
                ContainerKind::Sidecar | ContainerKind::SystemdService => vec![],
                ContainerKind::Ide if c.commands.is_empty() => vec![
                    "start".into(),
                    "stop".into(),
                    "shell".into(),
                    "build".into(),
                    "flush".into(),
                ],
                ContainerKind::Ide => c.commands.clone(),
                ContainerKind::Service => {
                    let mut actions = c.commands.clone();
                    // Enum groups — each becomes a labeled section in the menu
                    for group in &c.enums {
                        actions.push(format!("# {}", group.name.to_uppercase()));
                        let current = c.current_for_enum(&group.name);
                        for v in &group.values {
                            let short = shorten_param(&group.name, v);
                            let mark = if short == current { " ✓" } else { "" };
                            actions.push(format!("{}:{v}{mark}", group.name));
                        }
                    }
                    // Debug is a bool arg, not an enum — special group
                    if c.has_debug {
                        actions.push("# DEBUG".into());
                        let on_mark = if c.debug == "on" { " ✓" } else { "" };
                        let off_mark = if c.debug == "off" || c.debug.is_empty() {
                            " ✓"
                        } else {
                            ""
                        };
                        actions.push(format!("debug:on{on_mark}"));
                        actions.push(format!("debug:off{off_mark}"));
                    }
                    actions
                }
            }
        } else {
            vec![]
        }
    }

    pub fn selected_action(&self) -> Option<String> {
        let actions = self.menu_actions();
        actions.get(self.menu_cursor).cloned()
    }

    pub fn selected_container(&self) -> Option<ContainerInfo> {
        let vis = self.visible_containers();
        vis.get(self.cursor).map(|c| (*c).clone())
    }

    pub fn scroll_logs_up(&mut self) {
        self.scroll_logs_up_by(5);
    }

    pub fn scroll_logs_up_by(&mut self, lines: usize) {
        self.log_follow = false;
        self.log_scroll = self.log_scroll.saturating_sub(lines);
    }

    pub fn scroll_logs_down(&mut self) {
        self.scroll_logs_down_by(5);
    }

    pub fn scroll_logs_down_by(&mut self, lines: usize) {
        let max = self.logs.len().saturating_sub(10);
        self.log_scroll = (self.log_scroll + lines).min(max);
        if self.log_scroll >= max {
            self.log_follow = true;
        }
    }

    pub fn toggle_follow(&mut self) {
        self.log_follow = !self.log_follow;
        if self.log_follow {
            self.log_scroll = self.logs.len().saturating_sub(20);
        }
    }

    pub fn exec_action(&self, action: &str) -> Result<()> {
        if is_menu_separator(action) {
            return Ok(());
        }
        let action = action.trim_end_matches(" ✓");
        let container = match self.selected_container() {
            Some(c) => c,
            None => return Ok(()),
        };

        // monolito-worker: route commands through monolito
        if container.display_name == "monolito-worker" {
            return self.exec_worker_action(action, &container);
        }

        // Debug toggle — special case (bool, not enum)
        if let Some(dbg_val) = action.strip_prefix("debug:") {
            let flag = if dbg_val == "on" {
                "--debug=true"
            } else {
                "--debug=false"
            };
            let mut args = vec![container.display_name.clone(), "serve".into(), flag.into()];
            self.append_preserved_params(&container, Some("debug"), &mut args);
            let _ = Command::new("vennon").args(&args).status();
            return Ok(());
        }

        // Generic enum parameter — matches any "name:value" where name is a known enum
        if let Some((param_name, param_val)) = action.split_once(':') {
            let is_known_enum = container.enums.iter().any(|g| g.name == param_name);
            if is_known_enum {
                let mut args = vec![
                    container.display_name.clone(),
                    "serve".into(),
                    format!("--{param_name}={param_val}"),
                ];
                self.append_preserved_params(&container, Some(param_name), &mut args);
                let _ = Command::new("vennon").args(&args).status();
                return Ok(());
            }
        }

        // Plain command (serve, stop, logs, etc.)
        let _ = Command::new("vennon")
            .args([&container.display_name, action])
            .status();
        Ok(())
    }

    /// Route monolito-worker actions through `vennon monolito worker` / podman.
    fn exec_worker_action(&self, action: &str, container: &ContainerInfo) -> Result<()> {
        // Enum param switch → restart worker with new params
        if let Some(dbg_val) = action.strip_prefix("debug:") {
            let flag = if dbg_val == "on" {
                "--debug=true"
            } else {
                "--debug=false"
            };
            let mut args = vec!["monolito".into(), "worker".into(), flag.into()];
            self.append_preserved_params(container, Some("debug"), &mut args);
            let _ = Command::new("vennon").args(&args).status();
            return Ok(());
        }
        if let Some((param_name, param_val)) = action.split_once(':') {
            let is_known_enum = container.enums.iter().any(|g| g.name == param_name);
            if is_known_enum {
                let mut args = vec![
                    "monolito".into(),
                    "worker".into(),
                    format!("--{param_name}={param_val}"),
                ];
                self.append_preserved_params(container, Some(param_name), &mut args);
                let _ = Command::new("vennon").args(&args).status();
                return Ok(());
            }
        }
        match action {
            "start" => {
                let mut args = vec!["monolito".into(), "worker".into()];
                self.append_preserved_params(container, None, &mut args);
                let _ = Command::new("vennon").args(&args).status();
            }
            "stop" => {
                let _ = Command::new("podman")
                    .args(["stop", MONOLITO_WORKER_CONTAINER])
                    .status();
            }
            "logs" => {
                let _ = Command::new("podman")
                    .args(["logs", "-f", "--tail", "100", MONOLITO_WORKER_CONTAINER])
                    .status();
            }
            "shell" => {
                let _ = Command::new("podman")
                    .args(["exec", "-it", MONOLITO_WORKER_CONTAINER, "/bin/bash"])
                    .status();
            }
            _ => {
                // Fallback: try as vennon monolito <action>
                let _ = Command::new("vennon").args(["monolito", action]).status();
            }
        }
        Ok(())
    }

    /// True for actions that need an interactive terminal (shell).
    pub fn is_interactive_action(&self, action: &str) -> bool {
        let action = action.trim_end_matches(" ✓");
        action == "shell"
    }

    /// Like exec_action but spawns in background (non-blocking, no terminal needed).
    pub fn exec_action_bg(&self, action: &str) -> Result<()> {
        if is_menu_separator(action) {
            return Ok(());
        }
        let action = action.trim_end_matches(" ✓");
        let container = match self.selected_container() {
            Some(c) => c,
            None => return Ok(()),
        };

        // monolito-worker routing
        if container.display_name == "monolito-worker" {
            return self.exec_worker_action_bg(action, &container);
        }

        // Debug toggle
        if let Some(dbg_val) = action.strip_prefix("debug:") {
            let flag = if dbg_val == "on" {
                "--debug=true"
            } else {
                "--debug=false"
            };
            let mut args = vec![container.display_name.clone(), "serve".into(), flag.into()];
            self.append_preserved_params(&container, Some("debug"), &mut args);
            spawn_silent("vennon", &args);
            return Ok(());
        }

        // Generic enum parameter
        if let Some((param_name, param_val)) = action.split_once(':') {
            let is_known_enum = container.enums.iter().any(|g| g.name == param_name);
            if is_known_enum {
                let mut args = vec![
                    container.display_name.clone(),
                    "serve".into(),
                    format!("--{param_name}={param_val}"),
                ];
                self.append_preserved_params(&container, Some(param_name), &mut args);
                spawn_silent("vennon", &args);
                return Ok(());
            }
        }

        // Plain command
        spawn_silent(
            "vennon",
            &[container.display_name.clone(), action.to_string()],
        );
        Ok(())
    }

    /// Background version of exec_worker_action.
    fn exec_worker_action_bg(&self, action: &str, container: &ContainerInfo) -> Result<()> {
        if let Some(dbg_val) = action.strip_prefix("debug:") {
            let flag = if dbg_val == "on" {
                "--debug=true"
            } else {
                "--debug=false"
            };
            let mut args = vec!["monolito".into(), "worker".into(), flag.into()];
            self.append_preserved_params(container, Some("debug"), &mut args);
            spawn_silent("vennon", &args);
            return Ok(());
        }
        if let Some((param_name, param_val)) = action.split_once(':') {
            let is_known_enum = container.enums.iter().any(|g| g.name == param_name);
            if is_known_enum {
                let mut args = vec![
                    "monolito".into(),
                    "worker".into(),
                    format!("--{param_name}={param_val}"),
                ];
                self.append_preserved_params(container, Some(param_name), &mut args);
                spawn_silent("vennon", &args);
                return Ok(());
            }
        }
        match action {
            "start" => {
                let mut args = vec!["monolito".into(), "worker".into()];
                self.append_preserved_params(container, None, &mut args);
                spawn_silent("vennon", &args);
            }
            "stop" => {
                spawn_silent("podman", &["stop".into(), MONOLITO_WORKER_CONTAINER.into()]);
            }
            "logs" => {
                // logs needs terminal — fallback to noop in bg, user uses log panel
            }
            _ => {
                spawn_silent("vennon", &["monolito".into(), action.into()]);
            }
        }
        Ok(())
    }

    /// Append --flag for all other params so switching one doesn't lose the rest.
    fn append_preserved_params(
        &self,
        container: &ContainerInfo,
        skip: Option<&str>,
        args: &mut Vec<String>,
    ) {
        for group in &container.enums {
            if skip == Some(group.name.as_str()) {
                continue;
            }
            let current = container.current_for_enum(&group.name);
            if !current.is_empty() {
                // Reverse-lookup: find the full enum value that matches the shortened display
                let full_val = group
                    .values
                    .iter()
                    .find(|v| shorten_param(&group.name, v) == current)
                    .cloned()
                    .unwrap_or_else(|| current.to_string());
                args.push(format!("--{}={}", group.name, full_val));
            }
        }
        if skip != Some("debug") && container.debug == "on" && container.has_debug {
            args.push("--debug=true".into());
        }
    }
}

impl RefreshSnapshot {
    pub fn collect(tab: Tab, cursor: usize) -> Self {
        let (containers, mut timed_out) = collect_all();
        let (logs, lt, log_scroll) = logs_for_selection_with_timeout(&containers, tab, cursor);
        timed_out |= lt;
        Self {
            containers,
            logs,
            log_scroll,
            had_subprocess_timeout: timed_out,
        }
    }
}

fn logs_for_selection_with_timeout(
    containers: &[ContainerInfo],
    tab: Tab,
    cursor: usize,
) -> (Vec<String>, bool, usize) {
    let vis = App::visible_containers_slice(containers, tab);
    if let Some(c) = vis.get(cursor) {
        if c.is_up {
            let (logs, t) = collect_logs_for(&c.name);
            let log_scroll = logs.len().saturating_sub(20);
            (logs, t, log_scroll)
        } else {
            (vec![format!("{} — not running", c.display_name)], false, 0)
        }
    } else {
        (vec![], false, 0)
    }
}

// ── Data collection ─────────────────────────────────────────────

fn collect_all() -> (Vec<ContainerInfo>, bool) {
    let mut any_timeout = false;
    let mut containers = vec![];
    let (running, t) = collect_running();
    any_timeout |= t;

    // 1. IDE containers — always show claude/opencode/cursor
    // yaa/vennon uses project vennon-{ide}-{VENNON_INSTANCE}, so match exact name or vennon-{ide}-* .
    for name in &["claude", "opencode", "cursor"] {
        let row = ide_row(name, &running);
        containers.push(row);
    }

    // 2. Service containers — discover from vennon list
    let mut cmd = Command::new("vennon");
    cmd.args(["list"]);
    match output_with_timeout(cmd, CMD_TIMEOUT) {
        Ok(output) => {
            let stdout = String::from_utf8_lossy(&output.stdout);
            for line in stdout.lines() {
                // Format: "  [svc] monolito (mono)"
                if !line.contains("[svc]") {
                    continue;
                }
                let name = line
                    .trim()
                    .strip_prefix("[svc] ")
                    .unwrap_or("")
                    .split(' ')
                    .next()
                    .unwrap_or("")
                    .to_string();
                if name.is_empty() {
                    continue;
                }

                let podman_name = resolve_service_podman_name(&name, &running);

                let (status, is_up, cpu, mem) = running
                    .get(&podman_name)
                    .cloned()
                    .unwrap_or_else(|| ("stopped".into(), false, String::new(), String::new()));

                let manifest = get_manifest_data(&name);

                // Use enum defaults for stopped containers; running ones get overwritten by podman inspect below.
                let env_default = {
                    let d = manifest.enum_default("env");
                    if d.is_empty() {
                        String::new()
                    } else {
                        shorten_env(d)
                    }
                };
                let vert_default = {
                    let d = manifest.enum_default("vertical");
                    if d.is_empty() {
                        String::new()
                    } else {
                        shorten_vertical(d)
                    }
                };

                // Clone enums/has_debug before moving into ContainerInfo — worker reuses them
                let worker_enums = if name == "monolito" {
                    manifest.enums.clone()
                } else {
                    vec![]
                };
                let worker_has_debug = if name == "monolito" {
                    manifest.has_debug
                } else {
                    false
                };

                containers.push(ContainerInfo {
                    name: podman_name,
                    display_name: name.clone(),
                    status,
                    is_up,
                    cpu,
                    mem,
                    env: env_default,
                    debug: String::new(),
                    vertical: vert_default,
                    last_log: String::new(),
                    enums: manifest.enums,
                    has_debug: manifest.has_debug,
                    commands: manifest.commands,
                    kind: ContainerKind::Service,
                });

                if name == "monolito" {
                    // Worker: separate service entry (not sidecar) with full menu
                    let worker_row = monolito_worker_row(&running, worker_enums, worker_has_debug);
                    containers.push(worker_row);

                    for sidecar in monolito_sidecar_rows(&running) {
                        containers.push(sidecar);
                    }
                }
            }
        }
        Err(e) if e.kind() == io::ErrorKind::TimedOut => {
            any_timeout = true;
        }
        Err(_) => {}
    }

    // Populate env/debug for running containers (services + IDEs, skip sidecars)
    let running_names: Vec<String> = containers
        .iter()
        .filter(|c| c.is_up && c.kind != ContainerKind::Sidecar)
        .map(|c| c.name.clone())
        .collect();
    let env_info = collect_container_envs(&running_names);
    for c in &mut containers {
        if let Some((env, debug, vertical)) = env_info.get(&c.name) {
            c.env = env.clone();
            c.debug = debug.clone();
            c.vertical = vertical.clone();
        }
    }

    // Detect build status from last log line for running service containers
    let build_hints = collect_build_hints(&containers);
    for c in &mut containers {
        if let Some(hint) = build_hints.get(&c.name) {
            c.last_log = hint.clone();
        }
    }

    // Systemd service dots (buzz, yaa-tick) — not shown in table, only in header
    for row in systemd_service_rows() {
        containers.push(row);
    }

    (containers, any_timeout)
}

/// Fetch last log line for running service containers and detect build patterns.
/// Returns map: container_name → display string (e.g. "building 33m").
fn collect_build_hints(containers: &[ContainerInfo]) -> HashMap<String, String> {
    let mut hints = HashMap::new();
    let svc_running: Vec<&ContainerInfo> = containers
        .iter()
        .filter(|c| c.is_up && c.kind == ContainerKind::Service)
        .collect();

    if svc_running.is_empty() {
        return hints;
    }

    for c in &svc_running {
        let mut cmd = Command::new("podman");
        cmd.args(["logs", "--tail", "1", &c.name]);
        if let Ok(output) = output_with_timeout(cmd, Duration::from_secs(3)) {
            let text = String::from_utf8_lossy(&output.stdout);
            let stderr = String::from_utf8_lossy(&output.stderr);
            let last_line = text
                .lines()
                .last()
                .or_else(|| stderr.lines().last())
                .unwrap_or("");
            let clean = strip_ansi(last_line);

            // Match patterns: "buildando... Xm" or "[service] buildando... XmYs"
            if clean.contains("buildando") {
                // Extract time from end: "buildando... 33m0s" → "building 33m"
                if let Some(time_str) = extract_build_time(&clean) {
                    hints.insert(c.name.clone(), format!("building {time_str}"));
                } else {
                    hints.insert(c.name.clone(), "building…".into());
                }
            } else if clean.contains("compiling") || clean.contains("Compiling") {
                hints.insert(c.name.clone(), "compiling…".into());
            }
        }
    }
    hints
}

/// Extract time from build progress line like "[front-student] buildando... 33m0s"
fn extract_build_time(line: &str) -> Option<String> {
    // Look for pattern: digits followed by 'm' near the end
    let trimmed = line.trim();
    // Find last word that looks like a timestamp (e.g., "33m0s", "1m20s")
    for word in trimmed.split_whitespace().rev() {
        if word.contains('m')
            && word
                .chars()
                .next()
                .map(|c| c.is_ascii_digit())
                .unwrap_or(false)
        {
            // Simplify: "33m0s" → "33m"
            if let Some(pos) = word.find('m') {
                return Some(word[..=pos].to_string());
            }
        }
    }
    None
}

const MONOLITO_WORKER_CONTAINER: &str = "vennon-dk-monolito-worker-app";

/// Monolito worker as a standalone service row (with full menu).
fn monolito_worker_row(
    running: &HashMap<String, RunningPodRow>,
    enums: Vec<EnumGroup>,
    has_debug: bool,
) -> ContainerInfo {
    let (status, is_up, cpu, mem) = running
        .get(MONOLITO_WORKER_CONTAINER)
        .cloned()
        .unwrap_or_else(|| ("stopped".into(), false, String::new(), String::new()));

    // Reuse monolito enums defaults for display
    let env_default = enums
        .iter()
        .find(|e| e.name == "env")
        .map(|e| shorten_env(&e.default))
        .unwrap_or_default();

    ContainerInfo {
        name: MONOLITO_WORKER_CONTAINER.to_string(),
        display_name: "monolito-worker".to_string(),
        status,
        is_up,
        cpu,
        mem,
        env: env_default,
        debug: String::new(),
        vertical: String::new(),
        last_log: String::new(),
        enums,
        has_debug,
        commands: vec!["start".into(), "stop".into(), "logs".into(), "shell".into()],
        kind: ContainerKind::Service,
    }
}

/// Linhas aninhadas no deck: deps do compose (postgres, redis, localstack).
fn monolito_sidecar_rows(running: &HashMap<String, RunningPodRow>) -> Vec<ContainerInfo> {
    let specs: [(&str, &str); 3] = [
        ("vennon-dk-monolito-postgres", "  ├ postgres"),
        ("vennon-dk-monolito-redis", "  ├ monolito-redis"),
        ("vennon-dk-monolito-localstack", "  └ localstack"),
    ];
    let mut out = Vec::with_capacity(3);
    for (podman_name, label) in specs {
        let (status, is_up, cpu, mem) = running
            .get(podman_name)
            .cloned()
            .unwrap_or_else(|| ("stopped".into(), false, String::new(), String::new()));
        out.push(ContainerInfo {
            name: podman_name.to_string(),
            display_name: label.to_string(),
            status,
            is_up,
            cpu,
            mem,
            env: String::new(),
            debug: String::new(),
            vertical: String::new(),
            last_log: String::new(),
            enums: vec![],
            has_debug: false,
            commands: vec![],
            kind: ContainerKind::Sidecar,
        });
    }
    out
}

/// One IDE row: any Podman name `vennon-{ide}` or `vennon-{ide}-<slug>` (yaa instance).
fn ide_row(ide: &str, running: &HashMap<String, RunningPodRow>) -> ContainerInfo {
    let exact = format!("vennon-{ide}");
    let prefix = format!("vennon-{ide}-");

    let mut matches: Vec<&String> = running
        .keys()
        .filter(|k| *k == &exact || k.starts_with(&prefix))
        .collect();
    matches.sort();

    let mut chosen: Option<(&String, &RunningPodRow)> = None;
    for k in &matches {
        if let Some(entry) = running.get(*k) {
            if entry.1 {
                chosen = Some((*k, entry));
                break;
            }
        }
    }
    if chosen.is_none() {
        for k in &matches {
            if let Some(entry) = running.get(*k) {
                chosen = Some((*k, entry));
                break;
            }
        }
    }

    if let Some((k, e)) = chosen {
        ContainerInfo {
            name: (*k).clone(),
            display_name: ide.to_string(),
            status: e.0.clone(),
            is_up: e.1,
            cpu: e.2.clone(),
            mem: e.3.clone(),
            env: String::new(),
            debug: String::new(),
            vertical: String::new(),
            last_log: String::new(),
            enums: vec![],
            has_debug: false,
            commands: vec![],
            kind: ContainerKind::Ide,
        }
    } else {
        ContainerInfo {
            name: exact.clone(),
            display_name: ide.to_string(),
            status: "stopped".into(),
            is_up: false,
            cpu: String::new(),
            mem: String::new(),
            env: String::new(),
            debug: String::new(),
            vertical: String::new(),
            last_log: String::new(),
            enums: vec![],
            has_debug: false,
            commands: vec![],
            kind: ContainerKind::Ide,
        }
    }
}

/// Get running containers from podman.
fn collect_running() -> (HashMap<String, RunningPodRow>, bool) {
    let mut map = HashMap::new();
    let mut timed_out = false;

    let mut cmd = Command::new("podman");
    cmd.args([
        "ps",
        "-a",
        "--format",
        "{{.Names}}\t{{.Status}}",
        "--filter",
        "name=vennon",
    ]);
    match output_with_timeout(cmd, CMD_TIMEOUT) {
        Ok(output) => {
            for line in String::from_utf8_lossy(&output.stdout).lines() {
                let parts: Vec<&str> = line.split('\t').collect();
                if parts.len() >= 2 {
                    let is_up = parts[1].starts_with("Up");
                    map.insert(
                        parts[0].to_string(),
                        (parts[1].to_string(), is_up, String::new(), String::new()),
                    );
                }
            }
        }
        Err(e) if e.kind() == io::ErrorKind::TimedOut => {
            timed_out = true;
        }
        Err(_) => {}
    }

    let mut cmd = Command::new("podman");
    cmd.args([
        "stats",
        "--no-stream",
        "--format",
        "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}",
    ]);
    match output_with_timeout(cmd, CMD_TIMEOUT) {
        Ok(output) => {
            for line in String::from_utf8_lossy(&output.stdout).lines() {
                let parts: Vec<&str> = line.split('\t').collect();
                if parts.len() >= 3 {
                    if let Some(entry) = map.get_mut(parts[0]) {
                        entry.2 = parts[1].to_string();
                        entry.3 = parts[2].to_string();
                    }
                }
            }
        }
        Err(e) if e.kind() == io::ErrorKind::TimedOut => {
            timed_out = true;
        }
        Err(_) => {}
    }

    (map, timed_out)
}

/// Fetch APP_ENV / DEBUG / VERTICAL env vars for running containers via podman inspect.
/// Returns map: container_name → (env_short, debug_val, vertical_short).
fn collect_container_envs(names: &[String]) -> HashMap<String, (String, String, String)> {
    let mut map = HashMap::new();
    if names.is_empty() {
        return map;
    }

    let mut cmd = Command::new("podman");
    cmd.arg("inspect");
    cmd.arg("--format");
    cmd.arg("{{.Name}}\t{{range .Config.Env}}{{.}}||{{end}}");
    for name in names {
        cmd.arg(name);
    }

    if let Ok(output) = output_with_timeout(cmd, CMD_TIMEOUT) {
        for line in String::from_utf8_lossy(&output.stdout).lines() {
            let parts: Vec<&str> = line.splitn(2, '\t').collect();
            if parts.len() != 2 {
                continue;
            }
            let cname = parts[0].to_string();
            let mut app_env = String::new();
            let mut debug_val = String::new();
            let mut vertical_val = String::new();

            for kv in parts[1].split("||") {
                let kv = kv.trim();
                if kv.is_empty() {
                    continue;
                }
                if let Some((k, v)) = kv.split_once('=') {
                    match k {
                        "APP_ENV" | "ENVIRONMENT" | "NODE_ENV" | "GO_ENV" | "RAILS_ENV" => {
                            if app_env.is_empty() {
                                app_env = shorten_env(v);
                            }
                        }
                        "DEBUG" | "APP_DEBUG" => {
                            if debug_val.is_empty() {
                                debug_val = if v == "true" || v == "1" || v == "yes" {
                                    "on".into()
                                } else {
                                    "off".into()
                                };
                            }
                        }
                        "LOG_LEVEL" => {
                            if debug_val.is_empty() && (v == "debug" || v == "trace") {
                                debug_val = "dbg".into();
                            }
                        }
                        "VERTICAL" | "APP_VERTICAL" | "NUXT_VERTICAL" => {
                            if vertical_val.is_empty() {
                                vertical_val = shorten_vertical(v);
                            }
                        }
                        _ => {}
                    }
                }
            }

            map.insert(cname, (app_env, debug_val, vertical_val));
        }
    }

    map
}

/// Spawn a command silently (stdout/stderr → log file) so it doesn't corrupt the TUI.
/// Logs go to /tmp/deck-action.log for debugging.
fn spawn_silent(cmd: &str, args: &[String]) {
    let log_path = "/tmp/deck-action.log";
    let log_file = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_path);

    match log_file {
        Ok(mut f) => {
            use std::io::Write;
            let _ = writeln!(f, "\n--- {} {} ---", cmd, args.join(" "));
            let stderr_file = std::fs::OpenOptions::new()
                .create(true)
                .append(true)
                .open(log_path)
                .unwrap();
            let _ = Command::new(cmd)
                .args(args)
                .stdout(Stdio::null())
                .stderr(Stdio::from(stderr_file))
                .spawn();
        }
        Err(_) => {
            let _ = Command::new(cmd)
                .args(args)
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn();
        }
    }
}

/// True for menu items that aren't actionable (headers, separators).
fn is_menu_separator(s: &str) -> bool {
    s == "---" || s.starts_with("# ")
}

/// Shorten a param value for display, dispatching to the right shortener.
fn shorten_param(enum_name: &str, v: &str) -> String {
    match enum_name {
        "env" => shorten_env(v),
        "vertical" => shorten_vertical(v),
        _ => v.to_string(),
    }
}

fn shorten_vertical(v: &str) -> String {
    match v.to_lowercase().as_str() {
        "medicina" => "med".into(),
        "oab" => "oab".into(),
        "concursos" => "conc".into(),
        "vestibulares" => "vest".into(),
        "militares" => "mil".into(),
        "carreiras-juridicas" => "cjur".into(),
        other => other.chars().take(4).collect(),
    }
}

fn shorten_env(v: &str) -> String {
    // Values come raw from APP_ENV (vennon enum values: local, sand, devbox, qa, prod)
    match v.to_lowercase().as_str() {
        "production" | "prod" => "prod".into(),
        "sandbox" => "sand".into(), // normalise if ever written as "sandbox"
        "devbox" => "dbox".into(),
        other => other.chars().take(5).collect(),
    }
}

/// Result of parsing a service manifest (vennon.yaml).
struct ManifestData {
    commands: Vec<String>,
    /// All enums from the manifest (name, values, default).
    enums: Vec<EnumGroup>,
    has_debug: bool,
}

impl ManifestData {
    fn enum_default(&self, name: &str) -> &str {
        self.enums
            .iter()
            .find(|e| e.name == name)
            .map(|e| e.default.as_str())
            .unwrap_or("")
    }
}

/// Parse vennon.yaml and return manifest data including all enums.
fn get_manifest_data(name: &str) -> ManifestData {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let candidates = [
        format!("{home}/.config/vennon/containers/{name}/vennon.yaml"),
        format!("{home}/nixos/stow/.config/vennon/containers/{name}/vennon.yaml"),
    ];

    for path in &candidates {
        if let Ok(contents) = std::fs::read_to_string(path) {
            let commands = parse_yaml_commands(&contents);
            let enums = parse_yaml_all_enums(&contents);
            let has_debug = parse_yaml_serve_has_bool_arg(&contents, "debug");
            if !commands.is_empty() {
                return ManifestData {
                    commands,
                    enums,
                    has_debug,
                };
            }
        }
    }

    ManifestData {
        commands: vec![
            "serve".into(),
            "stop".into(),
            "logs".into(),
            "shell".into(),
            "flush".into(),
        ],
        enums: vec![],
        has_debug: false,
    }
}

fn parse_yaml_commands(contents: &str) -> Vec<String> {
    let mut commands = vec![];
    let mut in_commands = false;
    for line in contents.lines() {
        if line.starts_with("commands:") {
            in_commands = true;
            continue;
        }
        if in_commands {
            if !line.starts_with(' ') && !line.is_empty() {
                break;
            }
            // Only 2-space indent = direct child of commands: (not sub-keys like args:, compose:, etc.)
            if line.starts_with("  ") && !line.starts_with("   ") {
                let trimmed = line.trim();
                if trimmed.ends_with(':') && !trimmed.starts_with('-') && !trimmed.contains(' ') {
                    commands.push(trimmed.trim_end_matches(':').to_string());
                }
            }
        }
    }
    commands
}

/// Parse all enums from `enums:` block in vennon.yaml.
/// Returns a list of (name, values, default) for each enum found.
fn parse_yaml_all_enums(contents: &str) -> Vec<EnumGroup> {
    let mut enums = vec![];
    let mut in_enums = false;
    let mut current_name = String::new();
    let mut current_values = vec![];
    let mut current_default = String::new();

    for line in contents.lines() {
        if line.starts_with("enums:") {
            in_enums = true;
            continue;
        }
        if !in_enums {
            continue;
        }
        // Exit enums block
        if !line.starts_with(' ') && !line.is_empty() {
            break;
        }
        let trimmed = line.trim();
        // New enum at 2-space indent: "  env:", "  vertical:"
        if line.starts_with("  ")
            && !line.starts_with("   ")
            && trimmed.ends_with(':')
            && !trimmed.starts_with('#')
        {
            // Save previous enum if any
            if !current_name.is_empty() && !current_values.is_empty() {
                enums.push(EnumGroup {
                    name: current_name.clone(),
                    values: current_values.clone(),
                    default: current_default.clone(),
                });
            }
            current_name = trimmed.trim_end_matches(':').to_string();
            current_values.clear();
            current_default.clear();
            continue;
        }
        // Inside an enum: look for values: and default:
        if !current_name.is_empty() {
            if let Some(rest) = trimmed.strip_prefix("values:") {
                let inner = rest.trim().trim_start_matches('[').trim_end_matches(']');
                current_values = inner
                    .split(',')
                    .map(|v| v.trim().to_string())
                    .filter(|v| !v.is_empty())
                    .collect();
            } else if let Some(rest) = trimmed.strip_prefix("default:") {
                current_default = rest.trim().to_string();
            }
        }
    }
    // Save last enum
    if !current_name.is_empty() && !current_values.is_empty() {
        enums.push(EnumGroup {
            name: current_name,
            values: current_values,
            default: current_default,
        });
    }
    enums
}

/// Check if the `serve` command has a bool arg with the given name.
fn parse_yaml_serve_has_bool_arg(contents: &str, arg_name: &str) -> bool {
    let mut in_commands = false;
    let mut in_serve = false;
    let mut in_args = false;
    let mut found_name = false;

    for line in contents.lines() {
        if line.starts_with("commands:") {
            in_commands = true;
            continue;
        }
        if !in_commands {
            continue;
        }
        if !line.starts_with(' ') && !line.is_empty() {
            break;
        }

        let trimmed = line.trim();
        if trimmed == "serve:" {
            in_serve = true;
            in_args = false;
            continue;
        }
        // Another top-level command
        if line.starts_with("  ") && !line.starts_with("   ") && trimmed.ends_with(':') {
            in_serve = false;
            in_args = false;
            found_name = false;
        }
        if !in_serve {
            continue;
        }

        if trimmed == "args:" {
            in_args = true;
            continue;
        }
        if in_args {
            if trimmed == format!("- name: {arg_name}") || trimmed == format!("name: {arg_name}") {
                found_name = true;
            }
            if found_name && (trimmed == "type: bool" || trimmed.contains("type: bool")) {
                return true;
            }
            // Reset on next arg
            if trimmed.starts_with("- name:") && !trimmed.contains(arg_name) {
                found_name = false;
            }
        }
    }
    false
}

/// Podman container name for a service row in the Services tab.
/// Prefer explicit `container_name:` from docker-compose (e.g. reverseproxy → vennon-reverseproxy),
/// else fall back to vennon-dk-{name} / vennon-dk-{name}-app / vennon-{name} if present in `running`.
fn resolve_service_podman_name(
    service_name: &str,
    running: &HashMap<String, RunningPodRow>,
) -> String {
    if let Some(cn) = first_literal_container_name(service_name) {
        return cn;
    }
    let app = format!("vennon-dk-{service_name}-app");
    let base = format!("vennon-dk-{service_name}");
    let short = format!("vennon-{service_name}");
    if running.contains_key(&app) {
        return app;
    }
    if running.contains_key(&base) {
        return base;
    }
    if running.contains_key(&short) {
        return short;
    }
    app
}

fn service_compose_paths(service_name: &str) -> Vec<PathBuf> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    vec![
        PathBuf::from(format!(
            "{home}/.config/vennon/containers/{service_name}/docker-compose.yml"
        )),
        PathBuf::from(format!(
            "{home}/nixos/stow/.config/vennon/containers/{service_name}/docker-compose.yml"
        )),
    ]
}

/// First literal `container_name:` (no `${...}`) in the service compose file.
fn first_literal_container_name(service_name: &str) -> Option<String> {
    for path in service_compose_paths(service_name) {
        if let Some(cn) = scan_compose_container_name(&path) {
            return Some(cn);
        }
    }
    None
}

fn scan_compose_container_name(path: &Path) -> Option<String> {
    let s = std::fs::read_to_string(path).ok()?;
    for line in s.lines() {
        let t = line.trim();
        if let Some(rest) = t.strip_prefix("container_name:") {
            let v = rest.trim().trim_matches('"').trim_matches('\'');
            if v.is_empty() || v.contains("${") {
                continue;
            }
            return Some(v.to_string());
        }
    }
    None
}

fn strip_ansi(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    let mut chars = s.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' && chars.peek() == Some(&'[') {
            chars.next();
            for nc in chars.by_ref() {
                if nc.is_ascii_alphabetic() {
                    break;
                }
            }
        } else {
            out.push(c);
        }
    }
    out
}

/// Returns (status_label, is_up) for a systemd user unit.
fn systemctl_status(unit: &str) -> (String, bool) {
    let output = Command::new("systemctl")
        .args(["--user", "is-active", unit])
        .output();
    match output {
        Ok(o) => {
            let s = String::from_utf8_lossy(&o.stdout).trim().to_string();
            let up = s == "active";
            (s, up)
        }
        Err(_) => ("unknown".into(), false),
    }
}

fn systemd_service_rows() -> Vec<ContainerInfo> {
    let specs = [("buzz.service", "buzz"), ("yaa-tick.timer", "tick")];
    specs
        .iter()
        .map(|(unit, label)| {
            let (status, is_up) = systemctl_status(unit);
            ContainerInfo {
                name: unit.to_string(),
                display_name: label.to_string(),
                status,
                is_up,
                cpu: String::new(),
                mem: String::new(),
                env: String::new(),
                debug: String::new(),
                vertical: String::new(),
                last_log: String::new(),
                enums: vec![],
                has_debug: false,
                commands: vec![],
                kind: ContainerKind::SystemdService,
            }
        })
        .collect()
}

fn collect_logs_for(container_name: &str) -> (Vec<String>, bool) {
    let mut logs = vec![];
    const LOG_TIMEOUT: Duration = Duration::from_secs(8);
    let mut cmd = Command::new("podman");
    cmd.args(["logs", "--tail", "300", container_name]);
    match output_with_timeout(cmd, LOG_TIMEOUT) {
        Ok(output) => {
            let text = String::from_utf8_lossy(&output.stdout);
            let stderr = String::from_utf8_lossy(&output.stderr);
            for line in text.lines().chain(stderr.lines()) {
                let clean = strip_ansi(line);
                if !clean.trim().is_empty() && !clean.contains("buildando...") {
                    logs.push(clean);
                }
            }
            (logs, false)
        }
        Err(e) if e.kind() == io::ErrorKind::TimedOut => (
            vec![format!("(podman logs timeout: {container_name})")],
            true,
        ),
        Err(_) => (logs, false),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ide_row_picks_running_container() {
        let mut running = HashMap::new();
        running.insert(
            "vennon-claude".into(),
            ("Up 2 hours".into(), true, "1%".into(), "512MiB".into()),
        );
        let info = ide_row("claude", &running);
        assert_eq!(info.name, "vennon-claude");
        assert!(info.is_up);
        assert_eq!(info.display_name, "claude");
    }

    #[test]
    fn ide_row_stopped_when_empty() {
        let running = HashMap::new();
        let info = ide_row("cursor", &running);
        assert_eq!(info.name, "vennon-cursor");
        assert!(!info.is_up);
    }
}
