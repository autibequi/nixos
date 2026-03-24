//! Logs panel — scrollable, ANSI-colored, with Block border and position indicator.

use ratatui::layout::Rect;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph, Scrollbar, ScrollbarOrientation, ScrollbarState};
use ratatui::Frame;
use ratatui::layout::Alignment;

use crate::app::App;
use crate::theme;

/// Render the logs panel for the currently selected service.
pub fn render(frame: &mut Frame, app: &App, area: Rect) {
    let svc = app.current_service();

    let entries: Vec<&leech_cli::logs::LogEntry> = app
        .snapshot
        .logs
        .iter()
        .filter(|e| e.service == svc)
        .collect();

    let total = entries.len();
    let scroll = app.log_scroll.min(total.saturating_sub(1));

    // ── Block with top border only (acts as the separator line) ───────────────
    let pos_label = if total > 0 {
        format!(" {}/{} ", total - scroll, total)
    } else {
        String::new()
    };
    let title = format!(" Logs [{}]{}", svc, if scroll > 0 { format!(" +{scroll}") } else { String::new() });

    let block = Block::default()
        .borders(Borders::TOP)
        .title(title)
        .title_style(theme::dim())
        .border_style(theme::separator());

    // Right-aligned position indicator via title_top (ratatui 0.29 API)
    let block = if !pos_label.is_empty() {
        block.title_top(
            Line::from(Span::styled(pos_label, theme::dim()))
                .alignment(Alignment::Right),
        )
    } else {
        block
    };

    let inner = block.inner(area);
    frame.render_widget(block, area);

    if entries.is_empty() {
        frame.render_widget(
            Paragraph::new(Line::from(vec![
                Span::raw("  "),
                Span::styled("no logs", theme::dim()),
            ])),
            inner,
        );
        return;
    }

    let max_lines = inner.height as usize;
    let end   = total.saturating_sub(scroll);
    let start = end.saturating_sub(max_lines);

    let lines: Vec<Line> = entries[start..end]
        .iter()
        .map(|entry| {
            let mut spans: Vec<Span> = vec![Span::raw("  ")];
            spans.extend(parse_ansi(&entry.line));
            Line::from(spans)
        })
        .collect();

    frame.render_widget(Paragraph::new(lines), inner);

    // Scrollbar on the right edge of the inner area
    if total > max_lines {
        let mut scrollbar_state = ScrollbarState::new(total.saturating_sub(max_lines))
            .position(total.saturating_sub(max_lines).saturating_sub(scroll));
        frame.render_stateful_widget(
            Scrollbar::new(ScrollbarOrientation::VerticalRight)
                .style(theme::dim()),
            inner,
            &mut scrollbar_state,
        );
    }
}

// ── ANSI parser ───────────────────────────────────────────────────────────────

/// Convert a string containing ANSI SGR escape sequences into a `Vec<Span>`.
/// Unknown / unsupported sequences are stripped silently.
fn parse_ansi(input: &str) -> Vec<Span<'static>> {
    let mut spans: Vec<Span<'static>> = Vec::new();
    let mut style = Style::default();
    let mut text_buf = String::new();
    let bytes = input.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        // Detect ESC [ (CSI)
        if bytes[i] == 0x1b && i + 1 < bytes.len() && bytes[i + 1] == b'[' {
            // Flush accumulated plain text
            if !text_buf.is_empty() {
                spans.push(Span::styled(std::mem::take(&mut text_buf), style));
            }
            // Scan to final byte (0x40–0x7e)
            let seq_start = i + 2;
            let mut j = seq_start;
            while j < bytes.len() && !(0x40..=0x7e).contains(&bytes[j]) {
                j += 1;
            }
            // Only handle 'm' (SGR)
            if j < bytes.len() && bytes[j] == b'm' {
                let params = &input[seq_start..j];
                style = apply_sgr(style, params);
            }
            i = j + 1;
        } else {
            // Regular character — push to buffer
            // Safety: we stay on valid UTF-8 boundaries by only splitting at ESC
            let ch = input[i..].chars().next().unwrap_or('\0');
            text_buf.push(ch);
            i += ch.len_utf8();
        }
    }

    if !text_buf.is_empty() {
        spans.push(Span::styled(text_buf, style));
    }

    // Fallback: if no ANSI codes were found, apply level-based color
    if spans.len() == 1 && spans[0].style == Style::default() {
        let line = spans[0].content.to_string();
        let level_style = detect_level_style(&line);
        spans[0] = Span::styled(line, level_style);
    }

    spans
}

