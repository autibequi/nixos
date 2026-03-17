# resume usa o mesmo engine que run (cursor/claude/opencode) a partir de ~/.claudio
engine="$(claudio_resolve_engine 0)"
[[ -z "$engine" ]] && engine="cursor"
mount_path="$(claudio_resolve_dir)"
proj_slug="$(claudio_proj_slug "$mount_path")"
proj_name="$(claudio_proj_name "$proj_slug")"
mount_opts="$(claudio_mount_opts)"
resume_id="${args['--resume']:-1}"

case "$engine" in
  opencode)
    proj_name_open="$(claudio_proj_name_open "$proj_slug")"
    echo "[claudio resume] engine=opencode → $proj_name_open"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name_open" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 -e CLAUDIO_RESUME_SESSION="$resume_id" sandbox \
      bash -c 'cd /workspace && exec opencode'
    ;;
  claude)
    echo "[claudio resume] engine=claude → $proj_name"
    CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /host/claudinho/scripts/bootstrap.sh; cd /workspace && exec /home/claude/.nix-profile/bin/claude --resume --permission-mode bypassPermissions"
    ;;
  cursor)
    echo "[claudio resume] engine=cursor → $proj_name (mount: ${mount_opts})"
    danger="$(claudio_danger_flag cursor)"
    cursor_cmd='. /host/claudinho/scripts/bootstrap.sh; cd /workspace; '
    cursor_cmd+='exec agent'"${danger}"' --resume="${CLAUDIO_RESUME_SESSION:-1}"'
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 -e CLAUDIO_RESUME_SESSION="$resume_id" sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "claudio: engine inválido: $engine" >&2
    exit 1
    ;;
esac
