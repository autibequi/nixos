use ratatui::prelude::*;
use ratatui::widgets::*;
use ratatui::widgets::ScrollbarOrientation;

use super::app::{App, AppMode, ContainerKind, Tab};
use ratatui::layout::Flex;

// ── Colors ──────────────────────────────────────────────────────
const GREEN: Color = Color::Rgb(166, 227, 161);
const RED: Color = Color::Rgb(243, 139, 168);
const MAUVE: Color = Color::Rgb(203, 166, 247);
const PEACH: Color = Color::Rgb(250, 179, 135);
const TEXT: Color = Color::Rgb(205, 214, 244);
const DIM: Color = Color::Rgb(108, 112, 134);
const SURFACE: Color = Color::Rgb(30, 30, 46);
const YELLOW: Color = Color::Rgb(249, 226, 175);

pub fn render(frame: &mut Frame, app: &App) {
    let area = frame.area();

    let vis = app.visible_containers();
    // Stack monolito + 3 sidecars — precisa de mais linhas visíveis na tabela
    let container_height = (vis.len() as u16 + 2).min(area.height / 2).max(3).max(8);
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(1),               // header + tabs
            Constraint::Length(container_height), // containers
            Constraint::Min(5),                  // logs
            Constraint::Length(1),               // footer
        ])
        .split(area);

    render_header(frame, app, chunks[0]);
    render_containers(frame, app, &vis, chunks[1]);
    render_logs(frame, app, chunks[2]);
    render_footer(frame, app, chunks[3]);

    // Menu overlay
    if matches!(app.mode, AppMode::Menu) {
        render_menu(frame, app, area);
    }
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let svc_style = if app.tab == Tab::Services { Style::default().fg(MAUVE).bold() } else { Style::default().fg(DIM) };
    let agents_style = if app.tab == Tab::Agents { Style::default().fg(MAUVE).bold() } else { Style::default().fg(DIM) };

    let svc_up = app
        .all_containers
        .iter()
        .filter(|c| c.kind != ContainerKind::Ide && c.kind != ContainerKind::SystemdService)
        .filter(|c| c.is_up)
        .count();
    let agents_up = app
        .all_containers
        .iter()
        .filter(|c| c.kind == ContainerKind::Ide)
        .filter(|c| c.is_up)
        .count();

    // Left: tabs
    let left_spans = vec![
        Span::styled(" deck ", Style::default().fg(MAUVE).bold()),
        Span::styled("│ ", Style::default().fg(DIM)),
        Span::styled(format!(" Services ({svc_up}) "), svc_style),
        Span::styled("│", Style::default().fg(DIM)),
        Span::styled(format!(" Agents ({agents_up}) "), agents_style),
    ];
    let left_line = Line::from(left_spans);

    // Right: systemd dots
    let systemd = app.systemd_containers();
    let mut dot_spans: Vec<Span> = vec![];
    for (i, c) in systemd.iter().enumerate() {
        if i > 0 {
            dot_spans.push(Span::styled("  ", Style::default()));
        }
        let color = if c.is_up { GREEN } else { RED };
        dot_spans.push(Span::styled("● ", Style::default().fg(color)));
        dot_spans.push(Span::styled(c.display_name.as_str(), Style::default().fg(DIM)));
    }
    dot_spans.push(Span::styled(" ", Style::default()));
    let right_line = Line::from(dot_spans).right_aligned();

    // Split area: left takes remaining, right is fixed width for dots
    let right_width = systemd.iter().map(|c| c.display_name.len() as u16 + 4).sum::<u16>().max(1);
    let chunks = Layout::horizontal([
        Constraint::Min(10),
        Constraint::Length(right_width),
    ])
    .flex(Flex::Legacy)
    .split(area);

    frame.render_widget(Paragraph::new(left_line), chunks[0]);
    frame.render_widget(Paragraph::new(right_line), chunks[1]);
}

/// Strip total from "31.62MB / 49.77GB" → "31.62MB".
fn mem_used_only(raw: &str) -> String {
    raw.split('/').next().unwrap_or(raw).trim().to_string()
}

