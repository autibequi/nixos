# Atalho: zion claude = zion new --engine=claude
args['--engine']="claude"
zion_load_config
engine="claude"
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"
flag_init_md="${args['--init-md']:-}"
initial_md="$(zion_initial_md "$mount_path")"
resume_id="${args['--resume']:-}"

echo "[zion claude] ${proj_slug} → ${proj_name} (mount: ${mount_opts})"

engine_args=""
[[ -n "$initial_md" ]] && engine_args+=" --init-md=$initial_md"
if [[ -n "$resume_id" ]]; then
  [[ "$resume_id" == "1" ]] && engine_args+=" --resume" || engine_args+=" --resume=$resume_id"
fi

zion_session_run "claude" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
