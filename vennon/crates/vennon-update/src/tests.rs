use super::*;
use std::time::Duration;

#[test]
fn pad_box_inner_pads_to_width() {
    assert_eq!(pad_box_inner("ab", 4).chars().count(), 4);
    assert_eq!(pad_box_inner("ab", 4), "ab  ");
}

#[test]
fn pad_box_inner_truncates() {
    assert_eq!(pad_box_inner("abcdefgh", 5), "abcde");
}

#[test]
fn fmt_dur_zero_ms() {
    let s = fmt_dur(Duration::from_millis(12));
    assert!(s.ends_with("ms"), "got {s}");
}

#[test]
fn fmt_dur_seconds() {
    assert_eq!(fmt_dur(Duration::from_secs(3)), "3s");
}

#[test]
fn fmt_dur_minutes() {
    assert_eq!(fmt_dur(Duration::from_secs(125)), "2m5s");
}
