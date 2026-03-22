zion_load_config

mount_path="$(zion_resolve_dir)"
mount_opts="$(zion_mount_opts)"
slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$slug")"
engine="$(zion_resolve_engine 1)"

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "--continue"
