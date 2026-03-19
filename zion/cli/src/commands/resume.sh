zion_load_config

mount_path="$(zion_resolve_dir)"
mount_opts="$(zion_mount_opts)"
slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$slug")"
engine="$(zion_resolve_engine 1)"

session_id="${args['--resume']:-}"

engine_args=""
if [[ -n "$session_id" ]]; then
  engine_args="--resume=$session_id"
else
  # Sem UUID: continua a última sessão
  engine_args="--continue"
fi

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
