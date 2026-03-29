use crate::process::{output_with_timeout, CMD_TIMEOUT};
use anyhow::Result;
use std::collections::HashMap;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::mpsc::{self, Receiver, TryRecvError};
use std::time::Duration;

pub const IDE_NAMES: &[&str] = &["claude", "opencode", "cursor"];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ContainerKind {
    Ide,
    Service,
    /// Postgres/Redis/Localstack do stack monolito — só logs no painel, sem menu vennon.
    Sidecar,
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
    /// Valid values for --env arg (from vennon.yaml enums.env.values).
    pub env_values: Vec<String>,
    /// Valid values for --vertical arg (from vennon.yaml enums.vertical.values).
    pub vertical_values: Vec<String>,
    /// Whether the serve command has a --debug bool arg.
    pub has_debug: bool,
    pub commands: Vec<String>,
    pub kind: ContainerKind,
}

#[derive(Clone, Copy, PartialEq)]
pub enum Tab {
    Ide,
    Services,
}

pub enum AppMode {
    Normal,
    Menu,
}

pub struct App {
    pub mode: AppMode,
    pub tab: Tab,
    pub all_containers: Vec<ContainerInfo>,
    pub cursor: usize,
    pub menu_cursor: usize,
    pub logs: Vec<String>,
    pub log_scroll: usize,
    /// True while a background `RefreshSnapshot::collect` is in flight.
    pub refresh_inflight: bool,
    /// True if the last completed refresh hit a subprocess timeout (podman/vennon).
    pub subprocess_degraded: bool,
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
            tab: Tab::Ide,
            all_containers: vec![],
            cursor: 0,
            menu_cursor: 0,
            logs: vec![],
            log_scroll: 0,
            refresh_inflight: false,
            subprocess_degraded: false,
            pending_refresh: None,
        }
    }

    pub fn visible_containers(&self) -> Vec<&ContainerInfo> {
        Self::visible_containers_slice(&self.all_containers, self.tab)
    }

    fn visible_containers_slice(all: &[ContainerInfo], tab: Tab) -> Vec<&ContainerInfo> {
        all.iter()
            .filter(|c| {
                let is_ide = c.kind == ContainerKind::Ide;
                match tab {
                    Tab::Ide => is_ide,
                    Tab::Services => !is_ide,
                }
            })
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
        self.log_scroll = snap.log_scroll;
        self.subprocess_degraded = snap.had_subprocess_timeout;
        self.refresh_inflight = false;
        self.pending_refresh = None;
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
        self.log_scroll = scroll;
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
            Tab::Ide => Tab::Services,
            Tab::Services => Tab::Ide,
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
        if actions.get(next).map(|a| a.as_str()) == Some("---") {
            next = (next + 1) % actions.len();
        }
        self.menu_cursor = next;
    }

    pub fn menu_prev(&mut self) {
        let actions = self.menu_actions();
        if actions.is_empty() {
            return;
        }
        let mut prev = self.menu_cursor.checked_sub(1).unwrap_or(actions.len() - 1);
        if actions.get(prev).map(|a| a.as_str()) == Some("---") {
            prev = prev.checked_sub(1).unwrap_or(actions.len() - 1);
        }
        self.menu_cursor = prev;
    }

    /// Get menu actions for the selected container.
    pub fn menu_actions(&self) -> Vec<String> {
        if let Some(c) = self.selected_container() {
            match c.kind {
                ContainerKind::Sidecar => vec![],
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
                    let has_params = !c.env_values.is_empty()
                        || c.has_debug
                        || !c.vertical_values.is_empty();
                    if has_params {
                        actions.push("---".into());
                    }
                    for v in &c.env_values {
                        let mark = if shorten_env(v) == c.env { " ✓" } else { "" };
                        actions.push(format!("env:{v}{mark}"));
                    }
                    if c.has_debug {
                        let on_mark = if c.debug == "on" { " ✓" } else { "" };
                        let off_mark = if c.debug == "off" || c.debug.is_empty() { " ✓" } else { "" };
                        actions.push(format!("debug:on{on_mark}"));
                        actions.push(format!("debug:off{off_mark}"));
                    }
                    if !c.vertical_values.is_empty() {
                        for v in &c.vertical_values {
                            let mark = if shorten_vertical(v) == c.vertical { " ✓" } else { "" };
                            actions.push(format!("vert:{v}{mark}"));
                        }
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
        self.log_scroll = self.log_scroll.saturating_sub(5);
    }

    pub fn scroll_logs_down(&mut self) {
        let max = self.logs.len().saturating_sub(10);
        self.log_scroll = (self.log_scroll + 5).min(max);
    }

    pub fn exec_action(&self, action: &str) -> Result<()> {
        if action == "---" {
            return Ok(());
        }
        let action = action.trim_end_matches(" ✓");
        let container = match self.selected_container() {
            Some(c) => c,
            None => return Ok(()),
        };

        if let Some(env_val) = action.strip_prefix("env:") {
            let mut args = vec![container.display_name.clone(), "serve".into(),
                                format!("--env={env_val}")];
            if !container.vertical.is_empty() && !container.vertical_values.is_empty() {
                args.push(format!("--vertical={}", container.vertical));
            }
            if container.debug == "on" && container.has_debug {
                args.push("--debug=true".into());
            }
            let _ = Command::new("vennon").args(&args).status();
            return Ok(());
        }

        if let Some(vert_val) = action.strip_prefix("vert:") {
            let mut args = vec![container.display_name.clone(), "serve".into(),
                                format!("--vertical={vert_val}")];
            if !container.env.is_empty() && !container.env_values.is_empty() {
                args.push(format!("--env={}", container.env));
            }
            if container.debug == "on" && container.has_debug {
                args.push("--debug=true".into());
            }
            let _ = Command::new("vennon").args(&args).status();
            return Ok(());
        }

        if let Some(dbg_val) = action.strip_prefix("debug:") {
            let flag = if dbg_val == "on" { "--debug=true" } else { "--debug=false" };
            let mut args = vec![container.display_name.clone(), "serve".into(),
                                flag.into()];
            if !container.env.is_empty() && !container.env_values.is_empty() {
                args.push(format!("--env={}", container.env));
            }
            if !container.vertical.is_empty() && !container.vertical_values.is_empty() {
                args.push(format!("--vertical={}", container.vertical));
            }
            let _ = Command::new("vennon").args(&args).status();
            return Ok(());
        }

        let _ = Command::new("vennon")
            .args([&container.display_name, action])
            .status();
        Ok(())
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
            (
                vec![format!("{} — not running", c.display_name)],
                false,
                0,
            )
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
            let env_default = if manifest.env_default.is_empty() {
                String::new()
            } else {
                shorten_env(&manifest.env_default)
            };
            let vert_default = if manifest.vertical_default.is_empty() {
                String::new()
            } else {
                shorten_vertical(&manifest.vertical_default)
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
                env_values: manifest.env_values,
                vertical_values: manifest.vertical_values,
                has_debug: manifest.has_debug,
                commands: manifest.commands,
                kind: ContainerKind::Service,
            });

            if name == "monolito" {
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

    (containers, any_timeout)
}

/// Linhas aninhadas no deck: deps do compose (postgres, redis, localstack).
fn monolito_sidecar_rows(
    running: &HashMap<String, (String, bool, String, String)>,
) -> Vec<ContainerInfo> {
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
            env_values: vec![],
            vertical_values: vec![],
            has_debug: false,
            commands: vec![],
            kind: ContainerKind::Sidecar,
        });
    }
    out
}

