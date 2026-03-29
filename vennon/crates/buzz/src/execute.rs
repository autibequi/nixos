use anyhow::Result;
use std::collections::HashMap;
use std::process::{Command, Stdio};

use crate::config::ActionDef;

/// Render the command template and execute it.
/// Returns Ok(Some(output)) if capture=true, Ok(None) for fire-and-forget.
pub fn run_action(action: &ActionDef, args: &HashMap<String, String>) -> Result<Option<String>> {
    let rendered = render_template(&action.command, args);

    if action.capture {
        let output = Command::new("bash")
            .args(["-c", &rendered])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()?;

        let stdout = String::from_utf8_lossy(&output.stdout).to_string();
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();

        if output.status.success() {
            Ok(Some(stdout))
        } else {
            let msg = if stderr.is_empty() { stdout } else { stderr };
            anyhow::bail!("exit {}: {}", output.status.code().unwrap_or(-1), msg.trim());
        }
    } else {
        // Fire and forget — spawn detached
        Command::new("bash")
            .args(["-c", &rendered])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()?;

        Ok(None)
    }
}

/// Replace all `{{ var }}` with shell-escaped arg values.
fn render_template(template: &str, args: &HashMap<String, String>) -> String {
    let mut result = template.to_string();
    // Keep replacing until no more {{ }} remain
    loop {
        let start = match result.find("{{") {
            Some(i) => i,
            None => break,
        };
        let end = match result[start..].find("}}") {
            Some(i) => start + i + 2,
            None => break,
        };
        let var_name = result[start + 2..end - 2].trim();
        let value = args.get(var_name).cloned().unwrap_or_default();
        let escaped = shell_escape(&value);
        result.replace_range(start..end, &escaped);
    }
    result
}

/// Shell-escape a value using single quotes.
/// The only char that needs escaping inside single quotes is the single quote itself.
fn shell_escape(s: &str) -> String {
    if s.is_empty() {
        return "''".into();
    }
    // If the string is simple (alphanumeric + common safe chars), no quoting needed
    if s.chars().all(|c| c.is_alphanumeric() || matches!(c, '/' | '.' | '-' | '_' | ':')) {
        return s.to_string();
    }
    // Wrap in single quotes, escaping any existing single quotes
    format!("'{}'", s.replace('\'', "'\\''"))
}
