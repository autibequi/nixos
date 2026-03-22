leech_load_config

mount_path="$(leech_resolve_dir)"
mount_opts="$(leech_mount_opts)"
slug="$(leech_proj_slug "$mount_path")"
proj_name="$(leech_proj_name "$slug")"
engine="$(leech_resolve_engine 1)"

leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "--continue"
