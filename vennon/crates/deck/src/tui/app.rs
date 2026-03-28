use anyhow::Result;
use std::process::Command;

#[derive(Debug, Clone)]
pub struct ContainerInfo {
    pub name: String,
    pub image: String,
    pub status: String,
    pub is_up: bool,
    pub cpu: String,
    pub mem: String,
}

pub enum AppMode {
    Normal,
    Menu,
}

pub struct App {
    pub mode: AppMode,
    pub containers: Vec<ContainerInfo>,
    pub cursor: usize,
    pub menu_cursor: usize,
    pub logs: Vec<String>,
    pub log_scroll: usize,
    pub status_line: String,
}

const MENU_ACTIONS: &[(&str, &str)] = &[
    ("start", "Start"),
    ("stop", "Stop"),
    ("shell", "Shell"),
    ("build", "Build"),
    ("flush", "Flush"),
];

impl App {
    pub fn new() -> Self {
        Self {
            mode: AppMode::Normal,
            containers: vec![],
            cursor: 0,
            menu_cursor: 0,
            logs: vec![],
            log_scroll: 0,
            status_line: String::new(),
        }
    }

    pub fn refresh(&mut self) -> Result<()> {
        self.containers = collect_containers();
        self.refresh_logs();
        if self.cursor >= self.containers.len() && !self.containers.is_empty() {
            self.cursor = self.containers.len() - 1;
        }
        Ok(())
    }

    /// Refresh logs for the selected container only.
    fn refresh_logs(&mut self) {
        if let Some(c) = self.containers.get(self.cursor) {
            self.logs = collect_logs_for(&c.name);
        } else {
            self.logs.clear();
        }
        // Auto-scroll to bottom
        self.log_scroll = self.logs.len().saturating_sub(20);
    }

    pub fn next(&mut self) {
        if !self.containers.is_empty() {
            self.cursor = (self.cursor + 1) % self.containers.len();
            self.refresh_logs();
        }
    }

    pub fn prev(&mut self) {
        if !self.containers.is_empty() {
            self.cursor = self.cursor.checked_sub(1).unwrap_or(self.containers.len() - 1);
            self.refresh_logs();
        }
    }

    pub fn open_menu(&mut self) {
        if !self.containers.is_empty() {
            self.mode = AppMode::Menu;
            self.menu_cursor = 0;
        }
    }

    pub fn close_menu(&mut self) {
        self.mode = AppMode::Normal;
    }

    pub fn menu_next(&mut self) {
        self.menu_cursor = (self.menu_cursor + 1) % MENU_ACTIONS.len();
    }

    pub fn menu_prev(&mut self) {
        self.menu_cursor = self.menu_cursor.checked_sub(1).unwrap_or(MENU_ACTIONS.len() - 1);
    }

    pub fn selected_action(&self) -> Option<String> {
        Some(MENU_ACTIONS[self.menu_cursor].0.to_string())
    }

    pub fn selected_container(&self) -> Option<&ContainerInfo> {
        self.containers.get(self.cursor)
    }

    pub fn scroll_logs_up(&mut self) {
        self.log_scroll = self.log_scroll.saturating_sub(5);
    }

    pub fn scroll_logs_down(&mut self) {
        let max = self.logs.len().saturating_sub(10);
        self.log_scroll = (self.log_scroll + 5).min(max);
    }

    /// Execute an action on the selected container.
    pub fn exec_action(&self, action: &str) -> Result<()> {
        let container = match self.selected_container() {
            Some(c) => c,
            None => return Ok(()),
        };

        // Derive vennon container name (strip "vennon-" prefix)
        let svc_name = container.name.strip_prefix("vennon-").unwrap_or(&container.name);

        match action {
            "shell" => {
                // Interactive — use yaa shell or vennon shell
                let _ = Command::new("vennon")
                    .args([svc_name, "shell"])
                    .status();
            }
            "start" => {
                let _ = Command::new("vennon")
                    .args([svc_name, "start"])
                    .status();
            }
            "stop" => {
                let _ = Command::new("vennon")
                    .args([svc_name, "stop"])
                    .status();
            }
            "build" => {
                let _ = Command::new("vennon")
                    .args([svc_name, "build"])
                    .status();
            }
            "flush" => {
                let _ = Command::new("vennon")
                    .args([svc_name, "flush"])
                    .status();
            }
            _ => {}
        }
        Ok(())
    }
}

// ── Data collection ─────────────────────────────────────────────

fn collect_containers() -> Vec<ContainerInfo> {
    let output = Command::new("podman")
        .args([
            "ps",
            "-a",
            "--format",
            "{{.Names}}\t{{.Image}}\t{{.Status}}",
            "--filter",
            "name=vennon-",
        ])
        .output();

    let output = match output {
        Ok(o) => o,
        Err(_) => return vec![],
    };

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut containers = vec![];

    for line in stdout.lines() {
        let parts: Vec<&str> = line.split('\t').collect();
        if parts.len() >= 3 {
            let name = parts[0].to_string();
            let image = parts[1].to_string();
            let status = parts[2].to_string();
            let is_up = status.starts_with("Up");
            containers.push(ContainerInfo {
                name,
                image,
                status,
                is_up,
                cpu: String::new(),
                mem: String::new(),
            });
        }
    }

    // Get stats for running containers
    if let Ok(stats) = Command::new("podman")
        .args([
            "stats",
            "--no-stream",
            "--format",
            "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}",
        ])
        .output()
    {
        let stats_out = String::from_utf8_lossy(&stats.stdout);
        for line in stats_out.lines() {
            let parts: Vec<&str> = line.split('\t').collect();
            if parts.len() >= 3 {
                if let Some(c) = containers.iter_mut().find(|c| c.name == parts[0]) {
                    c.cpu = parts[1].to_string();
                    c.mem = parts[2].to_string();
                }
            }
        }
    }

    containers
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
