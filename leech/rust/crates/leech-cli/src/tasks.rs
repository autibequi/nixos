//! Kanban task cards — reading TODO/DOING/DONE from the Obsidian tasks directory.

use serde::{Deserialize, Serialize};

use crate::{agents::parse_task_stem, paths};

/// A single kanban task card.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskCard {
    pub filename: String,
    pub label: String,
    /// "todo" | "doing" | "done"
    pub state: String,
    /// Scheduled epoch timestamp parsed from filename prefix.
    pub ts: Option<u64>,
}

impl TaskCard {
    fn from_file(filename: &str, state: &str) -> Self {
        let label = crate::agents::strip_date_prefix(filename);
        let ts = parse_task_stem(filename.trim_end_matches(".md")).map(|(ts, _)| ts);
        TaskCard {
            filename: filename.to_string(),
            label,
            state: state.to_string(),
            ts,
        }
    }

    /// Seconds since the card's scheduled timestamp (positive = overdue).
    pub fn age_secs(&self) -> Option<i64> {
        let ts = self.ts?;
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs();
        Some(now as i64 - ts as i64)
    }

    /// Human-readable age string like "5min", "2h", "3d".
    pub fn age_display(&self) -> String {
        match self.age_secs() {
            None => String::new(),
            Some(diff) => {
                let diff = diff.abs();
                if diff < 3600 {
                    format!("{}min", diff / 60)
                } else if diff < 86400 {
                    format!("{}h", diff / 3600)
                } else {
                    format!("{}d", diff / 86400)
                }
            }
        }
    }

    /// Human-readable "when" string — relative to now. Used for TODO scheduling.
    pub fn when_display(&self) -> String {
        match self.ts {
            None => String::new(),
            Some(ts) => {
                let now = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap_or_default()
                    .as_secs();
                let diff = ts as i64 - now as i64;
                if diff < -60 {
                    format!("\x1b[32matrasada {}min\x1b[0m", (-diff) / 60)
                } else if diff <= 0 {
                    "\x1b[32magora\x1b[0m".into()
                } else if diff < 3600 {
                    format!("em {}min", diff / 60)
                } else if diff < 86400 {
                    format!("em {}h", diff / 3600)
                } else {
                    format!("em {}d", diff / 86400)
                }
            }
        }
    }
}

/// List all tasks across DOING/TODO/DONE, in that order (doing first).
pub fn list_tasks() -> Vec<TaskCard> {
    let Some(tasks_dir) = paths::tasks_dir() else {
        return Vec::new();
    };

    let mut cards = Vec::new();

    for (subdir, state) in &[("DOING", "doing"), ("TODO", "todo"), ("DONE", "done")] {
        let dir = tasks_dir.join(subdir);
        if !dir.is_dir() {
            continue;
        }
        let mut entries: Vec<String> = std::fs::read_dir(&dir)
            .into_iter()
            .flatten()
            .flatten()
            .filter_map(|e| {
                let name = e.file_name().to_string_lossy().into_owned();
                name.ends_with(".md").then_some(name)
            })
            .collect();
        entries.sort();
        for filename in entries {
            cards.push(TaskCard::from_file(&filename, state));
        }
    }

    cards
}
