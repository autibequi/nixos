//! Agent & Tasks panel popup — shows running sessions and vault task queue.

use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, Clear, Paragraph};
use ratatui::Frame;

use crate::app::App;
use crate::theme;

pub fn render(frame: &mut Frame, app: &App) {
    let area  = popup_rect(frame.area());
    let inner = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title(" Agents & Tasks ")
        .title_style(theme::header())
        .border_style(theme::separator())
        .inner(area);

    frame.render_widget(Clear, area);
    frame.render_widget(
        Block::default()
            .borders(Borders::ALL)
            .border_type(BorderType::Rounded)
            .title(" Agents & Tasks ")
            .title_style(theme::header())
            .border_style(theme::separator()),
        area,
    );

    // Split inner area: agents / divider / tasks / footer
    let task_rows = (app.agent_tasks.len() as u16 + 1).max(2);
    let agent_rows = (app.agent_count() as u16 + 1).max(2);
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(agent_rows),
            Constraint::Length(task_rows),
            Constraint::Min(0),
            Constraint::Length(1),
        ])
        .split(inner);

    render_agents(frame, app, chunks[0]);
    render_tasks(frame, app, chunks[1]);
    render_footer(frame, chunks[3]);
}

fn render_agents(frame: &mut Frame, app: &App, area: Rect) {
    let all_sessions: Vec<_> = app.snapshot.agents.iter()
        .chain(app.snapshot.background.iter())
        .collect();

    let any_up    = all_sessions.iter().any(|s| s.is_up);
    let hdr_icon  = if any_up { "\u{25cf}" } else { "\u{25cb}" };
    let hdr_style = if any_up { theme::up_icon() } else { theme::down_icon() };
    let count_str = format!("  ({} running)", all_sessions.iter().filter(|s| s.is_up).count());

    let mut lines = vec![Line::from(vec![
        Span::styled(hdr_icon, hdr_style),
        Span::raw(" "),
        Span::styled("Agents", theme::group_label()),
        Span::styled(count_str, theme::dim()),
    ])];

    if all_sessions.is_empty() {
        lines.push(Line::from(vec![
            Span::raw("  "),
            Span::styled("no active sessions", theme::dim()),
        ]));
    }

    for (i, s) in all_sessions.iter().enumerate() {
        let is_sel    = i == app.agent_cursor;
        let marker    = if is_sel { "\u{25b6}" } else { " " };
        let icon      = if s.is_up { "\u{25cf}" } else { "\u{25cb}" };
        let mk_style  = if is_sel { theme::selected() } else { theme::dim() };
        let nm_style  = if is_sel { theme::selected() } else { theme::name() };
        let ic_style  = if s.is_up { theme::up_icon() } else { theme::down_icon() };

        // Short project path: last 2 path components or just the last
        let proj = short_path(&s.mnt_path);

        let uptime = format_uptime(&s.status);

        let mut spans = vec![
            Span::raw("  "),
            Span::styled(marker, mk_style),
            Span::raw(" "),
            Span::styled(icon, ic_style),
            Span::raw(" "),
            Span::styled(format!("{:<8}", s.short_id), nm_style),
            Span::raw("  "),
            Span::styled(format!("{:<20}", proj), theme::dim()),
            Span::raw("  "),
            Span::styled(format!("{:<6}", uptime), theme::uptime()),
        ];

        if s.is_up && !s.cpu.is_empty() {
            spans.push(Span::raw("  "));
            spans.push(Span::styled(format!("{:>6}", s.cpu.trim()), theme::cpu()));
            spans.push(Span::raw("  "));
            let mem = s.mem.split('/').next().unwrap_or(&s.mem)
                .replace("MiB", "M").replace("GiB", "G").trim().to_string();
            spans.push(Span::styled(format!("{:<7}", mem), theme::mem()));
        }

        if s.session_count > 0 {
            spans.push(Span::styled(
                format!(" [{}×]", s.session_count),
                theme::dim(),
            ));
        }

        lines.push(Line::from(spans));
    }

    frame.render_widget(Paragraph::new(lines), area);
}

fn render_tasks(frame: &mut Frame, app: &App, area: Rect) {
    let any    = !app.agent_tasks.is_empty();
    let icon   = if any { "\u{25cf}" } else { "\u{25cb}" };
    let istyle = if any { theme::up_icon() } else { theme::dim() };

    let mut lines = vec![Line::from(vec![
        Span::styled(icon, istyle),
        Span::raw(" "),
        Span::styled("Tasks", theme::group_label()),
        Span::styled(format!("  ({} queued)", app.agent_tasks.len()), theme::dim()),
    ])];

    if app.agent_tasks.is_empty() {
        lines.push(Line::from(vec![
            Span::raw("  "),
            Span::styled("no tasks found", theme::dim()),
        ]));
    } else {
        for title in &app.agent_tasks {
            lines.push(Line::from(vec![
                Span::raw("    "),
                Span::styled("\u{2022} ", theme::dim()),
                Span::styled(title.clone(), theme::name()),
            ]));
        }
    }

    frame.render_widget(Paragraph::new(lines), area);
}

fn render_footer(frame: &mut Frame, area: Rect) {
    let line = Line::from(vec![
        Span::styled("  \u{2191}\u{2193}", theme::footer_dim()),
        Span::styled(" nav  ", theme::footer_dim()),
        Span::styled("Enter", theme::footer_key()),
        Span::styled(" stop agent  ", theme::footer_dim()),
        Span::styled("a / Esc", theme::footer_key()),
        Span::styled(" close", theme::footer_dim()),
    ]);
    frame.render_widget(Paragraph::new(line), area);
}

fn popup_rect(r: Rect) -> Rect {
    let width  = (r.width  * 4 / 5).min(80).max(50);
    let height = (r.height * 3 / 4).min(40).max(12);
    let x = r.x + r.width.saturating_sub(width) / 2;
    let y = r.y + r.height.saturating_sub(height) / 2;
    Rect::new(x, y, width.min(r.width), height.min(r.height))
}

fn short_path(path: &str) -> String {
    if path.is_empty() { return "—".into(); }
    let parts: Vec<&str> = path.trim_end_matches('/').rsplitn(2, '/').collect();
    parts[0].to_string()
}

fn format_uptime(status: &str) -> String {
    if status.to_lowercase().starts_with("up") {
        status
            .trim_start_matches("Up ")
            .trim_start_matches("up ")
            .replace("About an hour", "~1h")
            .replace(" seconds", "s")
            .replace(" minutes", "min")
            .replace(" hours", "h")
            .replace(" days", "d")
            .split(" (")
            .next()
            .unwrap_or("")
            .to_string()
    } else {
        "stopped".into()
    }
}
