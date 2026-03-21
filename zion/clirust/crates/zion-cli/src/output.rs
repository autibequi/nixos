#[allow(dead_code)]
pub const RESET: &str = "\x1b[0m";
#[allow(dead_code)]
pub const BOLD: &str = "\x1b[1m";
#[allow(dead_code)]
pub const DIM: &str = "\x1b[2m";
#[allow(dead_code)]
pub const GREEN: &str = "\x1b[32m";
#[allow(dead_code)]
pub const RED: &str = "\x1b[31m";
#[allow(dead_code)]
pub const YELLOW: &str = "\x1b[33m";
#[allow(dead_code)]
pub const CYAN: &str = "\x1b[36m";
#[allow(dead_code)]
pub const MAGENTA: &str = "\x1b[35m";

#[allow(dead_code)]
pub fn error(msg: &str) {
    eprintln!("{RED}error:{RESET} {msg}");
}

#[allow(dead_code)]
pub fn warn(msg: &str) {
    eprintln!("{YELLOW}warn:{RESET} {msg}");
}
