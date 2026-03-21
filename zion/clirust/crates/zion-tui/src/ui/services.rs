//! Render the dockerized-services panel with status, uptime, CPU, and memory.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::{App, DK_SERVICES};
use crate::theme;

/// Render dockerized services panel.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let mut lines = Vec::new();

    if app.snapshot.dk_services.is_empty() {
        // Still show the service list from navigation
        lines.push(Line::from(vec![
            Span::styled("\u{25cb}", theme::down_icon()),
            Span::raw(" "),
            Span::styled("services", theme::group_label()),
        ]));

        for (i, &svc) in DK_SERVICES.iter().enumerate() {
            let is_selected = i == app.cursor_idx;
            let marker = if is_selected { "\u{25b6}" } else { " " };
            let style = if is_selected {
                theme::selected()
            } else {
                theme::dim()
            };

            lines.push(Line::from(vec![
                Span::raw("  "),
                Span::styled(marker.to_string(), style),
                Span::raw(" "),
                Span::styled("\u{25cb}", theme::down_icon()),
                Span::raw(" "),
                Span::styled(format!("{svc:<16}"), style),
                Span::styled("stopped", theme::dim()),
            ]));

            if is_selected {
                let log_line = app.snapshot.last_log.get(svc).map(|s| s.as_str()).unwrap_or("");
                let preview = truncate_log(log_line, area.width.saturating_sub(8) as usize);
                lines.push(Line::from(vec![
                    Span::raw("       "),
                    Span::styled(preview, log_level_style(log_line)),
                ]));
            }
        }
    } else {
        let any_up = app.snapshot.dk_services.iter().any(|s| s.is_up);
        let icon = if any_up { "\u{25cf}" } else { "\u{25cb}" };
        let icon_style = if any_up {
            theme::up_icon()
        } else {
            theme::down_icon()
        };

        lines.push(Line::from(vec![
            Span::styled(icon, icon_style),
            Span::raw(" "),
            Span::styled("services", theme::group_label()),
        ]));

        for (i, &svc) in DK_SERVICES.iter().enumerate() {
            let is_selected = i == app.cursor_idx;
            let marker = if is_selected { "\u{25b6}" } else { " " };

            // Find matching dk_service
            let dk = app
                .snapshot
                .dk_services
                .iter()
                .find(|d| d.name.contains(svc));

            let (status_icon, status_style, status_text, cpu, mem) = if let Some(d) = dk {
                if d.is_up {
                    (
                        "\u{25cf}",
                        theme::up_icon(),
                        format_uptime(&d.status),
                        d.cpu.clone(),
                        d.mem.clone(),
                    )
                } else {
                    (
                        "\u{25cb}",
                        theme::down_icon(),
                        "stopped".to_string(),
                        String::new(),
                        String::new(),
                    )
                }
            } else {
                (
                    "\u{25cb}",
                    theme::down_icon(),
                    "stopped".to_string(),
                    String::new(),
                    String::new(),
                )
            };

            let name_style = if is_selected {
                theme::selected()
            } else {
                theme::name()
            };
            let marker_style = if is_selected {
                theme::selected()
            } else {
                theme::dim()
            };

            let mut spans = vec![
                Span::raw("  "),
                Span::styled(marker.to_string(), marker_style),
                Span::raw(" "),
                Span::styled(status_icon, status_style),
                Span::raw(" "),
                Span::styled(format!("{svc:<16}"), name_style),
                Span::styled(format!("{status_text:<6}"), theme::uptime()),
            ];

            if !cpu.is_empty() {
                let cpu_pct = parse_pct(&cpu);
                let cpu_bar = mini_bar(cpu_pct, 6);
                let cpu_style = pct_color(cpu_pct);
                spans.push(Span::raw("  "));
                spans.push(Span::styled(cpu_bar, cpu_style));
                spans.push(Span::styled(format!(" {cpu:<6}", cpu = cpu.trim()), theme::cpu()));

                let mem_short = mem
                    .replace("MiB", "M")
                    .replace("GiB", "G")
                    .replace(" / ", "/");
                // Parse used/total for memory bar
                let mem_bar = mem_bar_from_str(&mem);
                spans.push(Span::raw(" "));
                spans.push(Span::styled(mem_bar, theme::mem()));
                spans.push(Span::styled(format!(" {mem_short}"), theme::dim()));
            }

            lines.push(Line::from(spans));

            // Inline last-log preview for the selected service
            if is_selected {
                let log_line = app
                    .snapshot
                    .last_log
                    .get(svc)
                    .map(|s| s.as_str())
                    .unwrap_or("");
                let preview = truncate_log(log_line, area.width.saturating_sub(8) as usize);
                let log_style = log_level_style(log_line);
                lines.push(Line::from(vec![
                    Span::raw("       "),
                    Span::styled(preview, log_style),
                ]));
            }
        }
    }

    let widget = Paragraph::new(lines);
    frame.render_widget(widget, area);
}

