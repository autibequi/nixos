zion_load_config

# Resolve dir: usa arg "dir" ou ~/projects
raw_dir="${args[dir]:-$HOME/projects}"
mount_path="$(cd "$raw_dir" 2>/dev/null && pwd)" \
  || { echo "zion: dir não encontrado: $raw_dir" >&2; exit 1; }

# Autodetect nixos repo → proj_name fixo + journal mount
nixos_dir="${ZION_NIXOS_DIR:-$HOME/nixos}"
nixos_real="$(cd "$nixos_dir" 2>/dev/null && pwd)"
is_nixos=0
[[ "$mount_path" == "$nixos_real" ]] && is_nixos=1

if [[ $is_nixos -eq 1 ]]; then
  proj_name="zion-projects"
  extra_volumes="-v /var/log/journal:/workspace/logs/host/journal:ro"
else
  slug="$(zion_proj_slug "$mount_path")"
  proj_name="$(zion_proj_name "$slug")"
  extra_volumes=""
fi

mount_opts="$(zion_mount_opts)"

# --shell: bash interativo em vez de engine
if [[ -n "${args['--shell']:-}" ]]; then
  zion_compose_env "$mount_path" "$mount_opts"
  zion_compose_cmd -p "$proj_name" run --rm -it $extra_volumes \
    --entrypoint /entrypoint.sh \
    -e "CLAUDIO_MOUNT=$mount_path" \
    -e "BOOTSTRAP_SKIP_CLEAR=1" \
    leech \
    /bin/bash -c ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec bash"
  exit 0
fi

engine="${args['--engine']:-${flag_engine:-${ZION_ENGINE:-}}}"
engine="${engine,,}"
if [[ -z "$engine" ]]; then
  echo "zion: --engine=opencode|claude|cursor é obrigatório (ou defina engine= em ~/.zion)" >&2
  exit 1
fi

# Build engine_args
engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

init_md="$(zion_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args" "$extra_volumes"
