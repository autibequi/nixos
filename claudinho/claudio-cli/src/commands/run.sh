# Sessão no container: exige --engine=opencode|claude|cursor (ou engine= em ~/.claudio)
claudio_load_config
engine=$(claudio_resolve_engine 1)
mount_path="$(claudio_resolve_dir)"
proj_slug="$(claudio_proj_slug "$mount_path")"
mount_opts="$(claudio_mount_opts)"
flag_init_md="${args['--init-md']:-}"
initial_md="$(claudio_initial_md "$mount_path")"

case "$engine" in
  opencode)
    proj_name="$(claudio_proj_name_open "$proj_slug")"
    echo "[claudio run] engine=opencode ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
    opencode_danger_env=""
    [[ -n "${flag_danger:-${args['--danger']:-}}" ]] && opencode_danger_env="-e OPENCODE_PERMISSION_BYPASS=1"
    opencode_init_env=""
    [[ -n "$initial_md" ]] && opencode_init_env="-e CLAUDE_INITIAL_MD=/workspace/mount/$initial_md"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" up -d sandbox
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" exec -it \
      -e CLAUDIO_MOUNT="$mount_path" $opencode_danger_env $opencode_init_env sandbox bash -c 'cd /workspace/mount && exec opencode'
    ;;
  claude)
    proj_name="$(claudio_proj_name "$proj_slug")"
    model="$(claudio_model_flag)"
    danger="$(claudio_danger_flag claude)"
    init_file=""
    [[ -n "$initial_md" ]] && init_file=" --append-system-prompt-file $initial_md"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /workspace/host/scripts/bootstrap.sh; cd /workspace/mount && exec /home/claude/.nix-profile/bin/claude ${model}${danger}${init_file}"
    ;;
  cursor)
    proj_name="$(claudio_proj_name "$proj_slug")"
    danger="$(claudio_danger_flag cursor)"
    echo "[claudio run] engine=cursor ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
    # --init-md: envia o texto do arquivo como primeira mensagem ao agent (script no container evita quoting)
    cursor_init_env=""
    if [[ -n "$initial_md" ]]; then
      cursor_init_env="-e CLAUDIO_INITIAL_MD=$initial_md"
    fi
    # Script no container: lê init-md, escapa aspas e passa como primeiro arg ao agent
    cursor_cmd='. /workspace/host/scripts/bootstrap.sh; cd /workspace/mount; '
    cursor_cmd+='if [ -n "${CLAUDIO_INITIAL_MD:-}" ] && [ -f "/workspace/mount/$CLAUDIO_INITIAL_MD" ]; then '
    cursor_cmd+='p=$(sed -e '\''s/\\\\/\\\\\\\\/g'\'' -e '\''s/"/\\"/g'\'' "/workspace/mount/$CLAUDIO_INITIAL_MD"); exec agent'"${danger}"' "$p"; '
    cursor_cmd+='else exec agent'"${danger}"'; fi'
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 $cursor_init_env sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "claudio: engine inválido: $engine" >&2
    exit 1
    ;;
esac
