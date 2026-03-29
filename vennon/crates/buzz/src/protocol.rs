use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize)]
pub struct BusRequest {
    pub id: String,
    pub action: String,
    #[serde(default)]
    pub args: HashMap<String, serde_json::Value>,
    /// Container name for audit trail.
    #[serde(default)]
    pub source: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BusResponse {
    pub id: String,
    /// "ok" | "error" | "denied"
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub output: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

impl BusResponse {
    pub fn ok(id: &str, output: Option<String>) -> Self {
        Self {
            id: id.into(),
            status: "ok".into(),
            output,
            error: None,
        }
    }

    pub fn denied(id: &str, reason: &str) -> Self {
        Self {
            id: id.into(),
            status: "denied".into(),
            output: None,
            error: Some(reason.into()),
        }
    }

    pub fn error(id: &str, reason: &str) -> Self {
        Self {
            id: id.into(),
            status: "error".into(),
            output: None,
            error: Some(reason.into()),
        }
    }
}

/// Generate a short random ID (no uuid crate needed).
pub fn gen_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let t = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default();
    format!("{:x}{:04x}", t.as_secs(), t.subsec_millis())
}
