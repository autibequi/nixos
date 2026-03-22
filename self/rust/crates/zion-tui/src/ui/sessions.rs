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
    let icon_style = if any_up {
        theme::up_icon()
    } else {
        theme::down_icon()
    };

    lines.push(Line::from(vec![
        Span::styled(icon, icon_style),
        Span::raw(" "),
        Span::styled(label.to_string(), theme::group_label()),
    ]));

    let total = sessions.len();
    for (i, session) in sessions.iter().enumerate() {
        let is_last = i == total - 1;
        let branch = if is_last {
            "\u{2514}\u{2500}"
        } else {
            "\u{251c}\u{2500}"
        };

        let icon = if session.is_up {
            "\u{25cf}"
        } else {
            "\u{25cb}"
        };
        let icon_style = if session.is_up {
            theme::up_icon()
        } else {
            theme::down_icon()
        };

        let uptime = format_uptime(&session.status);
        // Use mnt_path (host path bound to /workspace/mnt) as identifier; fall back to container name
        let ident = if !session.mnt_path.is_empty() {
            shorten_path(&session.mnt_path)
        } else {
            session
                .name
                .strip_prefix("zion-projects-leech-run-")
                .or_else(|| session.name.strip_prefix("zion-projects-"))
                .or_else(|| session.name.strip_prefix("zion-"))
                .unwrap_or(&session.name)
                .to_string()
        };

        let mut spans = vec![
            Span::raw("  "),
            Span::styled(branch.to_string(), theme::tree_branch()),
            Span::raw(" "),
            Span::styled(icon, icon_style),
            Span::raw(" "),
            Span::styled(format!("{ident:<20}"), theme::name()),
            Span::raw(" "),
            Span::styled(format!("{uptime:<5}"), theme::uptime()),
        ];

        if session.is_up && !session.cpu.is_empty() {
            let cpu_pct = parse_pct(&session.cpu);
            let cpu_bar = mini_bar(cpu_pct, 6);
            let cpu_style = pct_color(cpu_pct);
            spans.push(Span::raw("  "));
            spans.push(Span::styled(cpu_bar, cpu_style));
            spans.push(Span::styled(format!(" {:<6}", session.cpu.trim()), theme::cpu()));
            let mem_short = shorten_mem(&session.mem);
            spans.push(Span::styled(format!(" {mem_short}"), theme::mem()));
        }

        // Active mounts only
        let active: Vec<_> = session.mounts.iter().filter(|m| m.present).collect();
        if !active.is_empty() {
            spans.push(Span::raw("  "));
            for mount in active {
                spans.push(Span::styled(format!("{} ", mount.label), theme::mount_present()));
            }
        }

        lines.push(Line::from(spans));
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

/// Shorten memory strings by replacing verbose unit names with single-letter suffixes.
fn shorten_mem(mem: &str) -> String {
    mem.replace("MiB", "M")
        .replace("GiB", "G")
        .replace(" / ", "/")
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
