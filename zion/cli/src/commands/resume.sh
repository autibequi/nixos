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
      zion_compose_env "$mount_path" "$mount_opts"
      list_out=$(zion_compose_cmd -p "$proj_name" run --rm -T \
        --entrypoint /entrypoint.sh -e CLAUDIO_MOUNT="$mount_path" sandbox \
        /bin/bash -c ". /workspace/zion/scripts/bootstrap.sh 2>/dev/null; cd /workspace/mnt 2>/dev/null; agent list 2>/dev/null || true" 2>/dev/null) || true
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

if [[ "$engine" == "opencode" ]]; then
  proj_name="$(zion_proj_name_open "$proj_slug")"
fi

echo "[zion resume] engine=$engine → $proj_name"

# resume_id "1" = última sessão (--continue)
if [[ "$resume_id" == "1" ]]; then
  zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "--continue"
else
  zion_session_run "$engine" "$proj_name" "$mount_path" "$mount_opts" "--resume=$resume_id"
fi
