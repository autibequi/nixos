# DEPRECATED: use 'zion new --engine=claude --danger' instead.
# Kept for backwards compatibility — delegates to new session with claude engine.
echo "[zion start] DEPRECATED — use 'zion new --engine=claude --danger'" >&2
zion_load_config
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"

echo "[zion start] ${proj_slug} → ${proj_name}"

# Force danger mode (original behavior: --permission-mode bypassPermissions)
export ZION_DANGER=1
zion_session_run "claude" "$proj_name" "$mount_path" "$mount_opts" ""
