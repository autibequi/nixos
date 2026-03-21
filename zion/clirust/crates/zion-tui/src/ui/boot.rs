//! Boot flags panel — displays BOOT env vars as compact chips.

use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;
use ratatui::Frame;

use crate::app::App;
use crate::theme;

/// Render the boot flags section.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let b = &app.snapshot.boot;

    let flag = |label: &'static str, val: &str, on_val: &str| -> Vec<Span<'static>> {
        let is_on = val == on_val || val == "1" && on_val == "ON";
        let val_style = if is_on { theme::up_icon() } else { theme::dim() };
        vec![
            Span::styled(format!("{label}="), theme::dim()),
            Span::styled(val.to_string(), val_style),
            Span::raw("  "),
        ]
    };

    let mut spans: Vec<Span> = vec![Span::raw("  ")];

    // datetime first, abbreviated
    if !b.datetime.is_empty() {
        spans.push(Span::styled(b.datetime.clone(), theme::dim()));
        spans.push(Span::raw("  "));
    }

    for s in flag("docker", &b.in_docker, "ON") { spans.push(s); }
    for s in flag("zion_edit", &b.zion_edit, "ON") { spans.push(s); }
    for s in flag("persona", &b.personality, "ON") { spans.push(s); }
    for s in flag("autocommit", &b.autocommit, "ON") { spans.push(s); }
    for s in flag("headless", &b.headless, "ON") { spans.push(s); }
    for s in flag("debug", &b.zion_debug, "ON") { spans.push(s); }

    let lines = vec![Line::from(spans)];
    frame.render_widget(Paragraph::new(lines), area);
}
