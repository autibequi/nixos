# Compatibilidade: `leech host` foi substituído por `leech --host` ou `leech new --host`.
# Redireciona para o novo comando com --host ativo.
printf '\033[33m[leech]\033[0m \033[2mleech host\033[0m foi substituído por \033[1mleech --host\033[0m\n' >&2
args['--host']='1'
flag_host='1'

leech_load_config

mount_path="$(leech_resolve_dir)"
mount_opts="$(leech_mount_opts)"
slug="$(leech_proj_slug "$mount_path")"
proj_name="$(leech_proj_name "$slug")"
engine="$(leech_resolve_engine 1)"

engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"
init_md="$(leech_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
