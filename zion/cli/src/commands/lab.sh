zion_load_config

nixos_dir="${ZION_NIXOS_DIR:-$HOME/nixos}"
mount_path="$(cd "$nixos_dir" 2>/dev/null && pwd)" \
  || { echo "zion: nixos dir não encontrado: $nixos_dir" >&2; exit 1; }
proj_name="zion-projects"
mount_opts="rw"

# Engine: flag > ~/.zion > default claude (cursor-agent não suporta --name)
engine="${args['--engine']:-${flag_engine:-${ZION_ENGINE:-claude}}}"
engine="${engine,,}"
case "$engine" in
  opencode|claude|cursor) ;;
  *)
    echo "zion: engine inválido: $engine (use opencode|claude|cursor)" >&2
    exit 1
    ;;
esac

# Build engine_args
engine_args=""
resume="${args['--resume']:-${flag_resume:-}}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

# Extra volumes: host journal para /workspace/logs
extra_volumes="-v /var/log/journal:/workspace/logs/host/journal:ro"

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args" "$extra_volumes"
