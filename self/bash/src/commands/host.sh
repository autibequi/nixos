zion_load_config

# Project mount: identical to zion new
mount_path="$(zion_resolve_dir)"
mount_opts="$(zion_mount_opts)"
slug="$(zion_proj_slug "$mount_path")"
# "-host" suffix: pool separado de containers com /workspace/host rw
proj_name="$(zion_proj_name "$slug")-host"
engine="$(zion_resolve_engine 1)"

# Build engine_args
engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

init_md="$(zion_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

# /workspace/host já está no compose (base-volumes) como ro por padrão.
# Exportar rw para que o container seja criado com nixos editável.
# Journal e nixos mirror já estão em x-base-volumes — sem extra_volumes.
export CLAUDIO_HOST_OPTS=rw

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args"