fn render_containers(frame: &mut Frame, app: &App, vis: &[&super::app::ContainerInfo], area: Rect) {
    let rows: Vec<Row> = vis
        .iter()
        .enumerate()
        .map(|(i, c)| {
            let selected = i == app.cursor;
            let icon = if c.is_up { "●" } else { "○" };
            let icon_color = if c.is_up { GREEN } else { RED };
            let name = c.display_name.as_str();
            let cursor = if selected { "▸" } else { " " };

            let name_fg = if c.kind == ContainerKind::Sidecar {
                DIM
            } else {
                TEXT
            };
            let mut style = Style::default().fg(name_fg);
            if selected {
                style = style.bg(SURFACE);
            }

            let env_color = match c.env.as_str() {
                "prod"          => RED,
                "sand" | "sbox" => YELLOW,
                "local"         => GREEN,
                "qa"            => PEACH,
                "dbox" | "devb" => MAUVE,
                _               => DIM,
            };
            let vert_color = match c.vertical.as_str() {
                "med"  => MAUVE,
                "oab"  => GREEN,
                "conc" => PEACH,
                _      => DIM,
            };
            let env_display  = if c.env.is_empty() { "—".to_string() } else { c.env.clone() };
            let vert_display = if c.vertical.is_empty() { "—".to_string() } else { c.vertical.clone() };
            let mem_display = mem_used_only(&c.mem);
            let status_display = if !c.last_log.is_empty() {
                c.last_log.clone()
            } else {
                c.status.clone()
            };

            // Order: cursor icon name | flags | cpu mem | status
            Row::new(vec![
                Cell::from(Span::styled(cursor, Style::default().fg(MAUVE).bold())),
                Cell::from(Span::styled(icon, Style::default().fg(icon_color))),
                Cell::from(Span::styled(name, style.bold())),
                Cell::from(Span::styled(env_display, Style::default().fg(env_color))),
                Cell::from(Span::styled(vert_display, Style::default().fg(vert_color))),
                Cell::from(Span::styled(&c.cpu, Style::default().fg(PEACH))),
                Cell::from(Span::styled(mem_display, Style::default().fg(MAUVE))),
                Cell::from(Span::styled(status_display, Style::default().fg(DIM))),
            ])
            .style(style)
        })
        .collect();

    let widths = [
        Constraint::Length(1),   // cursor ▸
        Constraint::Length(2),   // status icon
        Constraint::Length(20),  // name (tree + sidecar label)
        Constraint::Length(5),   // env
        Constraint::Length(5),   // vertical
        Constraint::Length(8),   // cpu
        Constraint::Length(9),   // mem (used only)
        Constraint::Min(10),     // status (fills remaining)
    ];

    let tab_label = match app.tab {
        Tab::Agents => "Agents",
        Tab::Services => "Services",
    };
    let table = Table::new(rows, widths)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(Style::default().fg(DIM))
                .title(Span::styled(
                    format!(" {tab_label} "),
                    Style::default().fg(MAUVE).bold(),
                )),
        );

    frame.render_widget(table, area);
}

fn colorize_log_line(l: &str) -> Line<'_> {
    if l.contains("ERROR") || l.contains("error") || l.contains("ERRO")
        || l.contains("✗") || l.starts_with("Failed") || l.contains("failed to")
    {
        Line::from(Span::styled(l, Style::default().fg(RED)))
    } else if l.contains("WARN") || l.contains("warn") {
        Line::from(Span::styled(l, Style::default().fg(PEACH)))
    } else if l.starts_with('✔') || l.contains("Compiled successfully") || l.contains("pronto em") {
        Line::from(Span::styled(l, Style::default().fg(GREEN)))
    } else if l.starts_with('●') || l.contains('█') {
        Line::from(Span::styled(l, Style::default().fg(MAUVE)))
    } else {
        Line::from(Span::styled(l, Style::default().fg(DIM)))
    }
}

