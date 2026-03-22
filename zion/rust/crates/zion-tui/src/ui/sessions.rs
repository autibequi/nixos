//! Render agent and background session groups with tree-style branch decorations.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;
use zion_sdk::status::SessionInfo;

/// Render agent and background session groups.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    if !app.snapshot.agents.is_empty() {
        render_group(&mut lines, "agents", &app.snapshot.agents);
    }
    if !app.snapshot.background.is_empty() {
        if !lines.is_empty() {
            lines.push(Line::raw(""));
        }
        render_group(&mut lines, "background", &app.snapshot.background);
    }

    if lines.is_empty() {
        lines.push(Line::from(vec![
            Span::raw("  "),
            Span::styled("no active sessions", theme::dim()),
        ]));
    }

    let widget = Paragraph::new(lines);
    frame.render_widget(widget, area);
}

fn render_group(lines: &mut Vec<Line<'static>>, label: &str, sessions: &[SessionInfo]) {
    let any_up = sessions.iter().any(|s| s.is_up);
    let icon = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let icon_style = if any_up { theme::up_icon() } else { theme::down_icon() };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled(label.to_string(), theme::group_label()),
    ]));

    // Group sessions by mnt_path (preserve insertion order)
    let mut folders: Vec<String> = Vec::new();
    let mut by_folder: std::collections::HashMap<String, Vec<&SessionInfo>> =
        std::collections::HashMap::new();
    for s in sessions {
        let key = if s.mnt_path.is_empty() { s.name.clone() } else { s.mnt_path.clone() };
        if !by_folder.contains_key(&key) {
            folders.push(key.clone());
        }
        by_folder.entry(key).or_default().push(s);
    }

    let folder_count = folders.len();
    for (fi, folder_key) in folders.iter().enumerate() {
        let group = &by_folder[folder_key];
        let is_last_folder = fi == folder_count - 1;
        let folder_branch = if is_last_folder { "\u{2514}\u{2500}" } else { "\u{251c}\u{2500}" };
        let vert_pad   = if is_last_folder { "  " } else { "\u{2502} " };

        // Folder sub-header
        let folder_label = shorten_path(folder_key);
        let folder_any_up = group.iter().any(|s| s.is_up);
        let folder_icon = if folder_any_up { "\u{25cf}" } else { "\u{25cb}" };
        let folder_icon_style = if folder_any_up { theme::up_icon() } else { theme::down_icon() };
        lines.push(Line::from(vec![
            Span::raw("  "),
            Span::styled(folder_branch.to_string(), theme::tree_branch()),
            Span::raw(" "),
            Span::styled(folder_icon, folder_icon_style),
            Span::raw(" "),
            Span::styled(folder_label, theme::name()),
        ]));

        // Sessions within this folder
        let total = group.len();
        let agent_count: usize = group.iter().map(|s| s.session_count.max(1)).sum();
        let count_label = if agent_count == 1 { "1 agente".to_string() } else { format!("{agent_count} agentes") };

        if total == 1 {
            // Single agent: counter line with inline stats, no separate session row
            let session = &group[0];
            let uptime = format_uptime(&session.status);
            let mut spans = vec![
                Span::raw("  "),
                Span::styled(vert_pad.to_string(), theme::tree_branch()),
                Span::raw("  "),
                Span::styled(count_label, theme::dim()),
                Span::raw("  "),
                Span::styled(uptime, theme::uptime()),
            ];
            if session.is_up && !session.cpu.is_empty() {
                let cpu_pct = parse_pct(&session.cpu);
                let cpu_bar = mini_bar(cpu_pct, 6);
                let mem_pct = parse_mem_pct(&session.mem);
                let mem_bar = mini_bar(mem_pct, 6);
                let mem_used = mem_used_only(&session.mem);
                spans.push(Span::raw("  "));
                spans.push(Span::styled(cpu_bar, theme::up_icon()));
                spans.push(Span::styled(format!(" {:<6}", session.cpu.trim()), theme::cpu()));
                spans.push(Span::raw("  "));
                spans.push(Span::styled(mem_bar, theme::mem()));
                spans.push(Span::styled(format!(" {mem_used}"), theme::mem()));
            }
            lines.push(Line::from(spans));
        } else {
            // Multiple agents: counter line + individual session rows
            lines.push(Line::from(vec![
                Span::raw("  "),
                Span::styled(vert_pad.to_string(), theme::tree_branch()),
                Span::raw("  "),
                Span::styled(count_label, theme::dim()),
            ]));

            for (i, session) in group.iter().enumerate() {
                let is_last = i == total - 1;
                let branch = if is_last { "\u{2514}\u{2500}" } else { "\u{251c}\u{2500}" };
                let sess_icon = if session.is_up { "\u{25cf}" } else { "\u{25cb}" };
                let sess_icon_style = if session.is_up { theme::up_icon() } else { theme::down_icon() };
                let uptime = format_uptime(&session.status);
                let ident = session.short_id.clone();

                let mut spans = vec![
                    Span::raw("  "),
                    Span::styled(vert_pad.to_string(), theme::tree_branch()),
                    Span::styled(branch.to_string(), theme::tree_branch()),
                    Span::raw(" "),
                    Span::styled(sess_icon, sess_icon_style),
                    Span::raw(" "),
                    Span::styled(format!("{ident:<12}"), theme::dim()),
                    Span::raw(" "),
                    Span::styled(format!("{uptime:<5}"), theme::uptime()),
                ];

                if session.is_up && !session.cpu.is_empty() {
                    let cpu_pct = parse_pct(&session.cpu);
                    let cpu_bar = mini_bar(cpu_pct, 6);
                    let mem_pct = parse_mem_pct(&session.mem);
                    let mem_bar = mini_bar(mem_pct, 6);
                    let mem_used = mem_used_only(&session.mem);
                    spans.push(Span::raw("  "));
                    spans.push(Span::styled(cpu_bar, theme::up_icon()));
                    spans.push(Span::styled(format!(" {:<6}", session.cpu.trim()), theme::cpu()));
                    spans.push(Span::raw("  "));
                    spans.push(Span::styled(mem_bar, theme::mem()));
                    spans.push(Span::styled(format!(" {mem_used}"), theme::mem()));
                }

                lines.push(Line::from(spans));
            }
        }
    }
}

