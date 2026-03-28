//! Catppuccin Mocha color palette and reusable [`Style`] constructors for the TUI.

use ratatui::style::{Color, Modifier, Style};

// ── Catppuccin Mocha palette ─────────────────────────────────────────────────
pub const MAUVE: Color    = Color::Rgb(203, 166, 247); // headers / primary
pub const GREEN: Color    = Color::Rgb(166, 227, 161); // up / healthy
pub const RED: Color      = Color::Rgb(243, 139, 168); // down / error
pub const PEACH: Color    = Color::Rgb(250, 179, 135); // uptime
pub const YELLOW: Color   = Color::Rgb(249, 226, 175); // cpu metrics
pub const SKY: Color      = Color::Rgb(137, 220, 235); // mem metrics
pub const BLUE: Color     = Color::Rgb(137, 180, 250); // selected rows
pub const LAVENDER: Color = Color::Rgb(180, 190, 254); // group labels
pub const TEXT: Color     = Color::Rgb(205, 214, 244); // normal text
pub const OVERLAY0: Color = Color::Rgb(108, 112, 134); // dim / secondary
pub const SURFACE1: Color = Color::Rgb(69,  71,  90);  // tree branches / borders

// ── Style constructors ────────────────────────────────────────────────────────

pub fn header() -> Style {
    Style::default().fg(MAUVE).add_modifier(Modifier::BOLD)
}
pub fn up_icon() -> Style    { Style::default().fg(GREEN) }
pub fn down_icon() -> Style  { Style::default().fg(RED) }
pub fn uptime() -> Style     { Style::default().fg(PEACH) }
pub fn name() -> Style       { Style::default().fg(TEXT) }
pub fn cpu() -> Style        { Style::default().fg(YELLOW) }
pub fn mem() -> Style        { Style::default().fg(SKY) }
pub fn dim() -> Style        { Style::default().fg(OVERLAY0) }
pub fn separator() -> Style  { Style::default().fg(SURFACE1) }

pub fn group_label() -> Style {
    Style::default().fg(LAVENDER).add_modifier(Modifier::BOLD)
}
pub fn tree_branch() -> Style { Style::default().fg(SURFACE1) }
pub fn selected() -> Style {
    Style::default().fg(BLUE).add_modifier(Modifier::BOLD)
}
pub fn footer_key() -> Style  { Style::default().fg(GREEN) }
pub fn footer_dim() -> Style  { Style::default().fg(OVERLAY0) }
pub fn pending_icon() -> Style { Style::default().fg(YELLOW) }
pub fn pending_label() -> Style { Style::default().fg(OVERLAY0) }

/// Quota percentage colour: red ≥ 85%, yellow ≥ 70%, green otherwise.
pub fn pct_color(pct: u8) -> Style {
    if pct >= 85 {
        Style::default().fg(RED)
    } else if pct >= 70 {
        Style::default().fg(YELLOW)
    } else {
        Style::default().fg(GREEN)
    }
}
