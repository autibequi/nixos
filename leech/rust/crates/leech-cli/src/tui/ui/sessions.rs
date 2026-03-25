//! Render agent and background session groups with tree-style branch decorations.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::tui::app::App;
use crate::tui::theme;
use crate::status::SessionInfo;

pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    if !app.snapshot.agents.is_empty() {
        render_group(&mut lines, "agents", &app.snapshot.agents);
    }
    if !app.snapshot.background.is_empty() {
        if !lines.is_empty() { lines.push(Line::raw("")); }
        render_group(&mut lines, "background", &app.snapshot.background);
    }
    if lines.is_empty() {
        lines.push(Line::from(vec![
            Span::raw("  "),
            Span::styled("no active sessions", theme::dim()),
        ]));
    }

    frame.render_widget(Paragraph::new(lines), area);
}

fn render_group(lines: &mut Vec<Line<'static>>, label: &str, sessions: &[SessionInfo]) {
    let any_up      = sessions.iter().any(|s| s.is_up);
    let icon        = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let icon_style  = if any_up { theme::up_icon() } else { theme::down_icon() };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled(label.to_string(), theme::group_label()),
    ]));

    // Group by mnt_path, preserving insertion order
    let mut folders: Vec<String> = Vec::new();
    let mut by_folder: std::collections::HashMap<String, Vec<&SessionInfo>> =
        std::collections::HashMap::new();
    for s in sessions {
        let key = if s.mnt_path.is_empty() { s.name.clone() } else { s.mnt_path.clone() };
        if !by_folder.contains_key(&key) { folders.push(key.clone()); }
        by_folder.entry(key).or_default().push(s);
    }

    let folder_count = folders.len();
    for (fi, folder_key) in folders.iter().enumerate() {
        let group           = &by_folder[folder_key];
        let is_last_folder  = fi == folder_count - 1;
        let folder_branch   = if is_last_folder { "\u{2514}\u{2500}" } else { "\u{251c}\u{2500}" };
        let vert_pad        = if is_last_folder { "  " } else { "\u{2502} " };

        let folder_label    = shorten_path(folder_key);
        let folder_any_up   = group.iter().any(|s| s.is_up);
        let folder_icon     = if folder_any_up { "\u{25cf}" } else { "\u{25cb}" };
        let folder_icon_sty = if folder_any_up { theme::up_icon() } else { theme::down_icon() };
        // Use branch from first session that has one
        let branch = group.iter().map(|s| s.branch.as_str()).find(|b| !b.is_empty()).unwrap_or("");
        let mut folder_spans = vec![
            Span::raw("  "),
            Span::styled(folder_branch.to_string(), theme::tree_branch()),
            Span::raw(" "),
            Span::styled(folder_icon, folder_icon_sty),
            Span::raw(" "),
            Span::styled(folder_label, theme::name()),
        ];
        if !branch.is_empty() {
            folder_spans.push(Span::raw("  "));
            folder_spans.push(Span::styled(format!("@{branch}"), theme::dim()));
        }
        lines.push(Line::from(folder_spans));

        let total       = group.len();
        let count_label = if total == 1 {
            "1 sessão".to_string()
        } else {
            format!("{total} sessões")
        };

        // All folder sizes (single or multi) render as one stats line (collapsed view).
        let uptime = group.iter()
            .filter(|s| s.is_up)
            .map(|s| format_uptime(&s.status))
            .next()
            .unwrap_or_else(|| "stop".to_string());
        let any_up_sess = group.iter().any(|s| s.is_up);

        let mut spans = vec![
            Span::raw("  "),
            Span::styled(vert_pad.to_string(), theme::tree_branch()),
            Span::raw("  "),
            Span::styled(format!("{:<20}", count_label), theme::dim()),
            Span::raw("  "),
            Span::styled(format!("{:<5}", uptime), theme::uptime()),
        ];

        if any_up_sess {
            // Aggregate CPU (sum) and memory (sum used / sum limit)
            let total_cpu: f32 = group.iter()
                .filter_map(|s| s.cpu.trim().trim_end_matches('%').parse::<f32>().ok())
                .sum();
            let cpu_pct = total_cpu.min(100.0) as u8;
            let cpu_bar = mini_bar(cpu_pct, 6);
            let cpu_display = if total > 1 {
                format!("{:.2}%", total_cpu)
            } else {
                group[0].cpu.trim().to_string()
            };

            let total_used: u64 = group.iter().map(|s| parse_mem_used(s.mem.as_str())).sum();
            let total_limit: u64 = group.iter().map(|s| parse_mem_limit(s.mem.as_str())).sum();
            let mem_pct = if total_limit > 0 {
                ((total_used as f64 / total_limit as f64 * 100.0) as u8).min(100)
            } else {
                0
            };
            let mem_bar = mini_bar(mem_pct, 6);
            let mem_used_str = if total > 1 {
                fmt_bytes(total_used)
            } else {
                mem_used_only(&group[0].mem)
            };

            spans.push(Span::raw("  "));
            spans.push(Span::styled(cpu_bar, theme::up_icon()));
            spans.push(Span::styled(format!("  {cpu_display}"), theme::cpu()));
            spans.push(Span::raw("  "));
            spans.push(Span::styled(mem_bar, theme::mem()));
            spans.push(Span::styled(format!("  {mem_used_str}"), theme::mem()));
        }

        lines.push(Line::from(spans));
    }
}

