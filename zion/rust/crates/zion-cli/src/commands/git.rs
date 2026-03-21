//! Git commands — repository utilities invoked from the Zion CLI.

use anyhow::Result;

/// `zion git append` — delegates to bash CLI (merge current → branch, push, return).
pub fn append(branch: &str) -> Result<()> {
    crate::exec::bash_delegate(&["git", "append", branch])
}
