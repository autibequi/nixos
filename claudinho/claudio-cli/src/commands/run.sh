# Sessão no container: exige --engine=opencode|claude|cursor (ou engine= em ~/.claudio)
claudio_load_config
engine=$(claudio_resolve_engine 1)
mount_path="$(claudio_resolve_dir)"
proj_slug="$(claudio_proj_slug "$mount_path")"
mount_opts="$(claudio_mount_opts)"

case "$engine" in
  opencode)
    proj_name="$(claudio_proj_name_open "$proj_slug")"
    echo "[claudio run] engine=opencode ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
    opencode_danger_env=""
    [[ -n "${flag_danger:-${args['--danger']:-}}" ]] && opencode_danger_env="-e OPENCODE_PERMISSION_BYPASS=1"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" up -d sandbox
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" exec -it \
      -e CLAUDIO_MOUNT="$mount_path" $opencode_danger_env sandbox bash -c 'cd /workspace/mount && exec opencode'
    ;;
  claude)
    proj_name="$(claudio_proj_name "$proj_slug")"
    model="$(claudio_model_flag)"
    danger="$(claudio_danger_flag claude)"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /workspace/host/scripts/bootstrap.sh; cd /workspace/mount && exec /home/claude/.nix-profile/bin/claude ${model}${danger}"
    ;;
  cursor)
    proj_name="$(claudio_proj_name "$proj_slug")"
    danger="$(claudio_danger_flag cursor)"
    echo "[claudio run] engine=cursor ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
      claudio_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /workspace/host/scripts/bootstrap.sh; cd /workspace/mount && exec agent${danger}"
    ;;
  *)
    echo "claudio: engine inválido: $engine" >&2
    exit 1
    ;;
esac
