# Persistent sandbox + Claude (like legacy make start)
zion_load_config
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"
touch "$HOME/.claude.json"
echo "[zion start] ${proj_slug} → ${proj_name}"
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
  zion_compose_cmd -p "$proj_name" up -d sandbox
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
  zion_compose_cmd -p "$proj_name" exec -it \
  -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox bash -c \
  '. /zion/scripts/bootstrap.sh; cd /workspace; exec /home/claude/.nix-profile/bin/claude --permission-mode bypassPermissions'
