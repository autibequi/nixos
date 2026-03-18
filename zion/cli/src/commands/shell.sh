zion_load_config
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
  zion_compose_cmd -p "$proj_name" run --rm -it \
  --entrypoint /entrypoint.sh -e CLAUDIO_MOUNT="$mount_path" sandbox /bin/bash
