# Sessão no container: exige --engine=opencode|claude|cursor (ou engine= em ~/.zion)
zion_load_config
engine=$(zion_resolve_engine 1)
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
mount_opts="$(zion_mount_opts)"
flag_init_md="${args['--init-md']:-}"
initial_md="$(zion_initial_md "$mount_path")"
resume_id="${args['--resume']:-}"

case "$engine" in
  opencode)
    proj_name="$(zion_proj_name_open "$proj_slug")"
    echo "[zion run] engine=opencode ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
    opencode_danger_env=""
    [[ -n "${flag_danger:-${args['--danger']:-${ZION_DANGER:-}}}" ]] && opencode_danger_env="-e OPENCODE_PERMISSION_BYPASS=1"
    opencode_init_env=""
    [[ -n "$initial_md" ]] && opencode_init_env="-e CLAUDE_INITIAL_MD=/workspace/mnt/$initial_md"
    opencode_resume_env=""
    [[ -n "$resume_id" ]] && opencode_resume_env="-e CLAUDIO_RESUME_SESSION=$resume_id"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" up -d sandbox
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" exec -it \
      -e CLAUDIO_MOUNT="$mount_path" $opencode_danger_env $opencode_init_env $opencode_resume_env sandbox bash -c 'cd /workspace/mnt && exec opencode'
    ;;
  claude)
    proj_name="$(zion_proj_name "$proj_slug")"
    model="$(zion_model_flag)"
    danger="$(zion_danger_flag claude)"
    init_file=""
    [[ -n "$initial_md" ]] && init_file=" --append-system-prompt-file $initial_md"
    resume_flag=""
    if [[ -n "$resume_id" ]]; then
      [[ "$resume_id" == "1" ]] && resume_flag=" --resume" || resume_flag=" --resume=$resume_id"
    fi
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /zion/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude ${model}${danger}${init_file}${resume_flag}"
    ;;
  cursor)
    proj_name="$(zion_proj_name "$proj_slug")"
    danger="$(zion_danger_flag cursor)"
    echo "[zion run] engine=cursor ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
    cursor_init_env=""
    [[ -n "$initial_md" ]] && cursor_init_env="-e CLAUDIO_INITIAL_MD=$initial_md"
    cursor_resume_env=""
    [[ -n "$resume_id" ]] && cursor_resume_env="-e CLAUDIO_RESUME_SESSION=$resume_id"
    cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; '
    cursor_cmd+='if [ -n "${CLAUDIO_RESUME_SESSION:-}" ]; then '
    cursor_cmd+='exec agent'"${danger}"' --resume="${CLAUDIO_RESUME_SESSION}"; '
    cursor_cmd+='elif [ -n "${CLAUDIO_INITIAL_MD:-}" ] && [ -f "/workspace/mnt/$CLAUDIO_INITIAL_MD" ]; then '
    cursor_cmd+='p=$(sed -e '\''s/\\\\/\\\\\\\\/g'\'' -e '\''s/"/\\"/g'\'' "/workspace/mnt/$CLAUDIO_INITIAL_MD"); exec agent'"${danger}"' "$p"; '
    cursor_cmd+='else exec agent'"${danger}"'; fi'
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 $cursor_init_env $cursor_resume_env sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "zion: engine inválido: $engine" >&2
    exit 1
    ;;
esac
