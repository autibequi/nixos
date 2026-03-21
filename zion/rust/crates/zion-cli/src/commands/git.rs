//! Git commands — repository utilities invoked from the Zion CLI.

use anyhow::Result;
use zion_sdk::paths;

/// `zion git append` — stage all + commit.
pub fn append(_branch: &str) -> Result<()> {
    crate::exec::fire("git", &["add", "-A"]);
    let _ = crate::exec::run(
        "git",
        &[
            "commit",
            "-m",
            &format!("chore: append {}", paths::timestamp()),
        ],
    );
    Ok(())
}
