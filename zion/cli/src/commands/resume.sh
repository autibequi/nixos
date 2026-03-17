# Mostra lista de sessões e permite escolher qual retomar. Com --resume=UUID pula a lista.
zion_load_config
engine="$(zion_resolve_engine 0)"
[[ -z "$engine" ]] && engine="cursor"
mount_path="$(zion_resolve_dir)"
proj_slug="$(zion_proj_slug "$mount_path")"
proj_name="$(zion_proj_name "$proj_slug")"
mount_opts="$(zion_mount_opts)"
resume_id="${args['--resume']:-}"

# Se não passou --resume, mostrar lista e pedir escolha (só se TTY)
if [[ -z "$resume_id" ]]; then
  if [[ -t 0 ]]; then
    echo "[zion resume] Listando sessões (engine=$engine)..."
    list_out=""
    if [[ "$engine" == "cursor" ]]; then
      list_out=$(HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" OBSIDIAN_PATH="$zion_obsidian_path" \
        zion_compose_cmd -p "$proj_name" run --rm -T \
        --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" sandbox \
        -c ". /zion/scripts/bootstrap.sh 2>/dev/null; cd /workspace/mnt 2>/dev/null; agent list 2>/dev/null || true" 2>/dev/null) || true
    fi
    if [[ -n "$list_out" ]]; then
      echo "$list_out"
    else
      echo "Lista não disponível para este engine. Use 'zion continue' (ou só 'zion') para última sessão."
    fi
    echo ""
    read -r -p "UUID da sessão (ou Enter para última): " resume_id
  fi
  # Sem TTY ou Enter = última sessão (equivalente a continue)
  [[ -z "$resume_id" ]] && resume_id="1"
fi

# resume_id "1" = última sessão (--continue)
case "$engine" in
  opencode)
    proj_name_open="$(zion_proj_name_open "$proj_slug")"
    echo "[zion resume] engine=opencode → $proj_name_open"
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name_open" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 -e CLAUDIO_RESUME_SESSION="$resume_id" sandbox \
      bash -c 'cd /workspace/mnt && opencode'
    ;;
  claude)
    echo "[zion resume] engine=claude → $proj_name"
    CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 sandbox \
      -c ". /zion/scripts/bootstrap.sh; cd /workspace/mnt && /home/claude/.nix-profile/bin/claude --resume --permission-mode bypassPermissions"
    ;;
  cursor)
    echo "[zion resume] engine=cursor → $proj_name (mount: ${mount_opts})"
    danger="$(zion_danger_flag cursor)"
    if [[ -n "$resume_id" && "$resume_id" != "1" ]]; then
      cursor_resume_env="-e CLAUDIO_RESUME_SESSION=$resume_id"
      cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; agent'"${danger}"' --resume="${CLAUDIO_RESUME_SESSION}"'
    else
      cursor_resume_env=""
      cursor_cmd='. /zion/scripts/bootstrap.sh; cd /workspace/mnt; agent'"${danger}"' --continue'
    fi
    HOME="${HOME:-$(eval echo ~"$(id -un)")}" CLAUDIO_MOUNT="$mount_path" CLAUDIO_MOUNT_OPTS="$mount_opts" OBSIDIAN_PATH="$zion_obsidian_path" \
      zion_compose_cmd -p "$proj_name" run --rm -it \
      --entrypoint /bin/bash -e CLAUDIO_MOUNT="$mount_path" -e BOOTSTRAP_SKIP_CLEAR=1 $cursor_resume_env sandbox \
      -c "$cursor_cmd"
    ;;
  *)
    echo "zion: engine inválido: $engine" >&2
    exit 1
    ;;
esac
