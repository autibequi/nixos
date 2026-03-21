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
///
/// Handles both formats:
/// - `󱙺 5h:44% 7d:49% ex:100%`  (compact, actual output)
/// - `5h: ━━━━ 44%  7d: ━━━━ 49%`  (spaced, older format)
fn parse_percentages(text: &str) -> (u8, u8) {
    let mut pct_5h = 0u8;
    let mut pct_7d = 0u8;

    for line in text.lines() {
        if !line.contains("5h:") || !line.contains("7d:") {
            continue;
        }

        // Try compact format: `5h:44%`
        for token in line.split_whitespace() {
            if let Some(rest) = token.strip_prefix("5h:") {
                if let Some(n) = parse_pct(rest) {
                    pct_5h = n;
                }
            } else if let Some(rest) = token.strip_prefix("7d:") {
                if let Some(n) = parse_pct(rest) {
                    pct_7d = n;
                }
            }
        }

        // If compact didn't work, try spaced format: `5h:` then next token with `%`
        if pct_5h == 0 && pct_7d == 0 {
            let parts: Vec<&str> = line.split_whitespace().collect();
            let mut after_5h = false;
            let mut after_7d = false;
            for token in &parts {
                match *token {
                    "5h:" => { after_5h = true; after_7d = false; }
                    "7d:" => { after_7d = true; after_5h = false; }
                    t if after_5h => {
                        if let Some(n) = parse_pct(t) { pct_5h = n; after_5h = false; }
                    }
                    t if after_7d => {
                        if let Some(n) = parse_pct(t) { pct_7d = n; after_7d = false; }
                    }
                    _ => {}
                }
            }
        }

        if pct_5h > 0 || pct_7d > 0 {
            break;
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
    fn parse_compact() {
        let line = "󱙺 5h:44% 7d:49% ex:100%";
        let (a, b) = parse_percentages(line);
        assert_eq!(a, 44);
        assert_eq!(b, 49);
    }

    #[test]
    fn parse_spaced() {
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
