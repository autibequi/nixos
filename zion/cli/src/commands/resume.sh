# resume usa o mesmo engine que run (cursor/claude/opencode) a partir de ~/.claudio
engine="$(zion_resolve_engine 0)"
[[ -z "$engine" ]] && engine="cursor"
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"
resume_id="${args['--resume']:-1}"

case "$engine" in
  opencode)
    proj_name_open="$(zion_proj_name_open "$proj_slug")"
    echo "[zion resume] engine=opencode → $proj_name_open"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name_open" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 -e CLAUDIO_RESUME_SESSION="$resume_id" sandbox \
      bash -c 'cd /workspace/mnt && exec opencode'
    ;;
  claude)
    echo "[zion resume] engine=claude → $proj_name"
    CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /zion/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude --resume --permission-mode bypassPermissions"
    ;;
  cursor)
    echo "[zion resume] engine=cursor → $proj_name (mount: ${mount_opts})"
    danger="$(zion_danger_flag cursor)"
    # Cursor agent: --continue = última sessão; --resume=UUID = sessão específica
    if [[ -n "$resume_id" && "$resume_id" != "1" ]]; then
      cursor_resume_env="-e CLAUDIO_RESUME_SESSION=$resume_id"
      cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; exec agent'"${danger}"' --resume="${CLAUDIO_RESUME_SESSION}"'
    else
      cursor_resume_env=""
      cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; exec agent'"${danger}"' --continue'
    fi
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 $cursor_resume_env sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "zion: engine inválido: $engine" >&2
    exit 1
    ;;
esac
