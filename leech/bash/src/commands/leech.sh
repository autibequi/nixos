leech_load_config

# Resolve dir: usa arg "dir" ou ~/projects
raw_dir="${args[dir]:-$HOME/projects}"
mount_path="$(cd "$raw_dir" 2>/dev/null && pwd)" \
  || { echo "leech: dir não encontrado: $raw_dir" >&2; exit 1; }

# Slug e proj_name derivados do dir montado (sem colisão com ~/projects)
slug="$(leech_proj_slug "$mount_path")"
proj_name="$(leech_proj_name "$slug")"
extra_volumes=""

mount_opts="$(leech_mount_opts)"

# --shell: bash interativo em vez de engine
if [[ -n "${args['--shell']:-}" ]]; then
  leech_compose_env "$mount_path" "$mount_opts"
  leech_compose_cmd -p "$proj_name" run --rm -it $extra_volumes \
    --entrypoint /entrypoint.sh \
    -e "CLAUDIO_MOUNT=$mount_path" \
    -e "BOOTSTRAP_SKIP_CLEAR=1" \
    leech \
    /bin/bash -c ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec bash"
  exit 0
fi

engine="${args['--engine']:-${flag_engine:-${LEECH_ENGINE:-}}}"
engine="${engine,,}"
if [[ -z "$engine" ]]; then
  echo "leech: --engine=opencode|claude|cursor é obrigatório (ou defina engine= em ~/.leech)" >&2
  exit 1
fi

# Build engine_args
engine_args=""
resume="${args['--resume']:-}"
[[ -n "$resume" ]] && engine_args+=" --resume=$resume"

init_md="$(leech_initial_md "$mount_path")"
[[ -n "$init_md" ]] && engine_args+=" --init-md=$init_md"

leech_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args" "$extra_volumes"
