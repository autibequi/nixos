# zion edit: ~/nixos em /workspace/mnt + /workspace/logs. Respeita engine em ~/.zion (ex.: cursor).
zion_load_config
engine=$(zion_resolve_engine 0)
[[ -z "$engine" ]] && engine="cursor"
mount_path="${ZION_NIXOS_DIR:-$HOME/nixos}"
mount_path="$(cd "$mount_path" 2>/dev/null && pwd)" || { echo "zion edit: dir not found: $mount_path" >&2; exit 1; }
# Mesmo project name do `zion` (~/projects) para compartilhar cursor_config e não pedir login.
proj_name="zion-projects"
mount_opts="rw"
resume_id="${args['--resume']:-}"

EXTRA_V="-v /var/log/journal:/workspace/logs/host/journal:ro"

echo "[zion edit] engine=$engine ${mount_path} → ${proj_name} (mnt + logs)"

engine_args=""
if [[ -n "$resume_id" ]]; then
  [[ "$resume_id" == "1" ]] && engine_args+=" --resume" || engine_args+=" --resume=$resume_id"
fi

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args" "$EXTRA_V"
