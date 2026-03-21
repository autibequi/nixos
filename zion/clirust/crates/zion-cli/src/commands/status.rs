use anyhow::Result;

pub fn execute(tick: u64) -> Result<()> {
    zion_tui::run_status(tick)?;
    Ok(())
}
