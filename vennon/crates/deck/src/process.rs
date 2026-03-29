//! Subprocess execution with wall-clock timeout so the TUI event loop never blocks forever.

use std::io::{self, Read};
use std::process::{Command, Output, Stdio};
use std::thread;
use std::time::{Duration, Instant};

/// Default per external command (podman, vennon).
pub const CMD_TIMEOUT: Duration = Duration::from_secs(12);

pub fn output_with_timeout(mut cmd: Command, timeout: Duration) -> io::Result<Output> {
    cmd.stdout(Stdio::piped()).stderr(Stdio::piped());
    let mut child = cmd.spawn()?;

    let mut stdout_pipe = child.stdout.take().expect("stdout piped");
    let mut stderr_pipe = child.stderr.take().expect("stderr piped");

    let stdout_handle = thread::spawn(move || {
        let mut buf = Vec::new();
        let _ = stdout_pipe.read_to_end(&mut buf);
        buf
    });
    let stderr_handle = thread::spawn(move || {
        let mut buf = Vec::new();
        let _ = stderr_pipe.read_to_end(&mut buf);
        buf
    });

    let deadline = Instant::now() + timeout;
    loop {
        match child.try_wait() {
            Ok(Some(status)) => {
                let stdout = stdout_handle
                    .join()
                    .map_err(|_| io::Error::other("stdout reader thread panicked"))?;
                let stderr = stderr_handle
                    .join()
                    .map_err(|_| io::Error::other("stderr reader thread panicked"))?;
                return Ok(Output {
                    status,
                    stdout,
                    stderr,
                });
            }
            Ok(None) => {
                if Instant::now() >= deadline {
                    let _ = child.kill();
                    let _ = child.wait();
                    let _ = stdout_handle.join();
                    let _ = stderr_handle.join();
                    return Err(io::Error::new(
                        io::ErrorKind::TimedOut,
                        "command exceeded timeout",
                    ));
                }
                thread::sleep(Duration::from_millis(25));
            }
            Err(e) => {
                let _ = stdout_handle.join();
                let _ = stderr_handle.join();
                return Err(e);
            }
        }
    }
}
