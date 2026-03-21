//! Render utility containers (zion-reverseproxy and others) as a compact group.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;

/// Render the utils group (zion-* containers that are not dk or agent).
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

        // Strip "zion-" prefix for compact display
        let display_name = u.name.strip_prefix("zion-").unwrap_or(&u.name);

        let mut spans = vec![
            Span::raw("   "),
            Span::styled(status_icon, status_style),
            Span::raw(" "),
            Span::styled(format!("{display_name:<16}"), theme::name()),
            Span::styled(format!("{status_text:<6}"), theme::uptime()),
        ];

        if !u.cpu.is_empty() {
            spans.push(Span::raw("  "));
            spans.push(Span::styled(u.cpu.trim().to_string(), theme::cpu()));
            spans.push(Span::raw("  "));
            spans.push(Span::styled(u.mem.trim().to_string(), theme::dim()));
        }

        lines.push(Line::from(spans));
    }

    frame.render_widget(Paragraph::new(lines), area);
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
