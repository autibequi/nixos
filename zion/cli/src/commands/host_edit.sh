# zion edit: ~/nixos em /workspace/mnt + /workspace/logs. Respeita engine em ~/.zion (ex.: cursor).
# Cursor: usar credenciais do host como no outro container — ~/.claude (cursor_api_key, .env), ~/.config/cursor (mount).
zion_load_config
engine=$(zion_resolve_engine 0)
[[ -z "$engine" ]] && engine="cursor"
mount_path="${ZION_NIXOS_DIR:-$HOME/nixos}"
mount_path="$(cd "$mount_path" 2>/dev/null && pwd)" || { echo "zion edit: dir not found: $mount_path" >&2; exit 1; }
proj_slug="nixos"
# Mesmo project name do `zion` (~/projects) para compartilhar cursor_config e não pedir login.
proj_name="zion-projects"
mount_opts="rw"
resume_id="${args['--resume']:-}"
EXTRA_V="-v /var/log/journal:/workspace/logs/host/journal:ro"
cursor_key_env=""

case "$engine" in
  opencode)
    echo "[zion edit] engine=opencode ${mount_path} → ${proj_name} (mnt + logs)"
    opencode_danger_env=""
    [[ -n "${flag_danger:-${args['--danger']:-${ZION_DANGER:-}}}" ]] && opencode_danger_env="-e OPENCODE_PERMISSION_BYPASS=1"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it $EXTRA_V \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" sandbox bash -c 'cd /workspace/mnt && exec opencode'
    ;;
  claude)
    echo "[zion edit] engine=claude ${mount_path} → ${proj_name} (mnt + logs)"
    model="$(zion_model_flag)"
    danger="$(zion_danger_flag claude)"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it $EXTRA_V \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /zion/scripts/bootstrap.sh; cd /workspace/mnt && exec /home/claude/.nix-profile/bin/claude ${model}${danger}"
    ;;
    cursor)
      echo "[zion edit] engine=cursor ${mount_path} → ${proj_name} (mnt + logs)"
      danger="$(zion_danger_flag cursor)"
      cursor_resume_env=""
      [[ -n "$resume_id" ]] && cursor_resume_env="-e CLAUDIO_RESUME_SESSION=$resume_id"
      cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; '
      cursor_cmd+='if [ -n "${CLAUDIO_RESUME_SESSION:-}" ]; then exec agent'"${danger}"' --resume="${CLAUDIO_RESUME_SESSION}"; else exec agent'"${danger}"'; fi'
      HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it $EXTRA_V $cursor_key_env \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 $cursor_resume_env sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "zion edit: engine inválido: $engine (use opencode|claude|cursor em ~/.zion)" >&2
    exit 1
    ;;
esac
