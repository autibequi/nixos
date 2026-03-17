# Persistent sandbox + Claude (like legacy make start)
claudio_load_config
mount_path="$(claudio_resolve_dir)"
proj_slug="$(claudio_proj_slug "$mount_path")"
proj_name="$(claudio_proj_name "$proj_slug")"
mount_opts="$(claudio_mount_opts)"
touch "$HOME/.claude.json"
echo "[claudio start] ${proj_slug} → ${proj_name}"
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
  claudio_compose_cmd -p "$proj_name" up -d sandbox
CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$claudio_obsidian_path" \
  claudio_compose_cmd -p "$proj_name" exec -it \
  -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox bash -c \
  '. /host/claudinho/scripts/bootstrap.sh; cd /workspace; exec /home/claude/.nix-profile/bin/claude --permission-mode bypassPermissions'