fn mini_bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty  = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

fn format_uptime(status: &str) -> String {
    let lower = status.to_lowercase();
    if !lower.starts_with("up") { return "stop".to_string(); }
    status
        .strip_prefix("Up ").or_else(|| status.strip_prefix("up "))
        .unwrap_or(status)
        .replace("About an hour", "~1h")
        .replace("About a minute", "~1m")
        .replace(" seconds", "s")
        .replace(" second", "s")
        .replace(" minutes", "m")
        .replace(" minute", "m")
        .replace(" hours", "h")
        .replace(" hour", "h")
        .replace(" days", "d")
        .replace(" day", "d")
        .split(" (").next().unwrap_or("").to_string()
}

fn mem_used_only(mem: &str) -> String {
    mem.split('/').next().unwrap_or(mem)
        .replace("MiB", "M").replace("GiB", "G")
        .trim().to_string()
}

fn parse_mem_bytes(s: &str) -> u64 {
    let s = s.trim();
    if let Some(n) = s.strip_suffix("GiB").or_else(|| s.strip_suffix('G')) {
        return (n.parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0 * 1024.0) as u64;
    }
    if let Some(n) = s.strip_suffix("MiB").or_else(|| s.strip_suffix('M')) {
        return (n.parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0) as u64;
    }
    if let Some(n) = s.strip_suffix("kB").or_else(|| s.strip_suffix('k')) {
        return (n.parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    s.parse::<u64>().unwrap_or(0)
}

fn parse_mem_used(mem: &str) -> u64 {
    parse_mem_bytes(mem.split('/').next().unwrap_or("").trim())
}

fn parse_mem_limit(mem: &str) -> u64 {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() < 2 { return 0; }
    parse_mem_bytes(parts[1].trim())
}

fn fmt_bytes(bytes: u64) -> String {
    const GB: u64 = 1024 * 1024 * 1024;
    const MB: u64 = 1024 * 1024;
    if bytes >= GB {
        format!("{:.2}G", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.0}M", bytes as f64 / MB as f64)
    } else {
        format!("{bytes}B")
    }
}

fn shorten_path(p: &str) -> String {
    let home = std::env::var("HOME").unwrap_or_default();
    if !home.is_empty() && p.starts_with(&home) {
        format!("~{}", &p[home.len()..])
    } else {
        p.to_string()
    }
}
