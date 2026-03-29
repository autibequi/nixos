use ratatui::prelude::*;
use ratatui::widgets::ScrollbarOrientation;
use ratatui::widgets::*;

use super::app::{App, AppMode, ContainerKind, Tab};
use chrono::Local;
use ratatui::layout::Flex;

const REFRESH_SPINNER: &[&str] = &["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

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
            Constraint::Length(1),                // header + tabs
            Constraint::Length(container_height), // containers
            Constraint::Min(5),                   // logs (full remaining height)
        ])
        .split(area);

    render_header(frame, app, chunks[0]);
    render_containers(frame, app, &vis, chunks[1]);
    render_logs(frame, app, chunks[2]);

    // Menu overlay
    if matches!(app.mode, AppMode::Menu) {
        render_menu(frame, app, area);
    }
    if matches!(app.mode, AppMode::Help) {
        render_help(frame, area);
    }
}

fn render_header(frame: &mut Frame, app: &App, area: Rect) {
    let svc_style = if app.tab == Tab::Services {
        Style::default().fg(MAUVE).bold()
    } else {
        Style::default().fg(DIM)
    };
    let agents_style = if app.tab == Tab::Agents {
        Style::default().fg(MAUVE).bold()
    } else {
        Style::default().fg(DIM)
    };

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

    // Left: tabs + resource summary (visible tab, containers up)
    let summary = visible_resource_summary(app);
    let left_spans = vec![
        Span::styled(" deck ", Style::default().fg(MAUVE).bold()),
        Span::styled("│ ", Style::default().fg(DIM)),
        Span::styled(format!(" Services ({svc_up}) "), svc_style),
        Span::styled("│", Style::default().fg(DIM)),
        Span::styled(format!(" Agents ({agents_up}) "), agents_style),
        Span::styled(" │ ", Style::default().fg(DIM)),
        Span::styled(summary, Style::default().fg(DIM)),
    ];
    let left_line = Line::from(left_spans);

    // Right: largura fixa (relógio + dots). Esquerda = todo o resto — senão `Min+Min` esmaga as abas.
    let right_line = header_right_line(app);
    let right_w = header_right_column_width(app);

    let chunks = Layout::horizontal([Constraint::Min(10), Constraint::Length(right_w)])
        .flex(Flex::Legacy)
        .split(area);

    frame.render_widget(Paragraph::new(left_line), chunks[0]);
    frame.render_widget(
        Paragraph::new(right_line).alignment(Alignment::Right),
        chunks[1],
    );
}

/// Largura em colunas do bloco direito do header (deve bater com `header_right_line`).
fn header_right_column_width(app: &App) -> u16 {
    let mut w: u16 = 0;
    if app.subprocess_degraded {
        w += 6; // "stale "
    }
    w += 1; // spinner ou espaço
    w += 1; // espaço antes do horário
    w += 8; // HH:MM:SS ou --:--:--
    w += 2; // "  " antes das bolinhas
    let systemd = app.systemd_containers();
    for (i, c) in systemd.iter().enumerate() {
        if i > 0 {
            w += 2;
        }
        w += 2; // "● "
        w += c.display_name.len() as u16;
    }
    w += 1; // espaço final
    w.max(12)
}

/// `stale?` + spinner + horário · `● buzz` `● tick` (ordem visual: hora antes das bolinhas).
fn header_right_line(app: &App) -> Line<'_> {
    let mut spans: Vec<Span<'_>> = Vec::new();
    if app.subprocess_degraded {
        spans.push(Span::styled("stale ", Style::default().fg(PEACH).bold()));
    }
    if app.refresh_inflight {
        let spin = REFRESH_SPINNER[(app.spin_tick as usize) % REFRESH_SPINNER.len()];
        spans.push(Span::styled(spin, Style::default().fg(PEACH).bold()));
    } else {
        spans.push(Span::styled(" ", Style::default().fg(DIM)));
    }
    spans.push(Span::raw(" "));
    let time_str: String = app
        .last_refresh
        .map(|t| t.with_timezone(&Local).format("%H:%M:%S").to_string())
        .unwrap_or_else(|| "--:--:--".into());
    spans.push(Span::styled(time_str, Style::default().fg(DIM)));
    spans.push(Span::raw("  "));

    let systemd = app.systemd_containers();
    for (i, c) in systemd.iter().enumerate() {
        if i > 0 {
            spans.push(Span::styled("  ", Style::default()));
        }
        let color = if c.is_up { GREEN } else { RED };
        spans.push(Span::styled("● ", Style::default().fg(color)));
        spans.push(Span::styled(
            c.display_name.as_str(),
            Style::default().fg(DIM),
        ));
    }
    spans.push(Span::styled(" ", Style::default()));
    Line::from(spans)
}

