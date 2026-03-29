use super::*;

#[test]
fn expand_path_dollar_home() {
    let h = home();
    assert_eq!(expand_path("$HOME/foo"), h.join("foo"));
}

#[test]
fn expand_path_braced_home() {
    let h = home();
    assert_eq!(expand_path("${HOME}/bar"), h.join("bar"));
}

#[test]
fn expand_path_tilde_prefix() {
    let h = home();
    assert_eq!(expand_path("~/baz"), h.join("baz"));
}

#[test]
fn vennon_config_deserializes_minimal_yaml() {
    let yaml = r#"paths:
  self: ~/nixos/vennon/self
  obsidian: ~/.ovault/Work
  projects: ~/projects
  host: ~/nixos
  vennon: ~/nixos/vennon
settings:
  memory_limit: 12g
  journal_gid: 62
"#;
    let c: VennonConfig = serde_yaml::from_str(yaml).unwrap();
    assert_eq!(c.paths.vennon, "~/nixos/vennon");
    assert_eq!(c.settings.memory_limit, "12g");
    assert_eq!(c.settings.journal_gid, 62);
}

#[test]
fn settings_default_matches() {
    let s = SettingsConfig::default();
    assert_eq!(s.memory_limit, "12g");
    assert_eq!(s.journal_gid, 62);
}
