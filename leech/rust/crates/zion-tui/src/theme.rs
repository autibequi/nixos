//! Color palette and reusable [`Style`] constructors for the TUI.

use ratatui::style::{Color, Modifier, Style};

/// Cyberpunk magenta — used for primary headers.
pub const MAGENTA: Color = Color::Magenta;
/// Green — indicates a running / healthy state.
pub const GREEN: Color = Color::Green;
/// Red — indicates a stopped / error state.
pub const RED: Color = Color::Red;
/// Yellow — used for CPU metrics and selected items.
pub const YELLOW: Color = Color::Yellow;
/// Cyan — used for memory metrics and group labels.
pub const CYAN: Color = Color::Cyan;
/// Blue — used for tree branch decorations.
pub const BLUE: Color = Color::Blue;
/// Orange (256-colour index 214) — used for uptime values.
pub const ORANGE: Color = Color::Indexed(214);
/// White — default text colour for service names.
pub const WHITE: Color = Color::White;
/// Dark gray — used for dim / secondary text.
pub const GRAY: Color = Color::DarkGray;

/// Bold magenta header style.
pub fn header() -> Style {
    Style::default().fg(MAGENTA).add_modifier(Modifier::BOLD)
}

/// Green style for "up" status icons.
pub fn up_icon() -> Style {
    Style::default().fg(GREEN)
}

/// Red style for "down" status icons.
pub fn down_icon() -> Style {
    Style::default().fg(RED)
}

/// Orange style for uptime values.
pub fn uptime() -> Style {
    Style::default().fg(ORANGE)
}

/// White style for service/session names.
pub fn name() -> Style {
    Style::default().fg(WHITE)
}

/// Yellow style for CPU metric values.
pub fn cpu() -> Style {
    Style::default().fg(YELLOW)
}

/// Cyan style for memory metric values.
pub fn mem() -> Style {
    Style::default().fg(CYAN)
}

/// Dark-gray style for secondary / decorative text.
pub fn dim() -> Style {
    Style::default().fg(GRAY)
}

/// Bold cyan style for group labels.
pub fn group_label() -> Style {
    Style::default().fg(CYAN).add_modifier(Modifier::BOLD)
}

/// Blue style for tree-branch characters.
pub fn tree_branch() -> Style {
    Style::default().fg(BLUE)
}

/// Green style for a mount that is present.
pub fn mount_present() -> Style {
    Style::default().fg(GREEN)
}

/// Red style for a mount that is absent.
pub fn mount_absent() -> Style {
    Style::default().fg(RED)
}

/// Bold yellow style for the currently selected row.
pub fn selected() -> Style {
    Style::default().fg(YELLOW).add_modifier(Modifier::BOLD)
}

/// Green style for footer key hints.
pub fn footer_key() -> Style {
    Style::default().fg(GREEN)
}

/// Dark-gray style for footer description text.
pub fn footer_dim() -> Style {
    Style::default().fg(GRAY)
}

/// Yellow style for a pending / transitioning state icon.
pub fn pending_icon() -> Style {
    Style::default().fg(YELLOW)
}

/// Dark-gray style for a pending action label.
pub fn pending_label() -> Style {
    Style::default().fg(GRAY)
}