/// One IDE row: any Podman name `vennon-{ide}` or `vennon-{ide}-<slug>` (yaa instance).
fn ide_row(ide: &str, running: &HashMap<String, (String, bool, String, String)>) -> ContainerInfo {
    let exact = format!("vennon-{ide}");
    let prefix = format!("vennon-{ide}-");

    let mut matches: Vec<&String> = running
        .keys()
        .filter(|k| *k == &exact || k.starts_with(&prefix))
        .collect();
    matches.sort();

    let mut chosen: Option<(&String, &(String, bool, String, String))> = None;
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
            env_values: vec![],
            vertical_values: vec![],
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
            env_values: vec![],
            vertical_values: vec![],
            has_debug: false,
            commands: vec![],
            kind: ContainerKind::Ide,
        }
    }
}

/// Get running containers from podman.
fn collect_running() -> (HashMap<String, (String, bool, String, String)>, bool) {
    let mut map = HashMap::new();
    let mut timed_out = false;

    let mut cmd = Command::new("podman");
    cmd.args(["ps", "-a", "--format", "{{.Names}}\t{{.Status}}", "--filter", "name=vennon"]);
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
    cmd.args(["stats", "--no-stream", "--format", "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"]);
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

fn shorten_vertical(v: &str) -> String {
    match v.to_lowercase().as_str() {
        "medicina"              => "med".into(),
        "oab"                   => "oab".into(),
        "concursos"             => "conc".into(),
        "vestibulares"          => "vest".into(),
        "militares"             => "mil".into(),
        "carreiras-juridicas"   => "cjur".into(),
        other                   => other.chars().take(4).collect(),
    }
}

fn shorten_env(v: &str) -> String {
    // Values come raw from APP_ENV (vennon enum values: local, sand, devbox, qa, prod)
    match v.to_lowercase().as_str() {
        "production" | "prod" => "prod".into(),
        "sandbox"             => "sand".into(), // normalise if ever written as "sandbox"
        "devbox"              => "dbox".into(),
        other                 => other.chars().take(5).collect(),
    }
}

/// Result of parsing a service manifest (vennon.yaml).
struct ManifestData {
    commands: Vec<String>,
    env_values: Vec<String>,
    vertical_values: Vec<String>,
    has_debug: bool,
    env_default: String,
    vertical_default: String,
}

/// Parse vennon.yaml and return manifest data including enum defaults.
fn get_manifest_data(name: &str) -> ManifestData {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let candidates = [
        format!("{home}/.config/vennon/containers/{name}/vennon.yaml"),
        format!("{home}/nixos/stow/.config/vennon/containers/{name}/vennon.yaml"),
    ];

    for path in &candidates {
        if let Ok(contents) = std::fs::read_to_string(path) {
            let commands = parse_yaml_commands(&contents);
            let env_values = parse_yaml_enum_values(&contents, "env");
            let vertical_values = parse_yaml_enum_values(&contents, "vertical");
            let has_debug = parse_yaml_serve_has_bool_arg(&contents, "debug");
            let env_default = parse_yaml_enum_default(&contents, "env").unwrap_or_default();
            let vertical_default = parse_yaml_enum_default(&contents, "vertical").unwrap_or_default();
            if !commands.is_empty() {
                return ManifestData {
                    commands,
                    env_values,
                    vertical_values,
                    has_debug,
                    env_default,
                    vertical_default,
                };
            }
        }
    }

    ManifestData {
        commands: vec!["serve".into(), "stop".into(), "logs".into(), "shell".into(), "flush".into()],
        env_values: vec![],
        vertical_values: vec![],
        has_debug: false,
        env_default: String::new(),
        vertical_default: String::new(),
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

/// Extract `values:` list for a given enum name in the yaml.
fn parse_yaml_enum_values(contents: &str, enum_name: &str) -> Vec<String> {
    // Look for "  <enum_name>:" under "enums:", then collect "values: [...]"
    let mut in_enums = false;
    let mut in_target_enum = false;
    let mut values = vec![];

    for line in contents.lines() {
        if line.starts_with("enums:") {
            in_enums = true;
            continue;
        }
        if in_enums {
            // Top-level exit
            if !line.starts_with(' ') && !line.is_empty() {
                break;
            }
            // "  env:" or "  vertical:"
            let trimmed = line.trim();
            if trimmed == format!("{enum_name}:") {
                in_target_enum = true;
                continue;
            }
            // Another enum at same indent level resets
            if line.starts_with("  ") && !line.starts_with("   ") && trimmed.ends_with(':') {
                in_target_enum = false;
            }
            if in_target_enum {
                if let Some(rest) = trimmed.strip_prefix("values:") {
                    // Inline array: values: [local, sand, prod]
                    let inner = rest.trim().trim_start_matches('[').trim_end_matches(']');
                    values = inner.split(',').map(|v| v.trim().to_string())
                        .filter(|v| !v.is_empty()).collect();
                    return values;
                }
            }
        }
    }
    values
}

/// Extract `default:` value for a given enum name under `enums:`.
fn parse_yaml_enum_default(contents: &str, enum_name: &str) -> Option<String> {
    let mut in_enums = false;
    let mut in_target_enum = false;

    for line in contents.lines() {
        if line.starts_with("enums:") {
            in_enums = true;
            continue;
        }
        if in_enums {
            if !line.starts_with(' ') && !line.is_empty() {
                break;
            }
            let trimmed = line.trim();
            if trimmed == format!("{enum_name}:") {
                in_target_enum = true;
                continue;
            }
            // Another enum at same indent level resets
            if line.starts_with("  ") && !line.starts_with("   ") && trimmed.ends_with(':') {
                in_target_enum = false;
            }
            if in_target_enum {
                if let Some(rest) = trimmed.strip_prefix("default:") {
                    let val = rest.trim().to_string();
                    if !val.is_empty() {
                        return Some(val);
                    }
                }
            }
        }
    }
    None
}

/// Check if the `serve` command has a bool arg with the given name.
fn parse_yaml_serve_has_bool_arg(contents: &str, arg_name: &str) -> bool {
    let mut in_commands = false;
    let mut in_serve = false;
    let mut in_args = false;
    let mut found_name = false;

    for line in contents.lines() {
        if line.starts_with("commands:") { in_commands = true; continue; }
        if !in_commands { continue; }
        if !line.starts_with(' ') && !line.is_empty() { break; }

        let trimmed = line.trim();
        if trimmed == "serve:" { in_serve = true; in_args = false; continue; }
        // Another top-level command
        if line.starts_with("  ") && !line.starts_with("   ") && trimmed.ends_with(':') {
            in_serve = false; in_args = false; found_name = false;
        }
        if !in_serve { continue; }

        if trimmed == "args:" { in_args = true; continue; }
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
fn resolve_service_podman_name(service_name: &str, running: &HashMap<String, (String, bool, String, String)>) -> String {
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
                if nc.is_ascii_alphabetic() { break; }
            }
        } else {
            out.push(c);
        }
    }
    out
}

fn collect_logs_for(container_name: &str) -> (Vec<String>, bool) {
    let mut logs = vec![];
    const LOG_TIMEOUT: Duration = Duration::from_secs(8);
    let mut cmd = Command::new("podman");
    cmd.args(["logs", "--tail", "100", container_name]);
    match output_with_timeout(cmd, LOG_TIMEOUT) {
        Ok(output) => {
            let text = String::from_utf8_lossy(&output.stdout);
            let stderr = String::from_utf8_lossy(&output.stderr);
            for line in text.lines().chain(stderr.lines()) {
                let clean = strip_ansi(line);
                if !clean.trim().is_empty() {
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
