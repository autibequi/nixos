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
                spans.push(Span::styled(format!("  cpu {cpu:<6}"), theme::cpu()));
                let mem_short = mem
                    .replace("MiB", "M")
                    .replace("GiB", "G")
                    .replace(" / ", "/");
                spans.push(Span::styled(format!(" {mem_short}"), theme::mem()));
            }

            lines.push(Line::from(spans));
        }
    }

    let widget = Paragraph::new(lines);
    frame.render_widget(widget, area);
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
