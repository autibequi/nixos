//! Error types and `Result` alias for the Zion SDK.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum ZionError {
    #[error("engine required: use --engine=claude|cursor|opencode or set engine= in ~/.zion")]
    EngineRequired,

    #[error("invalid engine: {0} (use claude, cursor, or opencode)")]
    InvalidEngine(String),

    #[error("directory not found: {0}")]
    DirNotFound(String),

    #[error("config error: {0}")]
    Config(String),

    #[error("docker error: {0}")]
    Docker(String),

    #[error("compose error: {0}")]
    Compose(String),

    #[error(transparent)]
    Io(#[from] std::io::Error),

    #[error(transparent)]
    Other(#[from] anyhow::Error),
}

pub type Result<T> = std::result::Result<T, ZionError>;
