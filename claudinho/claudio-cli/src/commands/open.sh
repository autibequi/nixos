mount_path="$(claudio_resolve_dir)"
proj_slug="$(claudio_proj_slug "$mount_path")"
proj_name="$(claudio_proj_name_open "$proj_slug")"
mount_opts="$(claudio_mount_opts)"
echo "[claudio open] ${proj_slug} → ${proj_name} (mount: ${mount_opts})"
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" \
  docker compose -f "$claudio_compose_file" -p "$proj_name" up -d sandbox
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" \
  docker compose -f "$claudio_compose_file" -p "$proj_name" exec -it \
  -e CLAUDIO_MOUNT="$mount_path" sandbox bash -c 'cd /workspace/mount && exec opencode'