/// Strip total from "31.62MB / 49.77GB" → "31.62MB".
fn mem_used_only(raw: &str) -> String {
    raw.split('/').next().unwrap_or(raw).trim().to_string()
}

fn parse_cpu_percent(s: &str) -> Option<f64> {
    let s = s.trim();
    if s.is_empty() {
        return None;
    }
    s.trim_end_matches('%').trim().parse().ok()
}

fn parse_mem_used_bytes(raw: &str) -> Option<u64> {
    let part = raw.split('/').next()?.trim();
    if part.is_empty() {
        return None;
    }
    let mut i = 0;
    let b = part.as_bytes();
    while i < b.len() && (b[i].is_ascii_digit() || b[i] == b'.') {
        i += 1;
    }
    if i == 0 {
        return None;
    }
    let num: f64 = part[..i].parse().ok()?;
    let suf = part[i..].trim().to_ascii_lowercase();
    let mult: f64 = match suf.as_str() {
        "b" => 1.0,
        "kb" | "kib" => 1024.0,
        // podman often prints "MB"/"GB" (decimal SI); treat like MiB/GiB for totals
        "mb" | "mib" => 1024_f64.powi(2),
        "gb" | "gib" => 1024_f64.powi(3),
        "tb" | "tib" => 1024_f64.powi(4),
        "" => return None,
        _ => return None,
    };
    Some((num * mult) as u64)
}

fn format_bytes_short(n: u64) -> String {
    const KB: f64 = 1024.0;
    const MB: f64 = KB * 1024.0;
    const GB: f64 = MB * 1024.0;
    let x = n as f64;
    if x >= GB {
        format!("{:.1} GiB", x / GB)
    } else if x >= MB {
        format!("{:.1} MiB", x / MB)
    } else if x >= KB {
        format!("{:.0} KiB", x / KB)
    } else {
        format!("{n} B")
    }
}

/// Sum CPU% and memory for visible rows that are up (same scope as the table).
fn visible_resource_summary(app: &App) -> String {
    let vis = app.visible_containers();
    let mut cpu_sum = 0.0;
    let mut mem_sum: u64 = 0;
    let mut n_cpu = 0usize;
    let mut n_mem = 0usize;
    for c in vis {
        if !c.is_up {
            continue;
        }
        if let Some(p) = parse_cpu_percent(&c.cpu) {
            cpu_sum += p;
            n_cpu += 1;
        }
        if let Some(b) = parse_mem_used_bytes(&c.mem) {
            mem_sum += b;
            n_mem += 1;
        }
    }
    if n_cpu == 0 && n_mem == 0 {
        return "Σ —".to_string();
    }
    let mut parts: Vec<String> = Vec::new();
    if n_cpu > 0 {
        parts.push(format!("{:.1}% CPU", cpu_sum));
    }
    if n_mem > 0 {
        parts.push(format_bytes_short(mem_sum));
    }
    format!("Σ {}", parts.join(" · "))
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
                "prod" => RED,
                "sand" | "sbox" => YELLOW,
                "local" => GREEN,
                "qa" => PEACH,
                "dbox" | "devb" => MAUVE,
                _ => DIM,
            };
            let vert_color = match c.vertical.as_str() {
                "med" => MAUVE,
                "oab" => GREEN,
                "conc" => PEACH,
                _ => DIM,
            };
            let env_display = if c.env.is_empty() {
                "—".to_string()
            } else {
                c.env.clone()
            };
            let vert_display = if c.vertical.is_empty() {
                "—".to_string()
            } else {
                c.vertical.clone()
            };
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
        Constraint::Length(1),  // cursor ▸
        Constraint::Length(2),  // status icon
        Constraint::Length(20), // name (tree + sidecar label)
        Constraint::Length(5),  // env
        Constraint::Length(5),  // vertical
        Constraint::Length(8),  // cpu
        Constraint::Length(9),  // mem (used only)
        Constraint::Min(10),    // status (fills remaining)
    ];

    let tab_label = match app.tab {
        Tab::Agents => "Agents",
        Tab::Services => "Services",
    };
    let table = Table::new(rows, widths).block(
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
    if l.contains("ERROR")
        || l.contains("error")
        || l.contains("ERRO")
        || l.contains("✗")
        || l.starts_with("Failed")
        || l.contains("failed to")
    {
        Line::from(Span::styled(l, Style::default().fg(RED)))
    } else if l.contains("WARN") || l.contains("warn") {
        Line::from(Span::styled(l, Style::default().fg(PEACH)))
    } else if l.starts_with('✔') || l.contains("Compiled successfully") || l.contains("pronto em")
    {
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
        Paragraph::new(lines)
            .wrap(Wrap { trim: false })
            .block(block),
        area,
    );

    // Scrollbar
    let mut scrollbar_state =
        ScrollbarState::new(len.saturating_sub(visible_height)).position(app.log_scroll);
    frame.render_stateful_widget(
        Scrollbar::new(ScrollbarOrientation::VerticalRight)
            .begin_symbol(None)
            .end_symbol(None),
        area,
        &mut scrollbar_state,
    );
}

