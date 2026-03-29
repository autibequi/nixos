use anyhow::Result;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::process::Command;

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
        }
    }

    pub fn visible_containers(&self) -> Vec<&ContainerInfo> {
        self.all_containers
            .iter()
            .filter(|c| {
                let is_ide = c.kind == ContainerKind::Ide;
                match self.tab {
                    Tab::Ide => is_ide,
                    Tab::Services => !is_ide,
                }
            })
            .collect()
    }

    pub fn refresh(&mut self) -> Result<()> {
        self.all_containers = collect_all();
        let vis = self.visible_containers();
        if self.cursor >= vis.len() && !vis.is_empty() {
            self.cursor = vis.len() - 1;
        }
        self.refresh_logs();
        Ok(())
    }

    fn refresh_logs(&mut self) {
        let vis = self.visible_containers();
        if let Some(c) = vis.get(self.cursor) {
            if c.is_up {
                self.logs = collect_logs_for(&c.name);
            } else {
                self.logs = vec![format!("{} — not running", c.display_name)];
            }
        } else {
            self.logs.clear();
        }
        self.log_scroll = self.logs.len().saturating_sub(20);
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
        if !actions.is_empty() {
            self.menu_cursor = (self.menu_cursor + 1) % actions.len();
        }
    }

    pub fn menu_prev(&mut self) {
        let actions = self.menu_actions();
        if !actions.is_empty() {
            self.menu_cursor = self.menu_cursor.checked_sub(1).unwrap_or(actions.len() - 1);
        }
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
                ContainerKind::Service => c.commands.clone(),
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
        let container = match self.selected_container() {
            Some(c) => c,
            None => return Ok(()),
        };
        let _ = Command::new("vennon")
            .args([&container.display_name, action])
            .status();
        Ok(())
    }
}

// ── Data collection ─────────────────────────────────────────────

fn collect_all() -> Vec<ContainerInfo> {
    let mut containers = vec![];
    let running = collect_running();

    // 1. IDE containers — always show claude/opencode/cursor
    // yaa/vennon uses project vennon-{ide}-{VENNON_INSTANCE}, so match exact name or vennon-{ide}-* .
    for name in &["claude", "opencode", "cursor"] {
        let row = ide_row(name, &running);
        containers.push(row);
    }

    // 2. Service containers — discover from vennon list
    if let Ok(output) = Command::new("vennon").args(["list"]).output() {
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

            // Get commands from manifest
            let commands = get_manifest_commands(&name);

            containers.push(ContainerInfo {
                name: podman_name,
                display_name: name.clone(),
                status,
                is_up,
                cpu,
                mem,
                commands,
                kind: ContainerKind::Service,
            });

            if name == "monolito" {
                for sidecar in monolito_sidecar_rows(&running) {
                    containers.push(sidecar);
                }
            }
        }
    }

    containers
}

/// Linhas aninhadas no deck: deps do compose (postgres, redis, localstack).
fn monolito_sidecar_rows(
    running: &HashMap<String, (String, bool, String, String)>,
) -> Vec<ContainerInfo> {
    let specs: [(&str, &str); 3] = [
        ("vennon-dk-monolito-postgres", "  ├ postgres"),
        ("vennon-dk-monolito-redis", "  ├ redis"),
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
            commands: vec![],
            kind: ContainerKind::Ide,
        }
    }
}

/// Get running containers from podman.
fn collect_running() -> HashMap<String, (String, bool, String, String)> {
    let mut map = HashMap::new();

    if let Ok(output) = Command::new("podman")
        .args(["ps", "-a", "--format", "{{.Names}}\t{{.Status}}", "--filter", "name=vennon"])
        .output()
    {
        for line in String::from_utf8_lossy(&output.stdout).lines() {
            let parts: Vec<&str> = line.split('\t').collect();
            if parts.len() >= 2 {
                let is_up = parts[1].starts_with("Up");
                map.insert(parts[0].to_string(), (parts[1].to_string(), is_up, String::new(), String::new()));
            }
        }
    }

    // Stats for running
    if let Ok(output) = Command::new("podman")
        .args(["stats", "--no-stream", "--format", "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"])
        .output()
    {
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

    map
}

/// Get command names from a service's vennon.yaml manifest.
fn get_manifest_commands(name: &str) -> Vec<String> {
    // Try to find vennon.yaml in known locations
    let home = std::env::var("HOME").unwrap_or_else(|_| "/root".into());
    let candidates = [
        format!("{home}/.config/vennon/containers/{name}/vennon.yaml"),
        format!("{home}/nixos/vennon/containers/{name}/vennon.yaml"),
    ];

    for path in &candidates {
        if let Ok(contents) = std::fs::read_to_string(path) {
            let mut commands = vec![];
            let mut in_commands = false;
            for line in contents.lines() {
                if line.starts_with("commands:") {
                    in_commands = true;
                    continue;
                }
                if in_commands {
                    if !line.starts_with(' ') && !line.is_empty() {
                        break;  // left commands block
                    }
                    // Top-level command: "  serve:" (2 spaces + name + colon)
                    let trimmed = line.trim();
                    if trimmed.ends_with(':') && !trimmed.starts_with('-') && !trimmed.contains(' ') {
                        commands.push(trimmed.trim_end_matches(':').to_string());
                    }
                }
            }
            if !commands.is_empty() {
                return commands;
            }
        }
    }

    // Fallback
    vec!["serve".into(), "stop".into(), "logs".into(), "shell".into(), "flush".into()]
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

fn collect_logs_for(container_name: &str) -> Vec<String> {
    let mut logs = vec![];
    if let Ok(output) = Command::new("podman")
        .args(["logs", "--tail", "100", container_name])
        .output()
    {
        let text = String::from_utf8_lossy(&output.stdout);
        let stderr = String::from_utf8_lossy(&output.stderr);
        for line in text.lines().chain(stderr.lines()) {
            if !line.trim().is_empty() {
                logs.push(line.to_string());
            }
        }
    }
    logs
}
