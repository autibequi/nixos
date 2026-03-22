//! Render utility containers (leech-reverseproxy and others) as a compact group.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;

/// Render the utils group (leech-* containers that are not dk or agent).
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    let any_up = app.snapshot.utils.iter().any(|u| u.is_up);
    let icon = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let icon_style = if any_up { theme::up_icon() } else { theme::down_icon() };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled("utils", theme::group_label()),
    ]));

    for u in &app.snapshot.utils {
        let (status_icon, status_style, status_text) = if u.is_up {
            ("\u{25cf}", theme::up_icon(), format_uptime(&u.status))
        } else {
            ("\u{25cb}", theme::down_icon(), "stopped".to_string())
        };

        // Strip "leech-" prefix for compact display
        let display_name = u.name.strip_prefix("leech-").unwrap_or(&u.name);

        let mut spans = vec![
            Span::raw("     "),
            Span::styled(status_icon, status_style),
            Span::raw(" "),
            Span::styled(format!("{display_name:<20}"), theme::name()),
            Span::raw(" "),
            Span::styled(format!("{status_text:<5}"), theme::uptime()),
        ];

        if !u.cpu.is_empty() {
            let cpu_pct = parse_pct(&u.cpu);
            let cpu_bar = mini_bar(cpu_pct, 6);
            let cpu_style = pct_color(cpu_pct);
            let mem_short = u.mem
                .replace("MiB", "M")
                .replace("GiB", "G")
                .replace(" / ", "/");
            let mem_bar = mem_bar_from_str(&u.mem);
            spans.push(Span::raw("  "));
            spans.push(Span::styled(cpu_bar, cpu_style));
            spans.push(Span::styled(format!(" {:<6}", u.cpu.trim()), theme::cpu()));
            spans.push(Span::raw(" "));
            spans.push(Span::styled(mem_bar, theme::mem()));
            spans.push(Span::styled(format!(" {mem_short}"), theme::dim()));
        }

        lines.push(Line::from(spans));
    }

    frame.render_widget(Paragraph::new(lines), area);
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

fn mem_bar_from_str(mem: &str) -> String {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() != 2 { return String::new(); }
    let used = parse_bytes(parts[0].trim());
    let total = parse_bytes(parts[1].trim());
    if total == 0 { return String::new(); }
    let pct = ((used * 100) / total).min(100) as u8;
    mini_bar(pct, 6)
}

fn parse_bytes(s: &str) -> u64 {
    let s = s.replace("GiB", "G").replace("MiB", "M").replace("kB", "K");
    if let Some(v) = s.strip_suffix('G') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0 * 1024.0) as u64;
    }
    if let Some(v) = s.strip_suffix('M') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0 * 1024.0) as u64;
    }
    if let Some(v) = s.strip_suffix('K') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    s.trim().parse::<u64>().unwrap_or(0)
}

fn format_uptime(status: &str) -> String {
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
