zion_load_config

mount_path="$(zion_resolve_dir)"
mount_opts="$(zion_mount_opts)"
slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$slug")"
engine="$(zion_resolve_engine 1)"

# Build engine_args
engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

init_md="$(zion_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
