use ratatui::prelude::*;
use ratatui::widgets::*;

use super::app::{App, AppMode, ContainerKind, Tab};

// ── Colors ──────────────────────────────────────────────────────
const GREEN: Color = Color::Rgb(166, 227, 161);
const RED: Color = Color::Rgb(243, 139, 168);
const MAUVE: Color = Color::Rgb(203, 166, 247);
const PEACH: Color = Color::Rgb(250, 179, 135);
const TEXT: Color = Color::Rgb(205, 214, 244);
const DIM: Color = Color::Rgb(108, 112, 134);
const SURFACE: Color = Color::Rgb(30, 30, 46);

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
    let ide_style = if app.tab == Tab::Ide { Style::default().fg(MAUVE).bold() } else { Style::default().fg(DIM) };
    let svc_style = if app.tab == Tab::Services { Style::default().fg(MAUVE).bold() } else { Style::default().fg(DIM) };

    let ide_up = app
        .all_containers
        .iter()
        .filter(|c| c.kind == ContainerKind::Ide)
        .filter(|c| c.is_up)
        .count();
    let svc_up = app
        .all_containers
        .iter()
        .filter(|c| c.kind != ContainerKind::Ide)
        .filter(|c| c.is_up)
        .count();

    let text = Line::from(vec![
        Span::styled(" deck ", Style::default().fg(MAUVE).bold()),
        Span::styled("│ ", Style::default().fg(DIM)),
        Span::styled(format!(" IDE ({ide_up}) "), ide_style),
        Span::styled("│", Style::default().fg(DIM)),
        Span::styled(format!(" Services ({svc_up}) "), svc_style),
        Span::styled("│ ", Style::default().fg(DIM)),
        Span::styled("tab:switch", Style::default().fg(DIM)),
    ]);
    frame.render_widget(Paragraph::new(text), area);
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

            Row::new(vec![
                Cell::from(Span::styled(cursor, Style::default().fg(MAUVE).bold())),
                Cell::from(Span::styled(icon, Style::default().fg(icon_color))),
                Cell::from(Span::styled(name, style.bold())),
                Cell::from(Span::styled(&c.status, Style::default().fg(DIM))),
                Cell::from(Span::styled(&c.cpu, Style::default().fg(PEACH))),
                Cell::from(Span::styled(&c.mem, Style::default().fg(MAUVE))),
            ])
            .style(style)
        })
        .collect();

    let widths = [
        Constraint::Length(2),   // cursor ▸
        Constraint::Length(2),   // status icon
        Constraint::Length(28),  // name (tree + sidecar label)
        Constraint::Length(20),  // status text
        Constraint::Length(10),  // cpu
        Constraint::Min(15),    // mem
    ];

    let tab_label = match app.tab {
        Tab::Ide => "IDE",
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

fn render_logs(frame: &mut Frame, app: &App, area: Rect) {
    let visible_height = area.height.saturating_sub(2) as usize;
    let len = app.logs.len();
    let start = app.log_scroll.min(len);
    let end = (start + visible_height).min(len);

    let lines: Vec<Line> = app.logs[start..end]
        .iter()
        .map(|l| {
            // Color by prefix
            if l.contains("ERROR") || l.contains("error") || l.contains("ERRO") {
                Line::from(Span::styled(l.as_str(), Style::default().fg(RED)))
            } else if l.contains("WARN") || l.contains("warn") {
                Line::from(Span::styled(l.as_str(), Style::default().fg(PEACH)))
            } else {
                Line::from(Span::styled(l.as_str(), Style::default().fg(DIM)))
            }
        })
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

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(DIM))
        .title(Span::styled(
            format!(" {} [{}/{}] ", selected_name, end, app.logs.len()),
            Style::default().fg(MAUVE).bold(),
        ));

    frame.render_widget(Paragraph::new(lines).block(block), area);
}

fn render_footer(frame: &mut Frame, app: &App, area: Rect) {
    let hint = match app.mode {
        AppMode::Normal => "j/k:nav  enter:menu  tab:switch  r:refresh  [/]:scroll  q:quit",
        AppMode::Menu => "j/k:nav  enter:exec  esc:back",
    };
    let count = app.all_containers.iter().filter(|c| c.is_up).count();
    let total = app.all_containers.len();

    let mut parts = vec![Span::styled(
        format!(" {count}/{total} up "),
        Style::default().fg(GREEN).bold(),
    )];
    if app.refresh_inflight {
        parts.push(Span::styled(
            "refreshing… ",
            Style::default().fg(PEACH).bold(),
        ));
    } else if app.subprocess_degraded {
        parts.push(Span::styled(
            "stale (podman/vennon timeout) ",
            Style::default().fg(PEACH).bold(),
        ));
    }
    parts.push(Span::styled(hint, Style::default().fg(DIM)));
    let text = Line::from(parts);
    frame.render_widget(Paragraph::new(text), area);
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
            let style = if i == app.menu_cursor {
                Style::default().fg(MAUVE).bold()
            } else {
                Style::default().fg(TEXT)
            };
            let prefix = if i == app.menu_cursor { "▸ " } else { "  " };
            ListItem::new(format!("{prefix}{label}"))
                .style(style)
        })
        .collect();

    let menu_height = actions.len() as u16 + 2;
    let menu_width = 20;
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
