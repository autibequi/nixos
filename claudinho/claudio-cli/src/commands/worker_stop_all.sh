echo "[claudio worker-stop-all] Parando todos os containers claude..."
docker ps --filter "ancestor=claude-nix-sandbox" --format "{{.ID}} {{.Names}}" | while read -r id name; do
  echo "  stopping $name ($id)"
  docker stop "$id"
done
# Reset
for dir in "$claudio_vault_dir/_agent/tasks/running"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  source=$(grep '^source=' "$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending")
  rm -f "$dir/.lock"
  if [[ "$source" == "recurring" ]]; then
    rm -rf "$dir"
  else
    mkdir -p "$claudio_vault_dir/_agent/tasks/pending"
    mv "$dir" "$claudio_vault_dir/_agent/tasks/pending/$name"
  fi
done
mkdir -p "$claudio_ephemeral/locks"
rm -f "$claudio_ephemeral/.kanban.lock" "$claudio_ephemeral/locks"/*.lock 2>/dev/null || true
echo "[claudio worker-stop-all] done"
