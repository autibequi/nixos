# Continua a última sessão (todos os engines). Sem subcomando = mesmo que zion continue.
zion_load_config
engine="$(zion_resolve_engine 0)"
[[ -z "$engine" ]] && engine="cursor"
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
mount_opts="$(zion_mount_opts)"

if [[ "$engine" == "opencode" ]]; then
  proj_name="$(zion_proj_name_open "$proj_slug")"
else
  proj_name="$(zion_proj_name "$proj_slug")"
fi

echo "[zion continue] engine=$engine → $proj_name (última sessão, mount: ${mount_opts})"
zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "--continue"
