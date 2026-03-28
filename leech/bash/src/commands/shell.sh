leech_load_config

mount_path="$(leech_resolve_dir)"
mount_opts="$(leech_mount_opts)"
slug="$(leech_proj_slug "$mount_path")"
proj_name="$(leech_proj_name "$slug")"

leech_compose_env "$mount_path" "$mount_opts"

leech_compose_cmd -p "$proj_name" run --rm -it \
  --entrypoint /entrypoint.sh \
  -e "CLAUDIO_MOUNT=$mount_path" \
  -e "BOOTSTRAP_SKIP_CLEAR=1" \
  leech \
  /bin/bash -c ". /workspace/self/scripts/bootstrap.sh; cd /workspace/mnt && exec bash"
