zion_load_config

mount_path="$(zion_resolve_dir)"
mount_opts="$(zion_mount_opts)"
slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$slug")"

zion_compose_env "$mount_path" "$mount_opts"

zion_compose_cmd -p "$proj_name" run --rm -it \
  --entrypoint /entrypoint.sh \
  -e "CLAUDIO_MOUNT=$mount_path" \
  -e "BOOTSTRAP_SKIP_CLEAR=1" \
  leech \
  /bin/bash -c ". /workspace/zion/scripts/bootstrap.sh; cd /workspace/mnt && exec bash"
