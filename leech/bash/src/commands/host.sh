leech_load_config

# Project mount: identical to leech new
mount_path="$(leech_resolve_dir)"
mount_opts="$(leech_mount_opts)"
slug="$(leech_proj_slug "$mount_path")"
# "-host" suffix: pool separado de containers com /workspace/host rw
proj_name="$(leech_proj_name "$slug")-host"
engine="$(leech_resolve_engine 1)"

# Build engine_args
engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

init_md="$(leech_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

# /workspace/host já está no compose (base-volumes) como ro por padrão.
# Exportar rw para que o container seja criado com nixos editável.
# Journal e nixos mirror já estão em x-base-volumes — sem extra_volumes.
export CLAUDIO_HOST_OPTS=rw

leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
