# zion leech [dir] — engatou numa pasta.
# Auto-detecta nixos repo (flake.nix + configuration.nix) → monta logs + proj_name fixo.
zion_load_config

mount_path="${args[dir]:-}"
if [[ -z "$mount_path" ]]; then
  mount_path="$(zion_resolve_dir)"
else
  mount_path="$(cd "$mount_path" 2>/dev/null && pwd)" || { echo "zion leech: dir not found: ${args[dir]}" >&2; exit 1; }
fi

# Auto-detect: nixos repo tem flake.nix + configuration.nix na raiz
is_nixos=0
[[ -f "$mount_path/flake.nix" && -f "$mount_path/configuration.nix" ]] && is_nixos=1

EXTRA_V=""
[[ "$is_nixos" == "1" ]] && EXTRA_V="-v /var/log/journal:/workspace/logs/host/journal:ro"

# Shell mode
if [[ -n "${args['--shell']:-}" ]]; then
  if [[ "$is_nixos" == "1" ]]; then
    proj_name="zion-projects"
    mount_opts="rw"
  else
    proj_slug="$(zion_proj_slug "$mount_path")"
    proj_name="$(zion_proj_name "$proj_slug")"
    mount_opts="$(zion_mount_opts)"
  fi
  echo "[zion leech --shell] ${mount_path} → ${proj_name}"
  CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
    zion_compose_cmd -p "$proj_name" run --rm -it $EXTRA_V \
    --entrypoint /entrypoint.sh -e CLAUDIO_MOUNT="$mount_path" sandbox /bin/bash
  exit 0
fi

# Engine session
engine=$(zion_resolve_engine 1)

if [[ "$is_nixos" == "1" ]]; then
  proj_name="zion-projects"
  mount_opts="rw"
  echo "[zion leech] engine=$engine nixos → ${proj_name} (mnt + logs)"
else
  proj_slug="$(zion_proj_slug "$mount_path")"
  if [[ "$engine" == "opencode" ]]; then
    proj_name="$(zion_proj_name_open "$proj_slug")"
  else
    proj_name="$(zion_proj_name "$proj_slug")"
  fi
  mount_opts="$(zion_mount_opts)"
  echo "[zion leech] engine=$engine ${proj_slug} → ${proj_name} (${mount_opts})"
fi

resume_id="${args['--resume']:-}"
flag_init_md="${args['--init-md']:-}"
initial_md="$(zion_initial_md "$mount_path")"
engine_args=""
[[ -n "$initial_md" ]] && engine_args+=" --init-md=$initial_md"
if [[ -n "$resume_id" ]]; then
  [[ "$resume_id" == "1" ]] && engine_args+=" --resume" || engine_args+=" --resume=$resume_id"
fi

zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "$engine_args" "$EXTRA_V"
