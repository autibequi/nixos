//! Claude API quota — parses the output of `claude-oauth-usage.sh`.

/// API usage snapshot with bar-ready percentages.
#[derive(Debug, Clone, Default)]
pub struct QuotaInfo {
    /// Usage percentage for the last 5 hours (0–100).
    pub pct_5h: u8,
    /// Usage percentage for the last 7 days (0–100).
    pub pct_7d: u8,
    /// Raw text from the usage script (fallback display).
    pub raw: String,
}

/// Run the usage script and parse its output.
///
/// Expected script output (last two lines):
/// ```text
///   Claude OAuth  5h: ━━━━────── 44%  7d: ━━━━━━━━━━──────────── 49%  ex: 100%
/// ```
#[must_use]
pub fn collect(script_path: &std::path::Path) -> QuotaInfo {
    let output = std::process::Command::new(script_path)
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default();

    let raw = output.trim().to_string();
    let (pct_5h, pct_7d) = parse_percentages(&raw);
    QuotaInfo { pct_5h, pct_7d, raw }
}

/// Parse `44%` and `49%` from the script output line.
fn parse_percentages(text: &str) -> (u8, u8) {
    // Look for patterns like "5h: ... 44%  7d: ... 49%"
    let mut pct_5h = 0u8;
    let mut pct_7d = 0u8;

    for line in text.lines() {
        if line.contains("5h:") && line.contains("7d:") {
            let parts: Vec<&str> = line.split_whitespace().collect();
            let mut after_5h = false;
            let mut after_7d = false;
            for token in &parts {
                if *token == "5h:" {
                    after_5h = true;
                    after_7d = false;
                    continue;
                }
                if *token == "7d:" {
                    after_7d = true;
                    after_5h = false;
                    continue;
                }
                if after_5h {
                    if let Some(n) = parse_pct(token) {
                        pct_5h = n;
                        after_5h = false;
                    }
                }
                if after_7d {
                    if let Some(n) = parse_pct(token) {
                        pct_7d = n;
                        after_7d = false;
                    }
                }
            }
        }
    }

    (pct_5h, pct_7d)
}

fn parse_pct(s: &str) -> Option<u8> {
    s.trim_end_matches('%').parse::<u8>().ok()
}

/// Build an ASCII progress bar.
///
/// `width` is the total number of block characters.
#[must_use]
pub fn bar(pct: u8, width: usize) -> String {
    let filled = (pct as usize * width) / 100;
    let empty = width.saturating_sub(filled);
    format!("{}{}", "█".repeat(filled), "░".repeat(empty))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_basic() {
        let line = "  Claude OAuth  5h: ━━━━────── 44%  7d: ━━━━━━━━━━──────────── 49%  ex: 100%";
        let (a, b) = parse_percentages(line);
        assert_eq!(a, 44);
        assert_eq!(b, 49);
    }

    #[test]
    fn bar_half() {
        assert_eq!(bar(50, 10), "█████░░░░░");
    }

    #[test]
    fn bar_full() {
        assert_eq!(bar(100, 10), "██████████");
    }

    #[test]
    fn bar_empty() {
        assert_eq!(bar(0, 10), "░░░░░░░░░░");
    }
}