fn render_logs(frame: &mut Frame, app: &App, area: Rect) {
    let visible_height = area.height.saturating_sub(2) as usize;
    let len = app.logs.len();
    let start = app.log_scroll.min(len);
    let end = (start + visible_height).min(len);

    let lines: Vec<Line> = app.logs[start..end]
        .iter()
        .map(|l| colorize_log_line(l.as_str()))
        .collect();

    let selected_name = app
        .selected_container()
        .map(|c| {
            if c.kind == ContainerKind::Ide {
                format!("{} ({})", c.display_name, c.name)
            } else {
                c.display_name.clone()
            }
        })
        .unwrap_or_else(|| "none".into());

    let follow_span = if app.log_follow {
        Span::styled(" FOLLOW", Style::default().fg(GREEN).bold())
    } else {
        Span::styled(" PAUSED", Style::default().fg(DIM))
    };

    let title = Line::from(vec![
        Span::styled(
            format!(" {} [{}/{}]", selected_name, end, app.logs.len()),
            Style::default().fg(MAUVE).bold(),
        ),
        follow_span,
        Span::raw(" "),
    ]);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(DIM))
        .title(title);

    frame.render_widget(
        Paragraph::new(lines).wrap(Wrap { trim: false }).block(block),
        area,
    );

    // Scrollbar
    let mut scrollbar_state = ScrollbarState::new(len.saturating_sub(visible_height))
        .position(app.log_scroll);
    frame.render_stateful_widget(
        Scrollbar::new(ScrollbarOrientation::VerticalRight)
            .begin_symbol(None)
            .end_symbol(None),
        area,
        &mut scrollbar_state,
    );
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let hint = match app.mode {
        AppMode::Normal => "enter:menu  f:follow  q:quit",
        AppMode::Menu => "enter:exec  esc:back",
    };
    let mut parts = vec![];
    if app.subprocess_degraded {
        parts.push(Span::styled(
            " stale (podman/vennon timeout) ",
            Style::default().fg(PEACH).bold(),
        ));
    }
    parts.push(Span::styled(
        format!(" {hint}"),
        Style::default().fg(DIM),
    ));
    let left_line = Line::from(parts);

    if app.refresh_inflight {
        const SPINNER: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
        let spin = SPINNER[(app.spin_tick as usize) % SPINNER.len()];
        let chunks = Layout::horizontal([Constraint::Min(0), Constraint::Length(1)]).split(area);
        frame.render_widget(Paragraph::new(left_line), chunks[0]);
        frame.render_widget(
            Paragraph::new(Line::from(vec![Span::styled(
                spin,
                Style::default().fg(PEACH).bold(),
            )]))
            .alignment(Alignment::Right),
            chunks[1],
        );
    } else {
        frame.render_widget(Paragraph::new(left_line), area);
    }
}

fn render_menu(frame: &mut Frame, app: &App, area: Rect) {
    let container = match app.selected_container() {
        Some(c) => c,
        None => return,
    };
    let name = container.display_name.clone();
    let actions = app.menu_actions();

    let items: Vec<ListItem> = actions
        .iter()
        .enumerate()
        .map(|(i, label)| {
            // Group header: "# ENV", "# VERTICAL", etc.
            if let Some(header) = label.strip_prefix("# ") {
                return ListItem::new(format!(" ─ {header} ─"))
                    .style(Style::default().fg(MAUVE).bold());
            }
            let style = if i == app.menu_cursor {
                Style::default().fg(MAUVE).bold()
            } else if label.ends_with(" ✓") {
                Style::default().fg(GREEN)
            } else {
                Style::default().fg(TEXT)
            };
            let prefix = if i == app.menu_cursor { "▸ " } else { "  " };
            ListItem::new(format!("{prefix}{label}"))
                .style(style)
        })
        .collect();

    let menu_height = actions.len() as u16 + 2;
    let menu_width = 30;
    let x = area.width.saturating_sub(menu_width) / 2;
    let y = area.height.saturating_sub(menu_height) / 2;
    let menu_area = Rect::new(x, y, menu_width, menu_height);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(MAUVE))
        .title(Span::styled(
            format!(" {name} "),
            Style::default().fg(MAUVE).bold(),
        ));

    // Clear background
    frame.render_widget(Clear, menu_area);
    frame.render_widget(List::new(items).block(block), menu_area);
}
