leech_load_config

mount_path="$(leech_resolve_dir)"
mount_opts="$(leech_mount_opts)"
slug="$(leech_proj_slug "$mount_path")"
proj_name="$(leech_proj_name "$slug")"
engine="$(leech_resolve_engine 1)"

session_id="${args['--resume']:-}"

engine_args=""
if [[ -n "$session_id" ]]; then
  engine_args="--resume=$session_id"
else
  # Sem UUID: continua a última sessão
  engine_args="--continue"
fi

leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
