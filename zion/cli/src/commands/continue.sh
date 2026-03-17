# Continua a última sessão (todos os engines). Sem subcomando = mesmo que zion continue.
zion_load_config
engine="$(zion_resolve_engine 0)"
[[ -z "$engine" ]] && engine="cursor"
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"

case "$engine" in
  opencode)
    proj_name_open="$(zion_proj_name_open "$proj_slug")"
    echo "[zion continue] engine=opencode → $proj_name_open (última sessão)"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name_open" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      bash -c 'cd /workspace/mnt && exec opencode'
    ;;
  claude)
    echo "[zion continue] engine=claude → $proj_name (última sessão)"
    model="$(zion_model_flag)"
    danger="$(zion_danger_flag claude)"
    CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /zion/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude --continue ${model}${danger} --permission-mode bypassPermissions"
    ;;
  cursor)
    echo "[zion continue] engine=cursor → $proj_name (última sessão, mount: ${mount_opts})"
    danger="$(zion_danger_flag cursor)"
    cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; exec agent'"${danger}"' --continue'
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "zion: engine inválido: $engine (use opencode|claude|cursor em ~/.zion)" >&2
    exit 1
    ;;
esac
