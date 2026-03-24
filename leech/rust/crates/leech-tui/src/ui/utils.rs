//! Render utility containers (reverseproxy and others) as a compact group.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::{App, DK_SERVICES};
use crate::theme;

pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    let any_up     = app.snapshot.utils.iter().any(|u| u.is_up);
    let icon       = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let icon_style = if any_up { theme::up_icon() } else { theme::down_icon() };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled("utils", theme::group_label()),
    ]));

    let utils_count = app.snapshot.utils.len();
    for (i, u) in app.snapshot.utils.iter().enumerate() {
        let is_selected  = app.cursor_idx == DK_SERVICES.len() + i;
        let is_last      = i == utils_count - 1;
        let branch       = if is_last { "\u{2514}\u{2500}" } else { "\u{251c}\u{2500}" };
        let (status_icon, status_style, status_text) = if u.is_up {
            ("\u{25cf}", theme::up_icon(), format_uptime(&u.status))
        } else {
            ("\u{25cb}", theme::down_icon(), "stopped".to_string())
        };

        let display_name = u.name.strip_prefix("leech-").unwrap_or(&u.name);
        let marker       = if is_selected { "\u{25b6}" } else { " " };
        let name_style   = if is_selected { theme::selected() } else { theme::name() };
        let marker_style = if is_selected { theme::selected() } else { theme::dim() };

        let mut spans = vec![
            Span::raw("  "),
            Span::styled(branch.to_string(), theme::tree_branch()),
            Span::raw(" "),
            Span::styled(marker.to_string(), marker_style),
            Span::raw(" "),
            Span::styled(status_icon, status_style),
            Span::raw(" "),
            Span::styled(format!("{display_name:<18}"), name_style),
            Span::raw(" "),
            Span::styled(format!("{status_text:<5}"), theme::uptime()),
        ];

        if !u.cpu.is_empty() {
            let cpu_pct  = parse_pct(&u.cpu);
            let cpu_bar  = mini_bar(cpu_pct, 6);
            let cpu_sty  = pct_color(cpu_pct);
            let mem_used = u.mem.split('/').next().unwrap_or(&u.mem)
                .replace("MiB", "M").replace("GiB", "G").trim().to_string();
            let mem_bar  = mem_bar_from_str(&u.mem);
            spans.push(Span::raw("  "));
            spans.push(Span::styled(cpu_bar, cpu_sty));
            spans.push(Span::styled(format!(" {:<6}", u.cpu.trim()), theme::cpu()));
            spans.push(Span::raw(" "));
            spans.push(Span::styled(mem_bar, theme::mem()));
            spans.push(Span::styled(format!(" {mem_used}"), theme::mem()));
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
    if pct >= 80      { Style::default().fg(Color::Rgb(243, 139, 168)) }
    else if pct >= 50 { Style::default().fg(Color::Rgb(249, 226, 175)) }
    else              { Style::default().fg(Color::Rgb(166, 227, 161)) }
}

fn mini_bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty  = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

fn mem_bar_from_str(mem: &str) -> String {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() != 2 { return String::new(); }
    let used  = parse_bytes(parts[0].trim());
    let total = parse_bytes(parts[1].trim());
    if total == 0 { return String::new(); }
    mini_bar(((used * 100) / total).min(100) as u8, 6)
}

fn parse_bytes(s: &str) -> u64 {
    let s = s.replace("GiB", "G").replace("MiB", "M").replace("kB", "K");
    if let Some(v) = s.strip_suffix('G') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1_073_741_824.0) as u64;
    }
    if let Some(v) = s.strip_suffix('M') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1_048_576.0) as u64;
    }
    if let Some(v) = s.strip_suffix('K') {
        return (v.trim().parse::<f64>().unwrap_or(0.0) * 1024.0) as u64;
    }
    s.trim().parse::<u64>().unwrap_or(0)
}

fn format_uptime(status: &str) -> String {
    status
        .strip_prefix("Up ").or_else(|| status.strip_prefix("up "))
        .unwrap_or(status)
        .replace("About an hour", "~1h")
        .replace(" seconds", "s")
        .replace(" minutes", "min")
        .replace(" hours", "h")
        .replace(" days", "d")
        .split(" (").next().unwrap_or("").to_string()
}