fn parse_pct(s: &str) -> u8 {
    s.trim().trim_end_matches('%').parse::<f32>().map(|f| f as u8).unwrap_or(0)
}

fn pct_color(pct: u8) -> ratatui::style::Style {
    use ratatui::style::{Color, Style};
    if pct >= 80 { Style::default().fg(Color::Red) }
    else if pct >= 50 { Style::default().fg(Color::Yellow) }
    else { Style::default().fg(Color::Green) }
}

fn mini_bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

/// Strip the "Up " prefix and abbreviate common duration words for compact display.
fn format_uptime(status: &str) -> String {
    let lower = status.to_lowercase();
    if !lower.starts_with("up") {
        return "stop".to_string();
    }
    status
        .strip_prefix("Up ")
        .or_else(|| status.strip_prefix("up "))
        .unwrap_or(status)
        .replace("About an hour", "~1h")
        .replace(" seconds", "s")
        .replace(" minutes", "min")
        .replace(" hours", "h")
        .replace(" days", "d")
        .split(" (")
        .next()
        .unwrap_or("")
        .to_string()
}

/// Returns only the used portion of a memory string (strips the limit).
fn mem_used_only(mem: &str) -> String {
    mem.split('/').next().unwrap_or(mem)
        .replace("MiB", "M")
        .replace("GiB", "G")
        .trim()
        .to_string()
}

/// Parse memory percentage from docker MemUsage string (e.g. "346.2MiB / 12GiB").
fn parse_mem_pct(mem: &str) -> u8 {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() != 2 { return 0; }
    let used = parse_mem_bytes(parts[0].trim());
    let limit = parse_mem_bytes(parts[1].trim());
    if limit == 0 { return 0; }
    ((used as f64 / limit as f64 * 100.0) as u8).min(100)
}

fn parse_mem_bytes(s: &str) -> u64 {
    let s = s.trim();
    if let Some(n) = s.strip_suffix("GiB").or_else(|| s.strip_suffix("G")) {
        return (n.parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0 * 1024.0) as u64;
    }
    if let Some(n) = s.strip_suffix("MiB").or_else(|| s.strip_suffix("M")) {
        return (n.parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0) as u64;
    }
    if let Some(n) = s.strip_suffix("kB").or_else(|| s.strip_suffix("k")) {
        return (n.parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    s.parse::<u64>().unwrap_or(0)
}

/// Shorten an absolute path by replacing $HOME with `~`.
fn shorten_path(p: &str) -> String {
    let home = std::env::var("HOME").unwrap_or_default();
    if !home.is_empty() && p.starts_with(&home) {
        format!("~{}", &p[home.len()..])
    } else {
        p.to_string()
    }
}