/// Apply SGR (Select Graphic Rendition) parameters to a base `Style`.
fn apply_sgr(mut style: Style, params: &str) -> Style {
    if params.is_empty() {
        return Style::default();
    }

    let codes: Vec<&str> = params.split(';').collect();
    let mut i = 0;

    while i < codes.len() {
        match codes[i].trim() {
            "0" | "" => style = Style::default(),
            "1"  => style = style.add_modifier(Modifier::BOLD),
            "2"  => style = style.add_modifier(Modifier::DIM),
            "3"  => style = style.add_modifier(Modifier::ITALIC),
            "4"  => style = style.add_modifier(Modifier::UNDERLINED),
            "22" => style = style.remove_modifier(Modifier::BOLD),
            "23" => style = style.remove_modifier(Modifier::ITALIC),
            "24" => style = style.remove_modifier(Modifier::UNDERLINED),

            // Standard foreground colors (30–37)
            "30" => style = style.fg(Color::Black),
            "31" => style = style.fg(Color::Red),
            "32" => style = style.fg(Color::Green),
            "33" => style = style.fg(Color::Yellow),
            "34" => style = style.fg(Color::Blue),
            "35" => style = style.fg(Color::Magenta),
            "36" => style = style.fg(Color::Cyan),
            "37" => style = style.fg(Color::White),
            "39" => style = style.fg(Color::Reset),

            // Bright foreground colors (90–97)
            "90" => style = style.fg(Color::DarkGray),
            "91" => style = style.fg(Color::LightRed),
            "92" => style = style.fg(Color::LightGreen),
            "93" => style = style.fg(Color::LightYellow),
            "94" => style = style.fg(Color::LightBlue),
            "95" => style = style.fg(Color::LightMagenta),
            "96" => style = style.fg(Color::LightCyan),
            "97" => style = style.fg(Color::White),

            // Standard background colors (40–47)
            "40" => style = style.bg(Color::Black),
            "41" => style = style.bg(Color::Red),
            "42" => style = style.bg(Color::Green),
            "43" => style = style.bg(Color::Yellow),
            "44" => style = style.bg(Color::Blue),
            "45" => style = style.bg(Color::Magenta),
            "46" => style = style.bg(Color::Cyan),
            "47" => style = style.bg(Color::White),
            "49" => style = style.bg(Color::Reset),

            // Extended foreground: 38;2;R;G;B  or  38;5;N
            "38" => {
                if i + 2 < codes.len() && codes[i + 1].trim() == "5" {
                    if let Ok(n) = codes[i + 2].trim().parse::<u8>() {
                        style = style.fg(Color::Indexed(n));
                    }
                    i += 2;
                } else if i + 4 < codes.len() && codes[i + 1].trim() == "2" {
                    let r = codes[i + 2].trim().parse::<u8>().unwrap_or(0);
                    let g = codes[i + 3].trim().parse::<u8>().unwrap_or(0);
                    let b = codes[i + 4].trim().parse::<u8>().unwrap_or(0);
                    style = style.fg(Color::Rgb(r, g, b));
                    i += 4;
                }
            }

            // Extended background: 48;2;R;G;B  or  48;5;N
            "48" => {
                if i + 2 < codes.len() && codes[i + 1].trim() == "5" {
                    if let Ok(n) = codes[i + 2].trim().parse::<u8>() {
                        style = style.bg(Color::Indexed(n));
                    }
                    i += 2;
                } else if i + 4 < codes.len() && codes[i + 1].trim() == "2" {
                    let r = codes[i + 2].trim().parse::<u8>().unwrap_or(0);
                    let g = codes[i + 3].trim().parse::<u8>().unwrap_or(0);
                    let b = codes[i + 4].trim().parse::<u8>().unwrap_or(0);
                    style = style.bg(Color::Rgb(r, g, b));
                    i += 4;
                }
            }

            _ => {}
        }
        i += 1;
    }

    style
}

/// Fallback level detection when no ANSI codes are present.
fn detect_level_style(line: &str) -> Style {
    let upper = line.to_uppercase();
    if upper.contains("ERROR") || upper.contains("FATAL") || upper.contains("CRIT") {
        Style::default().fg(Color::Rgb(243, 139, 168)) // Catppuccin Red
    } else if upper.contains("WARN") {
        Style::default().fg(Color::Rgb(249, 226, 175)) // Catppuccin Yellow
    } else if upper.contains("DEBUG") || upper.contains("TRACE") {
        Style::default().fg(Color::Rgb(108, 112, 134)) // Catppuccin Overlay0
    } else {
        Style::default().fg(Color::Rgb(166, 173, 200)) // Catppuccin Subtext1
    }
}
