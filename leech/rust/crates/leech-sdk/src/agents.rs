//! Agent system — types, loaders, and activity log parsing.

use serde::{Deserialize, Serialize};

use crate::paths;

// ── Types ─────────────────────────────────────────────────────────────────────

/// Static information about one configured agent, enriched with schedule data.
#[derive(Debug, Clone, Serialize, Deserialize)]
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

/// One entry from the activity log.
#[derive(Debug, Clone, Serialize, Deserialize)]
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

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extract a single field value from YAML frontmatter (--- ... ---).
pub fn frontmatter_field(content: &str, key: &str) -> Option<String> {
    let mut in_fm = false;
    for line in content.lines() {
        if line == "---" {
            if in_fm {
                break;
            }
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

fn parse_clock(s: &str) -> Option<u32> {
    s.trim().strip_prefix("every").and_then(|n| n.parse().ok())
}

/// Parse a task filename stem like `20260323_0056_hermes` or
/// `20260324_03_00_doings-auto` → (epoch_secs, agent_name).
pub fn parse_task_stem(stem: &str) -> Option<(u64, String)> {
    let parts: Vec<&str> = stem.splitn(4, '_').collect();
    if parts.len() < 3 {
        return None;
    }
    let date_str = parts[0];
    if date_str.len() != 8 {
        return None;
    }
    let year: u64 = date_str[..4].parse().ok()?;
    let month: u64 = date_str[4..6].parse().ok()?;
    let day: u64 = date_str[6..8].parse().ok()?;

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
    let (m_adj, y_adj) = if m > 2 {
        (m - 3, y - 1970)
    } else {
        (m + 9, y - 1971)
    };
    let days = 365 * y_adj
        + y_adj / 4
        - y_adj / 100
        + y_adj / 400
        + (153 * m_adj + 2) / 5
        + d
        - 1;
    days * 86400
}

/// Strip YYYYMMDD_HH_MM_ or YYYYMMDD_HHMM_ prefix from a card filename stem.
pub fn strip_date_prefix(raw: &str) -> String {
    let stem = raw.trim_end_matches(".md");
    let parts: Vec<&str> = stem.splitn(5, '_').collect();
    if parts.len() >= 3 && parts[0].len() == 8 {
        if parts[1].len() == 4 && parts[1].chars().all(|c| c.is_ascii_digit()) {
            return parts[2..].join("_");
        } else if parts.len() >= 4 {
            return parts[3..].join("_");
        }
    }
    stem.to_string()
}

// ── Loaders ───────────────────────────────────────────────────────────────────

/// Load all configured agents from `self/agents/*/agent.md`,
/// enriched with pending task counts and next-run timestamps.
pub fn load_all_agents() -> Vec<AgentInfo> {
    let candidates = [
        paths::leech_root()
            .parent()
            .map(|p| p.join("agents"))
            .unwrap_or_default(),
        std::path::PathBuf::from("/workspace/self/agents"),
        paths::home().join("nixos/leech/self/agents"),
    ];
    let Some(agents_base) = candidates.into_iter().find(|p| p.is_dir()) else {
        return Vec::new();
    };

    // Build map: agent_name → (earliest_task_ts, count)
    let mut task_map: std::collections::HashMap<String, (u64, usize)> =
        std::collections::HashMap::new();
    if let Some(tasks_dir) = paths::tasks_dir() {
        let queue = tasks_dir.join("AGENTS");
        if queue.is_dir() {
            for entry in std::fs::read_dir(&queue).into_iter().flatten().flatten() {
                let path = entry.path();
                if path.is_dir() {
                    continue;
                }
                if path.extension().and_then(|e| e.to_str()) != Some("md") {
                    continue;
                }
                let stem = path
                    .file_stem()
                    .map(|s| s.to_string_lossy().into_owned())
                    .unwrap_or_default();
                if let Some((ts, name)) = parse_task_stem(&stem) {
                    let e = task_map.entry(name).or_insert((u64::MAX, 0));
                    if ts < e.0 {
                        e.0 = ts;
                    }
                    e.1 += 1;
                }
            }
        }
    }

    let mut infos: Vec<AgentInfo> = std::fs::read_dir(&agents_base)
        .into_iter()
        .flatten()
        .flatten()
        .filter_map(|e| {
            let dir = e.path();
            if !dir.is_dir() {
                return None;
            }
            let name = dir.file_name()?.to_string_lossy().into_owned();
            if name.starts_with('_') {
                return None;
            }
            let card = dir.join("agent.md");
            let content = std::fs::read_to_string(&card).ok()?;
            let model = frontmatter_field(&content, "model").unwrap_or_else(|| "?".into());
            let clock_mins = frontmatter_field(&content, "clock")
                .as_deref()
                .and_then(parse_clock);
            let (next_task_ts, task_count) = task_map
                .get(&name)
                .map(|(ts, c)| {
                    (
                        if *ts == u64::MAX { None } else { Some(*ts) },
                        *c,
                    )
                })
                .unwrap_or((None, 0));
            Some(AgentInfo {
                name,
                model,
                clock_mins,
                next_task_ts,
                task_count,
            })
        })
        .collect();

    infos.sort_by_key(|a| a.sort_key());
    infos
}

/// Read the last 30 entries for `agent_name` from the activity log,
/// returned newest-first.
pub fn load_agent_log(agent_name: &str) -> Vec<AgentLogEntry> {
    let candidates = [
        paths::obsidian_path().join("vault/logs/agents.md"),
        std::path::PathBuf::from("/workspace/obsidian/vault/logs/agents.md"),
    ];
    let Some(log_path) = candidates.iter().find(|p| p.is_file()) else {
        return Vec::new();
    };
    let Ok(content) = std::fs::read_to_string(log_path) else {
        return Vec::new();
    };

    let mut entries: Vec<AgentLogEntry> = content
        .lines()
        .filter(|l| l.starts_with('|') && !l.contains("Timestamp") && !l.contains("---"))
        .filter_map(|line| {
            let cols: Vec<&str> = line.split('|').map(str::trim).collect();
            // cols: [0]="", [1]=ts, [2]=agent, [3]=status, [4]=dur, [5]=tokens, [6]=card
            if cols.len() < 7 {
                return None;
            }
            if cols[2] != agent_name {
                return None;
            }
            let ts_raw = cols[1];
            let status = cols[3].to_string();
            let dur = cols[4].to_string();
            let card = strip_date_prefix(cols[6]);
            let ts_short = if ts_raw.len() >= 16 {
                format!("{} {}", &ts_raw[5..10], &ts_raw[11..16])
            } else {
                ts_raw.to_string()
            };
            Some(AgentLogEntry {
                ts_short,
                status,
                duration: dur,
                card,
            })
        })
        .collect();

    entries.reverse();
    entries.truncate(30);
    entries
}
