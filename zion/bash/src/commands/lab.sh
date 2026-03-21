zion_load_config

# Project mount: identical to zion new
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

# Lab volumes: nixos repo at /workspace/host (writable) + host journal
nixos_dir="${ZION_NIXOS_DIR:-$HOME/nixos}"
nixos_real="$(cd "$nixos_dir" 2>/dev/null && pwd)" \
  || { echo "zion: nixos dir não encontrado: $nixos_dir" >&2; exit 1; }
extra_volumes="-v ${nixos_real}:/workspace/host:rw"
extra_volumes+=" -v /var/log/journal:/workspace/logs/host/journal:ro"

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args" "$extra_volumes"
