use ratatui::style::{Color, Modifier, Style};

pub const MAGENTA: Color = Color::Magenta;
pub const GREEN: Color = Color::Green;
pub const RED: Color = Color::Red;
pub const YELLOW: Color = Color::Yellow;
pub const CYAN: Color = Color::Cyan;
pub const BLUE: Color = Color::Blue;
pub const ORANGE: Color = Color::Indexed(214);
pub const WHITE: Color = Color::White;
pub const GRAY: Color = Color::DarkGray;

pub fn header() -> Style {
    Style::default().fg(MAGENTA).add_modifier(Modifier::BOLD)
}

pub fn up_icon() -> Style {
    Style::default().fg(GREEN)
}

pub fn down_icon() -> Style {
    Style::default().fg(RED)
}

pub fn uptime() -> Style {
    Style::default().fg(ORANGE)
}

pub fn name() -> Style {
    Style::default().fg(WHITE)
}

pub fn cpu() -> Style {
    Style::default().fg(YELLOW)
}

pub fn mem() -> Style {
    Style::default().fg(CYAN)
}

pub fn dim() -> Style {
    Style::default().fg(GRAY)
}

pub fn group_label() -> Style {
    Style::default().fg(CYAN).add_modifier(Modifier::BOLD)
}

pub fn tree_branch() -> Style {
    Style::default().fg(BLUE)
}

pub fn mount_present() -> Style {
    Style::default().fg(GREEN)
}

pub fn mount_absent() -> Style {
    Style::default().fg(RED)
}

pub fn selected() -> Style {
    Style::default().fg(YELLOW).add_modifier(Modifier::BOLD)
}

pub fn footer_key() -> Style {
    Style::default().fg(GREEN)
}

pub fn footer_dim() -> Style {
    Style::default().fg(GRAY)
}