fn render_help(frame: &mut Frame, area: Rect) {
    let lines = vec![
        Line::from(""),
        Line::from(vec![Span::styled(
            " Atalhos ",
            Style::default().fg(MAUVE).bold(),
        )]),
        Line::from(""),
        Line::from(vec![
            Span::styled("j / k / ", Style::default().fg(PEACH)),
            Span::styled("↑ / ↓", Style::default().fg(PEACH)),
            Span::styled("     navegar na lista", Style::default().fg(DIM)),
        ]),
        Line::from(vec![
            Span::styled("Enter", Style::default().fg(PEACH)),
            Span::styled("            menu de ações", Style::default().fg(DIM)),
        ]),
        Line::from(vec![
            Span::styled("Tab", Style::default().fg(PEACH)),
            Span::styled(
                "              alternar Services ↔ Agents",
                Style::default().fg(DIM),
            ),
        ]),
        Line::from(vec![
            Span::styled("r", Style::default().fg(PEACH)),
            Span::styled("                atualizar dados", Style::default().fg(DIM)),
        ]),
        Line::from(vec![
            Span::styled("f", Style::default().fg(PEACH)),
            Span::styled(
                "                follow / pausar logs",
                Style::default().fg(DIM),
            ),
        ]),
        Line::from(vec![
            Span::styled("[ ]", Style::default().fg(PEACH)),
            Span::styled("              rolar logs", Style::default().fg(DIM)),
        ]),
        Line::from(vec![
            Span::styled("q / Esc", Style::default().fg(PEACH)),
            Span::styled("         sair (ou voltar)", Style::default().fg(DIM)),
        ]),
        Line::from(vec![
            Span::styled("?", Style::default().fg(PEACH)),
            Span::styled("                esta ajuda", Style::default().fg(DIM)),
        ]),
        Line::from(""),
        Line::from(vec![Span::styled(
            " Esc  ou  q  fecha esta tela ",
            Style::default().fg(DIM),
        )]),
    ];

    let h = lines.len() as u16 + 2;
    let w = 52u16.min(area.width.saturating_sub(2)).max(42);
    let h = h.min(area.height.saturating_sub(2));
    let x = area.x + area.width.saturating_sub(w) / 2;
    let y = area.y + area.height.saturating_sub(h) / 2;
    let help_area = Rect::new(x, y, w, h);

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(Style::default().fg(MAUVE))
        .title(Span::styled(" ajuda ", Style::default().fg(MAUVE).bold()));

    frame.render_widget(Clear, help_area);
    frame.render_widget(Paragraph::new(lines).block(block), help_area);
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
            ListItem::new(format!("{prefix}{label}")).style(style)
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
