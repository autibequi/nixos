leech_load_config

mount_path="$(leech_resolve_dir)"
mount_opts="$(leech_mount_opts)"
slug="$(leech_proj_slug "$mount_path")"
proj_name="$(leech_proj_name "$slug")"
engine="$(leech_resolve_engine 1)"

# Build engine_args
engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

init_md="$(leech_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
