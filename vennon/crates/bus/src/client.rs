use anyhow::{Context, Result};
use std::collections::HashMap;
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::Path;

use crate::protocol::{gen_id, BusRequest, BusResponse};

pub fn call(
    socket_path: &Path,
    action: &str,
    args: HashMap<String, serde_json::Value>,
) -> Result<BusResponse> {
    let stream = UnixStream::connect(socket_path)
        .with_context(|| format!("conectando em {}", socket_path.display()))?;

    let req = BusRequest {
        id: gen_id(),
        action: action.into(),
        args,
        source: container_name(),
    };

    // Send request
    let json = serde_json::to_string(&req)?;
    let mut writer = &stream;
    writeln!(writer, "{json}")?;

    // Read response
    let mut reader = BufReader::new(&stream);
    let mut line = String::new();
    reader.read_line(&mut line)?;

    let resp: BusResponse = serde_json::from_str(line.trim())
        .with_context(|| format!("parsing response: {}", line.trim()))?;

    Ok(resp)
}

/// Try to detect current container name from hostname or env.
fn container_name() -> String {
    std::env::var("HOSTNAME")
        .or_else(|_| std::fs::read_to_string("/etc/hostname").map(|s| s.trim().to_string()))
        .unwrap_or_else(|_| "unknown".into())
}
