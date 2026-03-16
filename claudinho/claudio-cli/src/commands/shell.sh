claudio_load_config
mount_path="$(claudio_resolve_dir)"
proj_slug="$(claudio_proj_slug "$mount_path")"
proj_name="$(claudio_proj_name "$proj_slug")"
mount_opts="$(claudio_mount_opts)"
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
  claudio_compose_cmd -p "$proj_name" run --rm -it \
  --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" sandbox