/// Truncate a log line to fit the available width, stripping ANSI codes.
fn truncate_log(line: &str, max: usize) -> String {
    // Strip ANSI escape sequences
    let clean: String = {
        let mut out = String::new();
        let mut in_escape = false;
        for ch in line.chars() {
            if in_escape {
                if ch.is_ascii_alphabetic() { in_escape = false; }
            } else if ch == '\x1b' {
                in_escape = true;
            } else {
                out.push(ch);
            }
        }
        out
    };
    let trimmed = clean.trim();
    if trimmed.len() <= max {
        trimmed.to_string()
    } else {
        format!("{}…", &trimmed[..max.saturating_sub(1)])
    }
}

/// Style a log line based on its content level.
fn log_level_style(line: &str) -> ratatui::style::Style {
    use ratatui::style::{Color, Style};
    let up = line.to_uppercase();
    if up.contains("ERROR") || up.contains("FATAL") || up.contains("CRIT") || up.contains("PANIC") {
        Style::default().fg(Color::Red)
    } else if up.contains("WARN") {
        Style::default().fg(Color::Yellow)
    } else if up.contains("START") || up.contains("LISTEN") || up.contains("READY")
        || up.contains("BOOT") || up.contains("UP") || up.contains("INIT")
    {
        Style::default().fg(Color::Green)
    } else if up.contains("STOP") || up.contains("SHUT") || up.contains("EXIT") || up.contains("DOWN") {
        Style::default().fg(Color::Indexed(214)) // orange
    } else {
        crate::theme::dim()
    }
}

/// Parse a CPU percentage string like "21.07%" → 21.
fn parse_pct(s: &str) -> u8 {
    s.trim()
        .trim_end_matches('%')
        .parse::<f32>()
        .map(|f| f as u8)
        .unwrap_or(0)
}

/// Color style based on percentage thresholds.
fn pct_color(pct: u8) -> ratatui::style::Style {
    use ratatui::style::{Color, Style};
    if pct >= 80 {
        Style::default().fg(Color::Red)
    } else if pct >= 50 {
        Style::default().fg(Color::Yellow)
    } else {
        Style::default().fg(Color::Green)
    }
}

/// Build a compact `width`-char bar: `███░░░`
fn mini_bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

/// Parse "1.453GiB / 4GiB" → percentage and render as a bar.
fn mem_bar_from_str(mem: &str) -> String {
    let parts: Vec<&str> = mem.split('/').collect();
    if parts.len() != 2 {
        return String::new();
    }
    let used = parse_bytes(parts[0].trim());
    let total = parse_bytes(parts[1].trim());
    if total == 0 {
        return String::new();
    }
    let pct = ((used * 100) / total).min(100) as u8;
    mini_bar(pct, 6)
}

/// Parse a bytes string like "1.453GiB", "717.8MiB" → bytes.
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

/// Strip the "Up " prefix and abbreviate common duration words for compact display.
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
