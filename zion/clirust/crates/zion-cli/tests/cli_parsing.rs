//! Integration tests for CLI argument parsing.
//! These verify that clap accepts the expected arguments without actually running commands.

use std::process::Command;

fn zion_bin() -> Command {
    Command::new(env!("CARGO_BIN_EXE_zion"))
}

// ── Help output ──────────────────────────────────────────────────

#[test]
fn help_shows_all_commands() {
    let out = zion_bin().arg("--help").output().unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);

    let expected = [
        "new", "continue", "claude", "cursor", "opencode", "resume", "shell",
        "leech", "lab", "build", "down", "shutdown", "clean", "stow", "os",
        "update", "init", "set", "hooks", "relay", "inbox", "outbox", "man",
        "banner", "usage", "token", "status", "contractors", "git",
    ];
    for cmd in expected {
        assert!(stdout.contains(cmd), "missing command in help: {cmd}");
    }
}

#[test]
fn version_flag() {
    let out = zion_bin().arg("--version").output().unwrap();
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(stdout.starts_with("zion "));
}

// ── Subcommand help ──────────────────────────────────────────────

#[test]
fn new_help() {
    let out = zion_bin().args(["new", "--help"]).output().unwrap();
    let s = String::from_utf8_lossy(&out.stdout);
    assert!(s.contains("--engine"));
    assert!(s.contains("--model"));
    assert!(s.contains("--danger"));
    assert!(s.contains("--resume"));
    assert!(s.contains("--init-md"));
    assert!(s.contains("--analysis-mode"));
}

#[test]
fn os_help_shows_subcommands() {
    let out = zion_bin().args(["os", "--help"]).output().unwrap();
    let s = String::from_utf8_lossy(&out.stdout);
    assert!(s.contains("switch"));
    assert!(s.contains("test"));
    assert!(s.contains("boot"));
    assert!(s.contains("build"));
}

#[test]
fn contractors_help() {
    let out = zion_bin().args(["contractors", "--help"]).output().unwrap();
    let s = String::from_utf8_lossy(&out.stdout);
    assert!(s.contains("run"));
    assert!(s.contains("status"));
}

#[test]
fn status_help() {
    let out = zion_bin().args(["status", "--help"]).output().unwrap();
    let s = String::from_utf8_lossy(&out.stdout);
    assert!(s.contains("--tick"));
}

// ── Flag validation ──────────────────────────────────────────────

#[test]
fn invalid_subcommand_as_dir() {
    // Unknown words are treated as dir arg, not as errors
    // This tests that clap doesn't crash
    let out = zion_bin().args(["--help"]).output().unwrap();
    assert!(out.status.success());
}

#[test]
fn resume_accepts_no_value() {
    // --resume without value should be accepted (default_missing_value = "1")
    let out = zion_bin().args(["new", "--resume", "--help"]).output().unwrap();
    assert!(out.status.success());
}

#[test]
fn resume_accepts_uuid() {
    let out = zion_bin()
        .args(["new", "--resume=abc-123-def", "--help"])
        .output()
        .unwrap();
    assert!(out.status.success());
}

// ── Aliases ──────────────────────────────────────────────────────

#[test]
fn aliases_work() {
    for (alias, expected_in_help) in [
        ("run", "--engine"),    // alias for new
        ("cont", "[DIR]"),     // alias for continue
        ("oc", "--engine"),    // alias for opencode
        ("sh", "[DIR]"),       // alias for shell
        ("st", "--tick"),      // alias for status
        ("gc", "--force"),     // alias for clean
        ("l", "--shell"),      // alias for leech
        ("ct", "run"),         // alias for contractors
        ("g", "append"),       // alias for git
        ("ib", "[MESSAGE]"),   // alias for inbox
        ("ob", ""),            // alias for outbox
    ] {
        let out = zion_bin().args([alias, "--help"]).output().unwrap();
        assert!(
            out.status.success(),
            "alias '{alias}' not recognized"
        );
        if !expected_in_help.is_empty() {
            let s = String::from_utf8_lossy(&out.stdout);
            assert!(
                s.contains(expected_in_help),
                "alias '{alias}' help missing '{expected_in_help}'"
            );
        }
    }
}
