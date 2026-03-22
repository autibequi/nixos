//! Git commands — repository utilities invoked from the Leech CLI.

use anyhow::Result;

/// `leech git append` — delegates to bash CLI (merge current → branch, push, return).
#[allow(dead_code)]
pub fn append(branch: &str) -> Result<()> {
    crate::exec::bash_delegate(&["git", "append", branch])
}
