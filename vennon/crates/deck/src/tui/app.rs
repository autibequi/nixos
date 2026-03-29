use anyhow::Result;
use std::collections::HashMap;
use std::process::Command;

pub const IDE_NAMES: &[&str] = &["claude", "opencode", "cursor"];

#[derive(Debug, Clone)]
pub struct ContainerInfo {
    pub name: String,
    pub display_name: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
    pub commands: Vec<String>,
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
                let is_ide = IDE_NAMES.contains(&c.display_name.as_str());
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
            if c.commands.is_empty() {
                // IDE default actions
                vec!["start", "stop", "shell", "build", "flush"]
                    .into_iter().map(|s| s.to_string()).collect()
            } else {
                c.commands.clone()
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
    for name in &["claude", "opencode", "cursor"] {
        let podman_name = format!("vennon-{name}");
        let (status, is_up, cpu, mem) = running
            .get(&podman_name)
            .cloned()
            .unwrap_or_else(|| ("stopped".into(), false, String::new(), String::new()));
        containers.push(ContainerInfo {
            name: podman_name,
            display_name: name.to_string(),
            status,
            is_up,
            cpu,
            mem,
            commands: vec![],  // IDE uses default actions
        });
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

            let podman_name = format!("vennon-dk-{name}");
            // Check both vennon-dk-NAME and vennon-dk-NAME-app patterns
            let (status, is_up, cpu, mem) = running
                .get(&podman_name)
                .or_else(|| running.get(&format!("{podman_name}-app")))
                .cloned()
                .unwrap_or_else(|| ("stopped".into(), false, String::new(), String::new()));

            // Get commands from manifest
            let commands = get_manifest_commands(&name);

            containers.push(ContainerInfo {
                name: if running.contains_key(&format!("{podman_name}-app")) {
                    format!("{podman_name}-app")
                } else {
                    podman_name
                },
                display_name: name,
                status,
                is_up,
                cpu,
                mem,
                commands,
            });
        }
    }

    containers
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
