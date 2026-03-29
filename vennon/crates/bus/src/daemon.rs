use anyhow::{Context, Result};
use std::io::{BufRead, BufReader, Write};
use std::os::unix::net::{UnixListener, UnixStream};
use std::time::Instant;

use crate::audit;
use crate::config::BusConfig;
use crate::execute;
use crate::protocol::{BusRequest, BusResponse};
use crate::validate;

pub fn run(config: &BusConfig) -> Result<()> {
    let socket_path = config.socket_path();
    let log_path = config.log_path();

    // Create socket directory
    if let Some(parent) = socket_path.parent() {
        std::fs::create_dir_all(parent)?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let _ = std::fs::set_permissions(parent, std::fs::Permissions::from_mode(0o770));
        }
    }

    // Remove stale socket
    let _ = std::fs::remove_file(&socket_path);

    let listener = UnixListener::bind(&socket_path)
        .with_context(|| format!("bind {}", socket_path.display()))?;

    // Set socket permissions
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let _ = std::fs::set_permissions(&socket_path, std::fs::Permissions::from_mode(0o660));
    }

    eprintln!("[vennon-bus] listening on {}", socket_path.display());
    eprintln!("[vennon-bus] {} actions loaded", config.actions.len());

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let config_clone = config.actions.clone();
                let log_clone = log_path.clone();
                std::thread::spawn(move || {
                    if let Err(e) = handle_connection(stream, &config_clone, &log_clone) {
                        eprintln!("[vennon-bus] connection error: {e}");
                    }
                });
            }
            Err(e) => {
                eprintln!("[vennon-bus] accept error: {e}");
            }
        }
    }

    Ok(())
}

fn handle_connection(
    stream: UnixStream,
    actions: &std::collections::HashMap<String, crate::config::ActionDef>,
    log_path: &std::path::Path,
) -> Result<()> {
    let start = Instant::now();
    let mut reader = BufReader::new(&stream);
    let mut line = String::new();
    reader.read_line(&mut line)?;

    let req: BusRequest = match serde_json::from_str(line.trim()) {
        Ok(r) => r,
        Err(e) => {
            let resp = BusResponse::error("?", &format!("JSON inválido: {e}"));
            send_response(&stream, &resp)?;
            return Ok(());
        }
    };

    eprintln!("[vennon-bus] {} → {} {:?}", req.source, req.action, req.args);

    // Lookup action
    let action = match actions.get(&req.action) {
        Some(a) => a,
        None => {
            let resp = BusResponse::denied(&req.id, &format!("action desconhecida: {}", req.action));
            audit::log_entry(log_path, &req, &resp, start.elapsed().as_millis() as u64);
            send_response(&stream, &resp)?;
            return Ok(());
        }
    };

    // Validate args
    let resolved = match validate::validate_args(action, &req.args) {
        Ok(r) => r,
        Err(reason) => {
            let resp = BusResponse::denied(&req.id, &reason);
            audit::log_entry(log_path, &req, &resp, start.elapsed().as_millis() as u64);
            send_response(&stream, &resp)?;
            return Ok(());
        }
    };

    // Execute
    let resp = match execute::run_action(action, &resolved) {
        Ok(output) => BusResponse::ok(&req.id, output),
        Err(e) => BusResponse::error(&req.id, &e.to_string()),
    };

    audit::log_entry(log_path, &req, &resp, start.elapsed().as_millis() as u64);
    send_response(&stream, &resp)?;
    Ok(())
}

fn send_response(stream: &UnixStream, resp: &BusResponse) -> Result<()> {
    let mut writer = stream;
    let json = serde_json::to_string(resp)?;
    writeln!(writer, "{json}")?;
    Ok(())
}
